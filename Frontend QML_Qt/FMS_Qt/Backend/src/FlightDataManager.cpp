#include "FlightDataManager.hpp"
#include <QDebug>
#include <QMutexLocker>
#include <cmath>

FlightDataManager *FlightDataManager::s_instance = nullptr;

FlightDataManager *FlightDataManager::instance()
{
    static QRecursiveMutex initMutex;
    QMutexLocker locker(&initMutex);
    if (!s_instance)
        s_instance = new FlightDataManager();
    return s_instance;
}

FlightDataManager::FlightDataManager(QObject *parent)
    : QObject(parent)
{
    initDefaultWaypoints();
}

void FlightDataManager::initDefaultWaypoints()
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    bus->avionics().waypoints.clear();
    auto addWp = [bus](const QString &n, double lat, double lon, double alt, double spd) {
        QVariantMap wp;
        wp["name"]     = n;
        wp["lat"]      = lat;
        wp["lon"]      = lon;
        wp["altitude"] = alt;
        wp["speed"]    = spd;
        bus->avionics().waypoints.append(wp);
    };
    addWp("EDDF", 50.0379,  8.5622,     0,   0);
    addWp("LBU",  50.8667,  8.0833, 15000, 250);
    addWp("KRH",  51.2833,  6.9167, 32000, 280);
    addWp("LFPG", 49.0097,  2.5479,     0,   0);
    recalculateRouteDistances();
    emit waypointsChanged();
}

// ── Getters ──────────────────────────────────────────────────────────────────

QString FlightDataManager::departure() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().departure;
}

QString FlightDataManager::destination() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().destination;
}

QString FlightDataManager::alternate() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().alternate;
}

QString FlightDataManager::flightNumber() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().flightNumber;
}

QString FlightDataManager::callsign() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().callsign;
}

int FlightDataManager::cruiseAltitude() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().cruiseAltitude;
}

double FlightDataManager::tripFuel() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().tripFuel;
}

double FlightDataManager::reserveFuel() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().reserveFuel;
}

double FlightDataManager::alternateFuel() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().alternateFuel;
}

double FlightDataManager::finalReserve() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().finalReserve;
}

double FlightDataManager::zeroFuelWeight() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().zeroFuelWeight;
}

double FlightDataManager::blockFuel() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().blockFuel;
}

int FlightDataManager::passengers() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().passengers;
}

double FlightDataManager::cargo() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().cargo;
}

int FlightDataManager::costIndex() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().costIndex;
}

QVariantList FlightDataManager::waypoints() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().waypoints;
}

double FlightDataManager::windHeading() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->aircraft().atmosphere.windHeading;
}

double FlightDataManager::windSpeed() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->aircraft().atmosphere.windSpeed;
}

double FlightDataManager::turbulence() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->aircraft().atmosphere.turbulence;
}

bool FlightDataManager::hydraulicGreen() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().hyd.greenPumpOn;
}

bool FlightDataManager::hydraulicYellow() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().hyd.yellowPumpOn;
}

bool FlightDataManager::hydraulicBlue() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().hyd.bluePumpOn;
}

bool FlightDataManager::gen1Active() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().elec.idg1Active;
}

bool FlightDataManager::gen2Active() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().elec.idg2Active;
}

bool FlightDataManager::apuActive() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().apuActive;
}

bool FlightDataManager::apuMasterSw() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().apuMasterSw;
}

bool FlightDataManager::apuStartSw() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().apuStartSw;
}

double FlightDataManager::apuN() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().apuN;
}

double FlightDataManager::apuEgt() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().apuEgt;
}

int FlightDataManager::adirs1Mode() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().adirsMode[0];
}

int FlightDataManager::adirs2Mode() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().adirsMode[1];
}

int FlightDataManager::adirs3Mode() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().adirsMode[2];
}

double FlightDataManager::adirs1AlignTime() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().adirsAlignTime[0];
}

double FlightDataManager::adirs2AlignTime() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().adirsAlignTime[1];
}

