#include "FlightDataManager.hpp"
#include <QDebug>
#include <QMutexLocker>

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
    QMutexLocker locker(&m_mutex);
    m_waypoints.clear();
    auto addWp = [this](const QString &n, double lat, double lon, double alt, double spd) {
        QVariantMap wp;
        wp["name"]     = n;
        wp["lat"]      = lat;
        wp["lon"]      = lon;
        wp["altitude"] = alt;
        wp["speed"]    = spd;
        m_waypoints.append(wp);
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
    QMutexLocker locker(&m_mutex);
    return m_departure;
}

QString FlightDataManager::destination() const
{
    QMutexLocker locker(&m_mutex);
    return m_destination;
}

QString FlightDataManager::alternate() const
{
    QMutexLocker locker(&m_mutex);
    return m_alternate;
}

QString FlightDataManager::flightNumber() const
{
    QMutexLocker locker(&m_mutex);
    return m_flightNumber;
}

QString FlightDataManager::callsign() const
{
    QMutexLocker locker(&m_mutex);
    return m_callsign;
}

int FlightDataManager::cruiseAltitude() const
{
    QMutexLocker locker(&m_mutex);
    return m_cruiseAltitude;
}

double FlightDataManager::tripFuel() const
{
    QMutexLocker locker(&m_mutex);
    return m_tripFuel;
}

double FlightDataManager::reserveFuel() const
{
    QMutexLocker locker(&m_mutex);
    return m_reserveFuel;
}

double FlightDataManager::alternateFuel() const
{
    QMutexLocker locker(&m_mutex);
    return m_alternateFuel;
}

double FlightDataManager::finalReserve() const
{
    QMutexLocker locker(&m_mutex);
    return m_finalReserve;
}

 double FlightDataManager::zeroFuelWeight() const
{
    QMutexLocker locker(&m_mutex);
    return m_zeroFuelWeight;
}

double FlightDataManager::blockFuel() const
{
    QMutexLocker locker(&m_mutex);
    return m_blockFuel;
}

int FlightDataManager::passengers() const
{
    QMutexLocker locker(&m_mutex);
    return m_passengers;
}

double FlightDataManager::cargo() const
{
    QMutexLocker locker(&m_mutex);
    return m_cargo;
}

int FlightDataManager::costIndex() const
{
    QMutexLocker locker(&m_mutex);
    return m_costIndex;
}

QVariantList FlightDataManager::waypoints() const
{
    QMutexLocker locker(&m_mutex);
    return m_waypoints;
}

double FlightDataManager::windHeading() const
{
    QMutexLocker locker(&m_mutex);
    return m_windHeading;
}

double FlightDataManager::windSpeed() const
{
    QMutexLocker locker(&m_mutex);
    return m_windSpeed;
}

double FlightDataManager::turbulence() const
{
    QMutexLocker locker(&m_mutex);
    return m_turbulence;
}

bool FlightDataManager::hydraulicGreen() const
{
    QMutexLocker locker(&m_mutex);
    return m_hydraulicGreen;
}

bool FlightDataManager::hydraulicYellow() const
{
    QMutexLocker locker(&m_mutex);
    return m_hydraulicYellow;
}

bool FlightDataManager::hydraulicBlue() const
{
    QMutexLocker locker(&m_mutex);
    return m_hydraulicBlue;
}

bool FlightDataManager::gen1Active() const
{
    QMutexLocker locker(&m_mutex);
    return m_gen1Active;
}

bool FlightDataManager::gen2Active() const
{
    QMutexLocker locker(&m_mutex);
    return m_gen2Active;
}

bool FlightDataManager::apuActive() const
{
    QMutexLocker locker(&m_mutex);
    return m_apuActive;
}

bool FlightDataManager::gnssActive() const
{
    QMutexLocker locker(&m_mutex);
    return m_gnssActive;
}

double FlightDataManager::gnssDrift() const
{
    QMutexLocker locker(&m_mutex);
    return m_gnssDrift;
}

