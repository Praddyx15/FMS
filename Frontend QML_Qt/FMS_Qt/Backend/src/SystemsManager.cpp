#include "SystemsManager.hpp"
#include <QMutexLocker>
#include <algorithm>
#include <cmath>

SystemsManager *SystemsManager::s_instance = nullptr;

SystemsManager *SystemsManager::instance()
{
    static QRecursiveMutex initMutex;
    QMutexLocker locker(&initMutex);
    if (!s_instance)
        s_instance = new SystemsManager();
    return s_instance;
}

SystemsManager::SystemsManager(QObject *parent)
    : QObject(parent)
{
}

void SystemsManager::tick(double dt)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);

    updateAPU(dt, bus);
    updateHydraulics(dt, bus);
    updateElectrical(dt, bus);
    updateFuel(dt, bus);
    updateADIRS(dt, bus);
}

void SystemsManager::applyBrakes()
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);

    QString channel = getBrakingChannel();
    if (channel == "ACCUMULATOR") {
        m_accumPressure = std::max(0.0, m_accumPressure - 200.0);
        bus->systems().hyd.accumulatorPressure = m_accumPressure;
    }
}

QString SystemsManager::getBrakingChannel() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);

    if (bus->systems().hyd.greenPressure >= 2500.0) {
        return "NORMAL";
    } else if (bus->systems().hyd.yellowPressure >= 2500.0) {
        return "ALTERNATE";
    } else if (m_accumPressure > 500.0) {
        return "ACCUMULATOR";
    }
    return "NONE";
}

void SystemsManager::updateAPU(double dt, DataBus::FlightDataBus *bus)
{
    auto &sys = bus->systems();
    if (sys.apuMasterSw) {
        if (sys.apuStartSw) {
            // Spool up APU
            sys.apuN = std::min(100.0, sys.apuN + dt * 10.0); // ~10 seconds to reach 100%
            if (sys.apuN >= 95.0) {
                sys.apuActive = true;
            }
            // EGT peak during startup, then settle
            if (sys.apuN < 95.0) {
                // Peak at 650°C
                sys.apuEgt = 15.0 + (sys.apuN / 95.0) * 635.0;
            } else {
                // Settle to 400°C
                sys.apuEgt = 400.0;
            }
        } else {
            // Master switch is on, but start is not pressed
            sys.apuN = std::max(0.0, sys.apuN - dt * 15.0);
            sys.apuEgt = std::max(15.0, sys.apuEgt - dt * 25.0);
            sys.apuActive = false;
        }
    } else {
        // Master switch off: shutdown/cooldown
        sys.apuStartSw = false;
        sys.apuN = std::max(0.0, sys.apuN - dt * 15.0);
        sys.apuEgt = std::max(15.0, sys.apuEgt - dt * 25.0);
        sys.apuActive = false;
    }
}

void SystemsManager::updateADIRS(double dt, DataBus::FlightDataBus *bus)
{
    auto &sys = bus->systems();
    for (int i = 0; i < 3; ++i) {
        if (sys.adirsActive[i]) {
            if (sys.adirsMode[i] == 1) { // ALIGN
                sys.adirsAlignTime[i] = std::max(0.0, sys.adirsAlignTime[i] - dt);
                if (sys.adirsAlignTime[i] <= 0.0) {
                    sys.adirsMode[i] = 2; // NAV (aligned)
                }
            } else if (sys.adirsMode[i] == 0) {
                // Set to ALIGN if it was OFF
                sys.adirsMode[i] = 1;
                sys.adirsAlignTime[i] = 600.0;
            }

            // degraded mode (ATT) if GNSS/GPS is inactive and it was aligned/nav
            if (!sys.gnssActive && sys.adirsMode[i] == 2) {
                sys.adirsMode[i] = 3; // ATT
            } else if (sys.gnssActive && sys.adirsMode[i] == 3) {
                sys.adirsMode[i] = 2; // Restore NAV
            }
        } else {
            sys.adirsMode[i] = 0; // OFF
            sys.adirsAlignTime[i] = 0.0;
        }
    }
}