double FlightDataManager::adirs3AlignTime() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().adirsAlignTime[2];
}

bool FlightDataManager::gnssActive() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().gnssActive;
}

double FlightDataManager::gnssDrift() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().gnssDrift;
}

bool FlightDataManager::adirs1Active() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().adirsActive[0];
}

bool FlightDataManager::adirs2Active() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().adirsActive[1];
}

bool FlightDataManager::adirs3Active() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().adirsActive[2];
}

bool FlightDataManager::pack1Active() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().packs[0];
}

bool FlightDataManager::pack2Active() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().packs[1];
}

bool FlightDataManager::wingAntiIce() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().antiIce[0];
}

bool FlightDataManager::eng1AntiIce() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().antiIce[1];
}

bool FlightDataManager::eng2AntiIce() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().antiIce[2];
}

int FlightDataManager::fuelLOuter() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return static_cast<int>(bus->aircraft().weight.fuel_per_tank[0]);
}

int FlightDataManager::fuelLInner() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return static_cast<int>(bus->aircraft().weight.fuel_per_tank[1]);
}

int FlightDataManager::fuelCentre() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return static_cast<int>(bus->aircraft().weight.fuel_per_tank[2]);
}

int FlightDataManager::fuelRInner() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return static_cast<int>(bus->aircraft().weight.fuel_per_tank[3]);
}

int FlightDataManager::fuelROuter() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return static_cast<int>(bus->aircraft().weight.fuel_per_tank[4]);
}

double FlightDataManager::hydraulicGreenPressure() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().hyd.greenPressure;
}

double FlightDataManager::hydraulicYellowPressure() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().hyd.yellowPressure;
}

double FlightDataManager::hydraulicBluePressure() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().hyd.bluePressure;
}

double FlightDataManager::acBus1() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().elec.acBus1;
}

double FlightDataManager::acBus2() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().elec.acBus2;
}

double FlightDataManager::acEss() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().elec.acEss;
}

double FlightDataManager::dcBus1() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().elec.dcBus1;
}

double FlightDataManager::dcBus2() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().elec.dcBus2;
}

double FlightDataManager::dcEss() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().elec.dcEss;
}

double FlightDataManager::bat1Voltage() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().elec.bat1Voltage;
}

double FlightDataManager::bat2Voltage() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->systems().elec.bat2Voltage;
}

int FlightDataManager::ndRange() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().ndRange;
}

QString FlightDataManager::ndMode() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().ndMode;
}

bool FlightDataManager::wxrOverlay() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().wxrOverlay;
}

bool FlightDataManager::terrOverlay() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().terrOverlay;
}

bool FlightDataManager::tcasOverlay() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().tcasOverlay;
}

bool FlightDataManager::vorOverlay() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().vorOverlay;
}

bool FlightDataManager::wptOverlay() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().wptOverlay;
}

double FlightDataManager::qnh() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().qnh;
}

// ── Setters ──────────────────────────────────────────────────────────────────

void FlightDataManager::setDeparture(const QString &v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().departure != v) {
        bus->avionics().departure = v;
        emit flightDataChanged();
    }
}

void FlightDataManager::setDestination(const QString &v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().destination != v) {
        bus->avionics().destination = v;
        emit flightDataChanged();
    }
}

void FlightDataManager::setAlternate(const QString &v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().alternate != v) {
        bus->avionics().alternate = v;
        emit flightDataChanged();
    }
}

void FlightDataManager::setFlightNumber(const QString &v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().flightNumber != v) {
        bus->avionics().flightNumber = v;
        emit flightDataChanged();
    }
}

void FlightDataManager::setCallsign(const QString &v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().callsign != v) {
        bus->avionics().callsign = v;
        emit flightDataChanged();
    }
}

void FlightDataManager::setCruiseAltitude(int v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().cruiseAltitude != v) {
        bus->avionics().cruiseAltitude = v;
        emit flightDataChanged();
    }
}