bool FlightDataManager::apuMasterSw()  const { QMutexLocker locker(&m_mutex); return m_apuMasterSw; }
bool FlightDataManager::adirs1Active() const { QMutexLocker locker(&m_mutex); return m_adirs1Active; }
bool FlightDataManager::adirs2Active() const { QMutexLocker locker(&m_mutex); return m_adirs2Active; }
bool FlightDataManager::adirs3Active() const { QMutexLocker locker(&m_mutex); return m_adirs3Active; }
bool FlightDataManager::pack1Active()  const { QMutexLocker locker(&m_mutex); return m_pack1Active; }
bool FlightDataManager::pack2Active()  const { QMutexLocker locker(&m_mutex); return m_pack2Active; }
bool FlightDataManager::wingAntiIce()  const { QMutexLocker locker(&m_mutex); return m_wingAntiIce; }
bool FlightDataManager::eng1AntiIce()  const { QMutexLocker locker(&m_mutex); return m_eng1AntiIce; }
bool FlightDataManager::eng2AntiIce()  const { QMutexLocker locker(&m_mutex); return m_eng2AntiIce; }
int  FlightDataManager::fuelLOuter()   const { QMutexLocker locker(&m_mutex); return m_fuelLOuter; }
int  FlightDataManager::fuelLInner()   const { QMutexLocker locker(&m_mutex); return m_fuelLInner; }
int  FlightDataManager::fuelCentre()   const { QMutexLocker locker(&m_mutex); return m_fuelCentre; }
int  FlightDataManager::fuelRInner()   const { QMutexLocker locker(&m_mutex); return m_fuelRInner; }
int  FlightDataManager::fuelROuter()   const { QMutexLocker locker(&m_mutex); return m_fuelROuter; }

int FlightDataManager::ndRange() const
{
    QMutexLocker locker(&m_mutex);
    return m_ndRange;
}

QString FlightDataManager::ndMode() const
{
    QMutexLocker locker(&m_mutex);
    return m_ndMode;
}

bool FlightDataManager::wxrOverlay() const
{
    QMutexLocker locker(&m_mutex);
    return m_wxrOverlay;
}

bool FlightDataManager::terrOverlay() const
{
    QMutexLocker locker(&m_mutex);
    return m_terrOverlay;
}

bool FlightDataManager::tcasOverlay() const
{
    QMutexLocker locker(&m_mutex);
    return m_tcasOverlay;
}

bool FlightDataManager::vorOverlay() const
{
    QMutexLocker locker(&m_mutex);
    return m_vorOverlay;
}

bool FlightDataManager::wptOverlay() const
{
    QMutexLocker locker(&m_mutex);
    return m_wptOverlay;
}

double FlightDataManager::qnh() const
{
    QMutexLocker locker(&m_mutex);
    return m_qnh;
}

// ── Flight Plan Setters ───────────────────────────────────────────────────────

void FlightDataManager::setDeparture(const QString &v)    { QMutexLocker locker(&m_mutex); m_departure    = v; emit flightDataChanged(); }
void FlightDataManager::setDestination(const QString &v)  { QMutexLocker locker(&m_mutex); m_destination  = v; emit flightDataChanged(); }
void FlightDataManager::setAlternate(const QString &v)    { QMutexLocker locker(&m_mutex); m_alternate    = v; emit flightDataChanged(); }
void FlightDataManager::setFlightNumber(const QString &v) { QMutexLocker locker(&m_mutex); m_flightNumber = v; emit flightDataChanged(); }
void FlightDataManager::setCallsign(const QString &v)     { QMutexLocker locker(&m_mutex); m_callsign     = v; emit flightDataChanged(); }
void FlightDataManager::setCruiseAltitude(int v)          { QMutexLocker locker(&m_mutex); m_cruiseAltitude = v; emit flightDataChanged(); }
void FlightDataManager::setTripFuel(double v)             { QMutexLocker locker(&m_mutex); m_tripFuel     = v; emit flightDataChanged(); }
void FlightDataManager::setReserveFuel(double v)          { QMutexLocker locker(&m_mutex); m_reserveFuel  = v; emit flightDataChanged(); }
void FlightDataManager::setAlternateFuel(double v)        { QMutexLocker locker(&m_mutex); m_alternateFuel = v; emit flightDataChanged(); }
void FlightDataManager::setFinalReserve(double v)         { QMutexLocker locker(&m_mutex); m_finalReserve = v; emit flightDataChanged(); }
void FlightDataManager::setZeroFuelWeight(double v)       { QMutexLocker locker(&m_mutex); m_zeroFuelWeight = v; emit flightDataChanged(); }
void FlightDataManager::setBlockFuel(double v)           { QMutexLocker locker(&m_mutex); m_blockFuel     = v; emit flightDataChanged(); }
void FlightDataManager::setPassengers(int v)              { QMutexLocker locker(&m_mutex); m_passengers   = v; emit flightDataChanged(); }
void FlightDataManager::setCargo(double v)                { QMutexLocker locker(&m_mutex); m_cargo        = v; emit flightDataChanged(); }
void FlightDataManager::setCostIndex(int v)               { QMutexLocker locker(&m_mutex); m_costIndex    = v; emit flightDataChanged(); }

