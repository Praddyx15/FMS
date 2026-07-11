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
        // APU startup/running simulation
        sys.apuActive = true;
    } else {
        sys.apuActive = false;
    }
}

void SystemsManager::updateHydraulics(double dt, DataBus::FlightDataBus *bus)
{
    auto &sys = bus->systems();
    auto &ac = bus->aircraft();

    // In a future Phase 3 EngineModel, we will read live N1. For now, we mock/read from m_engines.
    // Let's assume engines are running at N1 if active.
    double eng1N1 = 65.0; // Mock cruise N1
    double eng2N1 = 65.0;

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

    // Sources availability
    bool gen1Available = sys.elec.idg1Active && !bus->training().activeFailures.contains("GEN_1_FAULT");
    bool gen2Available = sys.elec.idg2Active && !bus->training().activeFailures.contains("GEN_2_FAULT");
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
    // Slats state/N1 details can affect auto pump logic here
}