void FlightDataManager::setTripFuel(double v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().tripFuel != v) {
        bus->avionics().tripFuel = v;
        emit flightDataChanged();
    }
}

void FlightDataManager::setReserveFuel(double v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().reserveFuel != v) {
        bus->avionics().reserveFuel = v;
        emit flightDataChanged();
    }
}

void FlightDataManager::setAlternateFuel(double v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().alternateFuel != v) {
        bus->avionics().alternateFuel = v;
        emit flightDataChanged();
    }
}

void FlightDataManager::setFinalReserve(double v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().finalReserve != v) {
        bus->avionics().finalReserve = v;
        emit flightDataChanged();
    }
}

void FlightDataManager::setZeroFuelWeight(double v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().zeroFuelWeight != v) {
        bus->avionics().zeroFuelWeight = v;
        emit flightDataChanged();
    }
}

void FlightDataManager::setBlockFuel(double v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().blockFuel != v) {
        bus->avionics().blockFuel = v;
        emit flightDataChanged();
    }
}

void FlightDataManager::setPassengers(int v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().passengers != v) {
        bus->avionics().passengers = v;
        emit flightDataChanged();
    }
}

void FlightDataManager::setCargo(double v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().cargo != v) {
        bus->avionics().cargo = v;
        emit flightDataChanged();
    }
}

void FlightDataManager::setCostIndex(int v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().costIndex != v) {
        bus->avionics().costIndex = v;
        emit flightDataChanged();
    }
}

void FlightDataManager::setWindHeading(double v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->aircraft().atmosphere.windHeading != v) {
        bus->aircraft().atmosphere.windHeading = v;
        emit weatherChanged();
    }
}

void FlightDataManager::setWindSpeed(double v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->aircraft().atmosphere.windSpeed != v) {
        bus->aircraft().atmosphere.windSpeed = v;
        emit weatherChanged();
    }
}

void FlightDataManager::setTurbulence(double v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->aircraft().atmosphere.turbulence != v) {
        bus->aircraft().atmosphere.turbulence = v;
        emit weatherChanged();
    }
}