// ── Weather ──────────────────────────────────────────────────────────────────
void FlightDataManager::setWindHeading(double v)  { QMutexLocker locker(&m_mutex); m_windHeading  = v; emit weatherChanged(); }
void FlightDataManager::setWindSpeed(double v)    { QMutexLocker locker(&m_mutex); m_windSpeed    = v; emit weatherChanged(); }
void FlightDataManager::setTurbulence(double v)   { QMutexLocker locker(&m_mutex); m_turbulence   = v; emit weatherChanged(); }

// ── Systems ──────────────────────────────────────────────────────────────────
void FlightDataManager::setHydraulicGreen(bool v)  { QMutexLocker locker(&m_mutex); m_hydraulicGreen  = v; emit systemsChanged(); }
void FlightDataManager::setHydraulicYellow(bool v) { QMutexLocker locker(&m_mutex); m_hydraulicYellow = v; emit systemsChanged(); }
void FlightDataManager::setHydraulicBlue(bool v)   { QMutexLocker locker(&m_mutex); m_hydraulicBlue   = v; emit systemsChanged(); }
void FlightDataManager::setGen1Active(bool v)       { QMutexLocker locker(&m_mutex); m_gen1Active      = v; emit systemsChanged(); }
void FlightDataManager::setGen2Active(bool v)       { QMutexLocker locker(&m_mutex); m_gen2Active      = v; emit systemsChanged(); }
void FlightDataManager::setApuActive(bool v)        { QMutexLocker locker(&m_mutex); m_apuActive       = v; emit systemsChanged(); }
void FlightDataManager::setApuMasterSw(bool v)      { QMutexLocker locker(&m_mutex); m_apuMasterSw     = v; emit systemsChanged(); }
void FlightDataManager::setGnssActive(bool v)       { QMutexLocker locker(&m_mutex); m_gnssActive      = v; emit systemsChanged(); }
void FlightDataManager::setGnssDrift(double v)      { QMutexLocker locker(&m_mutex); m_gnssDrift       = v; emit systemsChanged(); }
void FlightDataManager::setAdirs1Active(bool v)     { QMutexLocker locker(&m_mutex); m_adirs1Active    = v; emit systemsChanged(); }
void FlightDataManager::setAdirs2Active(bool v)     { QMutexLocker locker(&m_mutex); m_adirs2Active    = v; emit systemsChanged(); }
void FlightDataManager::setAdirs3Active(bool v)     { QMutexLocker locker(&m_mutex); m_adirs3Active    = v; emit systemsChanged(); }
void FlightDataManager::setPack1Active(bool v)      { QMutexLocker locker(&m_mutex); m_pack1Active     = v; emit systemsChanged(); }
void FlightDataManager::setPack2Active(bool v)      { QMutexLocker locker(&m_mutex); m_pack2Active     = v; emit systemsChanged(); }
void FlightDataManager::setWingAntiIce(bool v)      { QMutexLocker locker(&m_mutex); m_wingAntiIce     = v; emit systemsChanged(); }
void FlightDataManager::setEng1AntiIce(bool v)      { QMutexLocker locker(&m_mutex); m_eng1AntiIce     = v; emit systemsChanged(); }
void FlightDataManager::setEng2AntiIce(bool v)      { QMutexLocker locker(&m_mutex); m_eng2AntiIce     = v; emit systemsChanged(); }
void FlightDataManager::setFuelLOuter(int v)        { QMutexLocker locker(&m_mutex); m_fuelLOuter      = v; emit systemsChanged(); }
void FlightDataManager::setFuelLInner(int v)        { QMutexLocker locker(&m_mutex); m_fuelLInner      = v; emit systemsChanged(); }
void FlightDataManager::setFuelCentre(int v)        { QMutexLocker locker(&m_mutex); m_fuelCentre      = v; emit systemsChanged(); }
void FlightDataManager::setFuelRInner(int v)        { QMutexLocker locker(&m_mutex); m_fuelRInner      = v; emit systemsChanged(); }
void FlightDataManager::setFuelROuter(int v)        { QMutexLocker locker(&m_mutex); m_fuelROuter      = v; emit systemsChanged(); }