void SystemsManager::updateHydraulics(double dt, DataBus::FlightDataBus *bus)
{
    auto &sys = bus->systems();
    auto &ac = bus->aircraft();

    double eng1N1 = ac.engines.n1Left;
    double eng2N1 = ac.engines.n1Right;

    // Check failures
    bool greenLeak = bus->training().activeFailures.contains("HYD_GREEN_LEAK");
    bool blueLeak = bus->training().activeFailures.contains("HYD_BLUE_LEAK");
    bool yellowLeak = bus->training().activeFailures.contains("HYD_YELLOW_LEAK");

    // Green Pump (Engine 1 driven)
    double greenTarget = 0.0;
    if (sys.hyd.greenPumpOn && eng1N1 > 20.0 && !greenLeak) {
        greenTarget = 3000.0;
    }
    sys.hyd.greenPressure += (greenTarget - sys.hyd.greenPressure) * dt * 2.0;
    sys.hyd.greenPressure = std::clamp(sys.hyd.greenPressure, 0.0, 3200.0);

    // Yellow Pump (Engine 2 driven + electric pump)
    double yellowTarget = 0.0;
    if ((sys.hyd.yellowPumpOn && eng2N1 > 20.0) || (!yellowLeak && sys.hyd.yellowPumpOn)) {
        yellowTarget = 3000.0;
    }
    sys.hyd.yellowPressure += (yellowTarget - sys.hyd.yellowPressure) * dt * 2.0;
    sys.hyd.yellowPressure = std::clamp(sys.hyd.yellowPressure, 0.0, 3200.0);

    // Blue Pump (electric + RAT fallback)
    double blueTarget = 0.0;
    if (sys.hyd.bluePumpOn && !blueLeak) {
        blueTarget = 3000.0;
    } else if (sys.hyd.ratDeployed && !blueLeak) {
        blueTarget = 2500.0;
    }
    sys.hyd.bluePressure += (blueTarget - sys.hyd.bluePressure) * dt * 2.0;
    sys.hyd.bluePressure = std::clamp(sys.hyd.bluePressure, 0.0, 3200.0);

    // PTU logic: transfers pressure between Green and Yellow when delta > 500 psi
    if (sys.hyd.ptuOn || std::abs(sys.hyd.greenPressure - sys.hyd.yellowPressure) > 500.0) {
        if (sys.hyd.greenPressure > 2500.0 && sys.hyd.yellowPressure < 1500.0 && !yellowLeak) {
            sys.hyd.yellowPressure += (2800.0 - sys.hyd.yellowPressure) * dt * 4.0;
        } else if (sys.hyd.yellowPressure > 2500.0 && sys.hyd.greenPressure < 1500.0 && !greenLeak) {
            sys.hyd.greenPressure += (2800.0 - sys.hyd.greenPressure) * dt * 4.0;
        }
    }

    // Accumulator decays slowly if not recharged
    if (sys.hyd.yellowPressure >= 2500.0) {
        m_accumPressure += (3000.0 - m_accumPressure) * dt * 1.0;
    }
    sys.hyd.accumulatorPressure = m_accumPressure;
}

void SystemsManager::updateElectrical(double dt, DataBus::FlightDataBus *bus)
{
    auto &sys = bus->systems();
    auto &ac = bus->aircraft();

    // Sources availability
    bool gen1Available = sys.elec.idg1Active && ac.engines.n2Left > 50.0 && !bus->training().activeFailures.contains("GEN_1_FAULT");
    bool gen2Available = sys.elec.idg2Active && ac.engines.n2Right > 50.0 && !bus->training().activeFailures.contains("GEN_2_FAULT");
    bool apuGenAvailable = sys.apuActive && sys.elec.apuGenActive;
    bool extPwrAvailable = sys.elec.extPwrActive;

    // AC BUS 1 and AC BUS 2 power state
    bool ac1Powered = false;
    bool ac2Powered = false;

    if (gen1Available) {
        ac1Powered = true;
    }
    if (gen2Available) {
        ac2Powered = true;
    }

    // Bus tie contactor cross-feed
    if (sys.elec.busTieClosed) {
        if (!ac1Powered && (gen2Available || apuGenAvailable || extPwrAvailable)) {
            ac1Powered = true;
        }
        if (!ac2Powered && (gen1Available || apuGenAvailable || extPwrAvailable)) {
            ac2Powered = true;
        }
    }

    sys.elec.acBus1 = ac1Powered ? 115.0 : 0.0;
    sys.elec.acBus2 = ac2Powered ? 115.0 : 0.0;

    // AC ESS (Essential) Bus: normally AC 1, switches to AC 2 if AC 1 is lost
    bool acEssPowered = false;
    if (ac1Powered) {
        acEssPowered = true;
    } else if (ac2Powered) {
        acEssPowered = true;
    } else if (sys.elec.emerGenActive) {
        acEssPowered = true;
    }
    sys.elec.acEss = acEssPowered ? 115.0 : 0.0;

    // DC Bus voltages via TRs
    sys.elec.dcBus1 = ac1Powered ? 28.0 : 0.0;
    sys.elec.dcBus2 = ac2Powered ? 28.0 : 0.0;
    sys.elec.dcEss = acEssPowered ? 28.0 : 0.0;

    // Battery voltage / charging
    if (sys.elec.bat1Active) {
        sys.elec.bat1Voltage = 28.0;
    } else {
        sys.elec.bat1Voltage = 0.0;
    }

    if (sys.elec.bat2Active) {
        sys.elec.bat2Voltage = 28.0;
    } else {
        sys.elec.bat2Voltage = 0.0;
    }

    // FMGC 1 power dependency: disengage Autopilot if AC 1 is lost
    if (!ac1Powered && !sys.elec.bat1Active) {
        bus->avionics().ap.ap1Active = false;
    }
}