void FlightDataManager::setHydraulicGreen(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().hyd.greenPumpOn != v) {
        bus->systems().hyd.greenPumpOn = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setHydraulicYellow(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().hyd.yellowPumpOn != v) {
        bus->systems().hyd.yellowPumpOn = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setHydraulicBlue(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().hyd.bluePumpOn != v) {
        bus->systems().hyd.bluePumpOn = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setGen1Active(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().elec.idg1Active != v) {
        bus->systems().elec.idg1Active = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setGen2Active(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().elec.idg2Active != v) {
        bus->systems().elec.idg2Active = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setApuActive(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().apuActive != v) {
        bus->systems().apuActive = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setApuMasterSw(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().apuMasterSw != v) {
        bus->systems().apuMasterSw = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setApuStartSw(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().apuStartSw != v) {
        bus->systems().apuStartSw = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setGnssActive(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().gnssActive != v) {
        bus->systems().gnssActive = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setGnssDrift(double v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().gnssDrift != v) {
        bus->systems().gnssDrift = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setAdirs1Active(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().adirsActive[0] != v) {
        bus->systems().adirsActive[0] = v;
        bus->systems().adirsMode[0] = v ? 1 : 0;
        bus->systems().adirsAlignTime[0] = v ? 600.0 : 0.0;
        emit systemsChanged();
    }
}

void FlightDataManager::setAdirs2Active(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().adirsActive[1] != v) {
        bus->systems().adirsActive[1] = v;
        bus->systems().adirsMode[1] = v ? 1 : 0;
        bus->systems().adirsAlignTime[1] = v ? 600.0 : 0.0;
        emit systemsChanged();
    }
}

void FlightDataManager::setAdirs3Active(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().adirsActive[2] != v) {
        bus->systems().adirsActive[2] = v;
        bus->systems().adirsMode[2] = v ? 1 : 0;
        bus->systems().adirsAlignTime[2] = v ? 600.0 : 0.0;
        emit systemsChanged();
    }
}

void FlightDataManager::setPack1Active(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().packs[0] != v) {
        bus->systems().packs[0] = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setPack2Active(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().packs[1] != v) {
        bus->systems().packs[1] = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setWingAntiIce(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().antiIce[0] != v) {
        bus->systems().antiIce[0] = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setEng1AntiIce(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().antiIce[1] != v) {
        bus->systems().antiIce[1] = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setEng2AntiIce(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->systems().antiIce[2] != v) {
        bus->systems().antiIce[2] = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setFuelLOuter(int v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (static_cast<int>(bus->aircraft().weight.fuel_per_tank[0]) != v) {
        bus->aircraft().weight.fuel_per_tank[0] = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setFuelLInner(int v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (static_cast<int>(bus->aircraft().weight.fuel_per_tank[1]) != v) {
        bus->aircraft().weight.fuel_per_tank[1] = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setFuelCentre(int v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (static_cast<int>(bus->aircraft().weight.fuel_per_tank[2]) != v) {
        bus->aircraft().weight.fuel_per_tank[2] = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setFuelRInner(int v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (static_cast<int>(bus->aircraft().weight.fuel_per_tank[3]) != v) {
        bus->aircraft().weight.fuel_per_tank[3] = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setFuelROuter(int v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (static_cast<int>(bus->aircraft().weight.fuel_per_tank[4]) != v) {
        bus->aircraft().weight.fuel_per_tank[4] = v;
        emit systemsChanged();
    }
}

void FlightDataManager::setNdRange(int v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().ndRange != v) {
        bus->avionics().ndRange = v;
        emit efisChanged();
    }
}

void FlightDataManager::setNdMode(const QString &v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().ndMode != v) {
        bus->avionics().ndMode = v;
        emit efisChanged();
    }
}

void FlightDataManager::setWxrOverlay(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().wxrOverlay != v) {
        bus->avionics().wxrOverlay = v;
        emit efisChanged();
    }
}

void FlightDataManager::setTerrOverlay(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().terrOverlay != v) {
        bus->avionics().terrOverlay = v;
        emit efisChanged();
    }
}

void FlightDataManager::setTcasOverlay(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().tcasOverlay != v) {
        bus->avionics().tcasOverlay = v;
        emit efisChanged();
    }
}

void FlightDataManager::setVorOverlay(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().vorOverlay != v) {
        bus->avionics().vorOverlay = v;
        emit efisChanged();
    }
}

void FlightDataManager::setWptOverlay(bool v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().wptOverlay != v) {
        bus->avionics().wptOverlay = v;
        emit efisChanged();
    }
}

void FlightDataManager::setQnh(double v)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().qnh != v) {
        bus->avionics().qnh = v;
        emit efisChanged();
    }
}

// ── Fuel burn ─────────────────────────────────────────────────────────────

void FlightDataManager::decrementFuel(double kg)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    
    // Decrement from tanks proportionally or simple sequence
    // A320 drains Center first, then Inner, then Outer
    double *tanks = bus->aircraft().weight.fuel_per_tank;
    
    double remaining = kg;
    
    // Center Tank (index 2)
    if (tanks[2] > 0.0) {
        double drain = std::min(remaining, tanks[2]);
        tanks[2] -= drain;
        remaining -= drain;
    }
    
    // Inner Tanks (index 1 and 3)
    if (remaining > 0.0) {
        double innerFuel = tanks[1] + tanks[3];
        if (innerFuel > 0.0) {
            double drain = std::min(remaining, innerFuel);
            double halfDrain = drain / 2.0;
            tanks[1] -= std::min(halfDrain, tanks[1]);
            tanks[3] -= std::min(halfDrain, tanks[3]);
            remaining -= drain;
        }
    }
    
    // Outer Tanks (index 0 and 4)
    if (remaining > 0.0) {
        double outerFuel = tanks[0] + tanks[4];
        if (outerFuel > 0.0) {
            double drain = std::min(remaining, outerFuel);
            double halfDrain = drain / 2.0;
            tanks[0] -= std::min(halfDrain, tanks[0]);
            tanks[4] -= std::min(halfDrain, tanks[4]);
            remaining -= drain;
        }
    }
    
    emit systemsChanged();
}

// ── Waypoint management ───────────────────────────────────────────────────

void FlightDataManager::addWaypoint(const QString &name, double lat, double lon, double altitude, double speed)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().waypoints.size() >= 100) {
        return;
    }
    QVariantMap wp;
    wp["name"]     = name;
    wp["lat"]      = lat;
    wp["lon"]      = lon;
    wp["altitude"] = altitude;
    wp["speed"]    = speed;
    bus->avionics().waypoints.append(wp);
    recalculateRouteDistances();
    emit waypointsChanged();
}

void FlightDataManager::removeWaypoint(int index)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (index >= 0 && index < bus->avionics().waypoints.size()) {
        bus->avionics().waypoints.removeAt(index);
        recalculateRouteDistances();
        emit waypointsChanged();
    }
}

void FlightDataManager::insertWaypoint(int index, const QString &name, double lat, double lon, double altitude, double speed)
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (bus->avionics().waypoints.size() >= 100) {
        return;
    }
    QVariantMap wp;
    wp["name"]     = name;
    wp["lat"]      = lat;
    wp["lon"]      = lon;
    wp["altitude"] = altitude;
    wp["speed"]    = speed;
    bus->avionics().waypoints.insert(std::clamp(index, 0, static_cast<int>(bus->avionics().waypoints.size())), wp);
    recalculateRouteDistances();
    emit waypointsChanged();
}

QVariantMap FlightDataManager::waypointAt(int index) const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    if (index >= 0 && index < bus->avionics().waypoints.size()) {
        return bus->avionics().waypoints.at(index).toMap();
    }
    return QVariantMap();
}

int FlightDataManager::waypointCount() const
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    return bus->avionics().waypoints.size();
}

double FlightDataManager::calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2)
{
    double rLat1 = lat1 * M_PI / 180.0;
    double rLon1 = lon1 * M_PI / 180.0;
    double rLat2 = lat2 * M_PI / 180.0;
    double rLon2 = lon2 * M_PI / 180.0;

    double dLat = rLat2 - rLat1;
    double dLon = rLon2 - rLon1;

    double a = std::sin(dLat / 2.0) * std::sin(dLat / 2.0) +
               std::cos(rLat1) * std::cos(rLat2) *
               std::sin(dLon / 2.0) * std::sin(dLon / 2.0);

    double clampedA = std::clamp(a, 0.0, 1.0);
    double sqrtA = std::sqrt(clampedA);
    double clampedAsinArg = std::clamp(sqrtA, -1.0, 1.0);
    double c = 2.0 * std::asin(clampedAsinArg);

    double dist = 3440.06 * c; // in NM
    if (std::isnan(dist) || std::isinf(dist)) {
        return 0.0;
    }
    return dist;
}

void FlightDataManager::recalculateRouteDistances()
{
    auto *bus = DataBus::FlightDataBus::instance();
    QMutexLocker locker(&bus->mutex);
    QVariantList &wps = bus->avionics().waypoints;
    double cumulative = 0.0;
    for (int i = 0; i < wps.size(); ++i) {
        QVariantMap wp = wps[i].toMap();
        double legDist = 0.0;
        if (i > 0) {
            QVariantMap prevWp = wps[i - 1].toMap();
            legDist = calculateHaversineDistance(
                prevWp["lat"].toDouble(), prevWp["lon"].toDouble(),
                wp["lat"].toDouble(), wp["lon"].toDouble()
            );
        }
        cumulative += legDist;
        wp["distance"] = legDist;
        wp["cumulativeDistance"] = cumulative;
        wps[i] = wp;
    }
}