void FlightDataManager::decrementFuel(double kg)
{
    // Drain order: Centre → L/R Inner equally → L/R Outer equally
    // Called from AirDataComputer::onTick() with kg burned per tick.
    QMutexLocker locker(&m_mutex);
    bool changed = false;

    auto burn = [&](int &tank, double amount) {
        int take = static_cast<int>(std::min(static_cast<double>(tank), amount));
        if (take > 0) { tank -= take; kg -= take; changed = true; }
    };

    if (kg > 0) burn(m_fuelCentre, kg);
    if (kg > 0) { double half = kg / 2.0; burn(m_fuelLInner, half); burn(m_fuelRInner, kg); }
    if (kg > 0) { double half = kg / 2.0; burn(m_fuelLOuter, half); burn(m_fuelROuter, kg); }

    if (changed) emit systemsChanged();
}

// ── EFIS ─────────────────────────────────────────────────────────────────────
void FlightDataManager::setNdRange(int v)         { QMutexLocker locker(&m_mutex); m_ndRange    = v; emit efisChanged(); }
void FlightDataManager::setNdMode(const QString &v){ QMutexLocker locker(&m_mutex); m_ndMode     = v; emit efisChanged(); }
void FlightDataManager::setWxrOverlay(bool v)     { QMutexLocker locker(&m_mutex); m_wxrOverlay  = v; emit efisChanged(); }
void FlightDataManager::setTerrOverlay(bool v)    { QMutexLocker locker(&m_mutex); m_terrOverlay = v; emit efisChanged(); }
void FlightDataManager::setTcasOverlay(bool v)    { QMutexLocker locker(&m_mutex); m_tcasOverlay = v; emit efisChanged(); }
void FlightDataManager::setVorOverlay(bool v)     { QMutexLocker locker(&m_mutex); m_vorOverlay  = v; emit efisChanged(); }
void FlightDataManager::setWptOverlay(bool v)     { QMutexLocker locker(&m_mutex); m_wptOverlay  = v; emit efisChanged(); }
void FlightDataManager::setQnh(double v)          { QMutexLocker locker(&m_mutex); m_qnh        = v; emit efisChanged(); }

// ── Waypoints ─────────────────────────────────────────────────────────────────

void FlightDataManager::addWaypoint(const QString &name, double lat, double lon,
                                     double altitude, double speed)
{
    QMutexLocker locker(&m_mutex);
    if (m_waypoints.size() >= 100) {
        return;
    }
    QVariantMap wp;
    wp["name"]     = name;
    wp["lat"]      = lat;
    wp["lon"]      = lon;
    wp["altitude"] = altitude;
    wp["speed"]    = speed;
    m_waypoints.append(wp);
    recalculateRouteDistances();
    emit waypointsChanged();
}

void FlightDataManager::removeWaypoint(int index)
{
    QMutexLocker locker(&m_mutex);
    if (index >= 0 && index < m_waypoints.size()) {
        m_waypoints.removeAt(index);
        recalculateRouteDistances();
        emit waypointsChanged();
    }
}

void FlightDataManager::insertWaypoint(int index, const QString &name, double lat, double lon,
                                        double altitude, double speed)
{
    QMutexLocker locker(&m_mutex);
    if (m_waypoints.size() >= 100) {
        return;
    }
    QVariantMap wp;
    wp["name"]     = name;
    wp["lat"]      = lat;
    wp["lon"]      = lon;
    wp["altitude"] = altitude;
    wp["speed"]    = speed;
    m_waypoints.insert(qBound(0, index, (int)m_waypoints.size()), wp);
    recalculateRouteDistances();
    emit waypointsChanged();
}

QVariantMap FlightDataManager::waypointAt(int index) const
{
    QMutexLocker locker(&m_mutex);
    if (index >= 0 && index < m_waypoints.size())
        return m_waypoints[index].toMap();
    return {};
}

int FlightDataManager::waypointCount() const
{
    QMutexLocker locker(&m_mutex);
    return m_waypoints.size();
}

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

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

    // Guard input to sqrt
    double clampedA = std::clamp(a, 0.0, 1.0);
    double sqrtA = std::sqrt(clampedA);

    // Guard input to asin
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
    QMutexLocker locker(&m_mutex);
    double cumulative = 0.0;
    for (int i = 0; i < m_waypoints.size(); ++i) {
        QVariantMap wp = m_waypoints[i].toMap();
        double legDist = 0.0;
        if (i > 0) {
            QVariantMap prevWp = m_waypoints[i - 1].toMap();
            legDist = calculateHaversineDistance(
                prevWp["lat"].toDouble(), prevWp["lon"].toDouble(),
                wp["lat"].toDouble(), wp["lon"].toDouble()
            );
        }
        cumulative += legDist;
        wp["distance"] = legDist;
        wp["cumulativeDistance"] = cumulative;
        m_waypoints[i] = wp;
    }
}