void SystemsManager::updateFuel(double dt, DataBus::FlightDataBus *bus)
{
    auto &sys = bus->systems();
    auto &ac = bus->aircraft();

    // Fuel flows are in kg/hr
    double burnLeft = (ac.engines.ffLeft * dt) / 3600.0;
    double burnRight = (ac.engines.ffRight * dt) / 3600.0;

    // Fuel tanks: 0 = Outer Left, 1 = Inner Left, 2 = Center, 3 = Inner Right, 4 = Outer Right
    double &outL  = ac.weight.fuel_per_tank[0];
    double &innL  = ac.weight.fuel_per_tank[1];
    double &ctr   = ac.weight.fuel_per_tank[2];
    double &innR  = ac.weight.fuel_per_tank[3];
    double &outR  = ac.weight.fuel_per_tank[4];

    // Outer-to-inner transfer (automatic in A320 when inner tank drops below ~750 kg)
    if (innL < 750.0 && outL > 0.0) {
        double transfer = std::min(outL, 10.0 * dt); // transfer rate
        outL -= transfer;
        innL += transfer;
    }
    if (innR < 750.0 && outR > 0.0) {
        double transfer = std::min(outR, 10.0 * dt);
        outR -= transfer;
        innR += transfer;
    }

    // Determine pump availability (need electrical power for pumps)
    bool ac1Ok = (sys.elec.acBus1 > 50.0);
    bool ac2Ok = (sys.elec.acBus2 > 50.0);
    bool pumpL1 = sys.fuel.pumps[0] && ac1Ok;
    bool pumpL2 = sys.fuel.pumps[1] && ac2Ok;
    bool pumpC1 = sys.fuel.pumps[2] && ac1Ok;
    bool pumpC2 = sys.fuel.pumps[3] && ac2Ok;
    bool pumpR1 = sys.fuel.pumps[4] && ac1Ok;
    bool pumpR2 = sys.fuel.pumps[5] && ac2Ok;

    bool leftFeedOk = (pumpL1 || pumpL2) && (innL > 0.0);
    bool rightFeedOk = (pumpR1 || pumpR2) && (innR > 0.0);
    bool centerFeedOk = (pumpC1 || pumpC2) && (ctr > 0.0);

    // Fuel consumption execution
    if (sys.fuel.crossfeedOpen) {
        // Crossfeed open: draw from center first if pumps are active, then inner tanks
        double totalBurn = burnLeft + burnRight;
        if (centerFeedOk && ctr > 0.0) {
            double draw = std::min(ctr, totalBurn);
            ctr -= draw;
            totalBurn -= draw;
        }
        if (totalBurn > 0.0) {
            double totalInner = innL + innR;
            if (totalInner > 0.0) {
                double drawL = std::min(innL, totalBurn * (innL / totalInner));
                double drawR = std::min(innR, totalBurn * (innR / totalInner));
                innL -= drawL;
                innR -= drawR;
            }
        }
    } else {
        // Engine 1 (Left)
        double neededLeft = burnLeft;
        if (centerFeedOk && pumpC1 && ctr > 0.0) {
            double draw = std::min(ctr, neededLeft);
            ctr -= draw;
            neededLeft -= draw;
        }
        if (neededLeft > 0.0 && leftFeedOk) {
            double draw = std::min(innL, neededLeft);
            innL -= draw;
        }

        // Engine 2 (Right)
        double neededRight = burnRight;
        if (centerFeedOk && pumpC2 && ctr > 0.0) {
            double draw = std::min(ctr, neededRight);
            ctr -= draw;
            neededRight -= draw;
        }
        if (neededRight > 0.0 && rightFeedOk) {
            double draw = std::min(innR, neededRight);
            innR -= draw;
        }
    }

    // Keep fuel positive
    for (int i = 0; i < 5; ++i) {
        if (ac.weight.fuel_per_tank[i] < 0.0) {
            ac.weight.fuel_per_tank[i] = 0.0;
        }
    }

    // Recalculate total aircraft mass and CG shift
    double totalFuel = outL + innL + ctr + innR + outR;
    ac.weight.mass = bus->avionics().zeroFuelWeight + totalFuel;

    // CG shift model
    ac.weight.cg_mac_pct = 25.0 + (ctr / 6200.0) * 2.0 - ((outL + innL + innR + outR) / 12400.0) * 1.5;
}
