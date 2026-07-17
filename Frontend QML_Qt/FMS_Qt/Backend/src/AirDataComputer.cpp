#include "AirDataComputer.hpp"
#include "FlightDataManager.hpp"
#include "SystemsManager.hpp"
#include <QtMath>
#include <QDebug>
#include <algorithm>
#include <cmath>

// ── ISA Constants ─────────────────────────────────────────────────────────────
static constexpr double kT0      = 288.15;   // K  Sea-level ISA temp
static constexpr double kP0      = 101325.0; // Pa Sea-level ISA pressure
static constexpr double kL       = 0.0065;   // K/m Lapse rate (troposphere)
static constexpr double kG       = 9.80665;  // m/s^2
static constexpr double kR       = 287.058;  // J/(kg·K)
static constexpr double kGamma   = 1.4;      // Ratio specific heats
static constexpr double kFtToM   = 0.3048;

// ── ISA Utilities ─────────────────────────────────────────────────────────────

double AirDataComputer::isaTemperature(double altitudeFt)
{
    if (std::isnan(altitudeFt) || std::isinf(altitudeFt)) {
        return kT0;
    }
    double altFtClamped = std::clamp(altitudeFt, -2000.0, 100000.0);
    double altM = altFtClamped * kFtToM;
    if (altM <= 11000.0) {
        double T = kT0 - kL * altM;
        if (T < 216.65) T = 216.65;
        return T;
    }
    return 216.65; // Stratosphere (isothermal)
}

double AirDataComputer::isaPressure(double altitudeFt)
{
    if (std::isnan(altitudeFt) || std::isinf(altitudeFt)) {
        return kP0;
    }
    double altFtClamped = std::clamp(altitudeFt, -2000.0, 100000.0);
    double altM = altFtClamped * kFtToM;
    if (altM <= 11000.0) {
        double T = isaTemperature(altFtClamped);
        if (T <= 0.0 || kT0 <= 0.0) {
            return kP0;
        }
        double ratio = T / kT0;
        double exponent = kG / (kL * kR);
        double press = kP0 * std::pow(ratio, exponent);
        if (std::isnan(press) || std::isinf(press)) {
            return kP0;
        }
        return press;
    }
    // Stratosphere
    double p11 = kP0 * std::pow(216.65 / kT0, kG / (kL * kR));
    double exponent = -kG / (kR * 216.65) * (altM - 11000.0);
    double press = p11 * std::exp(exponent);
    if (std::isnan(press) || std::isinf(press)) {
        return p11;
    }
    return press;
}

double AirDataComputer::iasToMach(double ias, double altitudeFt)
{
    if (std::isnan(ias) || std::isinf(ias) || ias <= 0.0) {
        return 0.0;
    }
    if (std::isnan(altitudeFt) || std::isinf(altitudeFt)) {
        altitudeFt = 0.0;
    }

    double T  = isaTemperature(altitudeFt);
    if (T <= 0.0) T = 216.65;
    double a  = std::sqrt(kGamma * kR * T);
    if (a <= 0.0) return 0.0;

    double p  = isaPressure(altitudeFt);
    double T0 = isaTemperature(0.0);
    double p0 = kP0;

    if (p0 <= 0.0 || T <= 0.0) return 0.0;
    double sigma = (p / p0) * (T0 / T); // density ratio
    if (sigma <= 1e-6) sigma = 1e-6; // prevent division by zero or negative in sqrt

    double tas = ias / std::sqrt(sigma); // in kt
    double aKt = a / kFtToM * (3600.0 / 6076.115);
    if (aKt <= 0.0) return 0.0;

    double mach = tas / aKt;
    if (std::isnan(mach) || std::isinf(mach)) {
        return 0.0;
    }
    return mach;
}

double AirDataComputer::machToIas(double mach, double altitudeFt)
{
    if (std::isnan(mach) || std::isinf(mach) || mach <= 0.0) {
        return 0.0;
    }
    if (std::isnan(altitudeFt) || std::isinf(altitudeFt)) {
        altitudeFt = 0.0;
    }

    double T  = isaTemperature(altitudeFt);
    if (T <= 0.0) T = 216.65;
    double a  = std::sqrt(kGamma * kR * T);

    double p  = isaPressure(altitudeFt);
    double T0 = isaTemperature(0.0);
    double p0 = kP0;

    if (p0 <= 0.0 || T <= 0.0) return 0.0;
    double sigma = (p / p0) * (T0 / T);
    if (sigma < 0.0) sigma = 0.0;

    double aKt = a / kFtToM * (3600.0 / 6076.115);
    double tas = mach * aKt;
    double ias = tas * std::sqrt(sigma);
    if (std::isnan(ias) || std::isinf(ias)) {
        return 0.0;
    }
    return ias;
}

// ── Constructor ───────────────────────────────────────────────────────────────

AirDataComputer::AirDataComputer(QObject *parent)
    : QObject(parent)
{
    connect(&m_timer, &QTimer::timeout, this, &AirDataComputer::onTick);
    m_timer.start(80); // ~12 Hz — lowers canvas-repaint churn so RAM stays GC-bounded
}

AirDataComputer::~AirDataComputer()
{
    m_timer.stop();
}

// ── Tick ─────────────────────────────────────────────────────────────────────

void AirDataComputer::onTick()
{
    tick(0.08);
}

void AirDataComputer::tick(double dt)
{
    m_simTime += dt;

    // Tick throttle model (speedbrake auto-deploy, A/THR arbitration, reverse interlock)
    m_throttle.tick(dt, m_ground.onGround, m_ap.athrActive);
    m_flapConfig = m_throttle.flapHandleIndex; // flap handle drives aero config

    // Braking-channel bridge: SystemsManager owns hydraulic pressure state,
    // GroundModel stays decoupled from it — translate channel -> a multiplier.
    m_brakingChannel = SystemsManager::instance()->getBrakingChannel();
    double hydBrakingMultiplier = 1.0;
    if (m_brakingChannel == "ALTERNATE")      hydBrakingMultiplier = 0.7; // no antiskid
    else if (m_brakingChannel == "ACCUMULATOR") hydBrakingMultiplier = 0.4; // limited applications
    else if (m_brakingChannel == "NONE")        hydBrakingMultiplier = 0.0; // no hydraulic braking

    // Drain the brake accumulator once per braking application (Appendix A.4:
    // -200 psi/application), not continuously — rising-edge detection.
    bool brakingActiveNow = (m_throttle.autobrakeSelector != 0) || m_throttle.parkingBrake;
    if (brakingActiveNow && !m_wasBraking && m_brakingChannel == "ACCUMULATOR") {
        SystemsManager::instance()->applyBrakes();
    }
    m_wasBraking = brakingActiveNow;

    m_ground.tick(dt, m_altitude, hydBrakingMultiplier, m_rudderPedal);

    // Set commanded engine inputs based on TLA
    m_engines.thrustLeverAngle1 = m_throttle.getNormalizedThrust(m_throttle.tla1);
    m_engines.thrustLeverAngle2 = m_throttle.getNormalizedThrust(m_throttle.tla2);

    // ── Engines (EngineModel) ─────────────────────────────────────────────────
    double oatK = isaTemperature(m_altitude);
    m_engines.tick(dt, m_altitude, m_mach, oatK,
                   m_activeFailures.contains("ENGINE_FIRE_1"),
                   m_activeFailures.contains("ENGINE_FIRE_2"));

    // Copy engine states to FlightDataBus
    auto *bus = DataBus::FlightDataBus::instance();
    {
        QMutexLocker locker(&bus->mutex);
        auto &eng = bus->aircraft().engines;
        eng.n1Left = m_engines.n1Left;
        eng.n1Right = m_engines.n1Right;
        eng.n2Left = m_engines.n2Left;
        eng.n2Right = m_engines.n2Right;
        eng.egtLeft = m_engines.egtLeft;
        eng.egtRight = m_engines.egtRight;
        eng.ffLeft = m_engines.ffLeft;
        eng.ffRight = m_engines.ffRight;
        eng.oilPressureLeft = m_engines.oilPressureLeft;
        eng.oilPressureRight = m_engines.oilPressureRight;
        eng.oilTempLeft = m_engines.oilTempLeft;
        eng.oilTempRight = m_engines.oilTempRight;
        eng.vibN1Left = m_engines.vibN1Left;
        eng.vibN1Right = m_engines.vibN1Right;
        eng.vibN2Left = m_engines.vibN2Left;
        eng.vibN2Right = m_engines.vibN2Right;
        eng.thrustN1 = m_engines.thrustN1;
        eng.thrustN2 = m_engines.thrustN2;
        eng.started1 = m_engines.started1;
        eng.started2 = m_engines.started2;
        eng.bleedFlow1 = m_engines.bleedFlow1;
        eng.bleedFlow2 = m_engines.bleedFlow2;
    }

    SystemsManager::instance()->tick(dt);
    updatePhysics(dt);
    updateSpeedProtection();

    // ── Autopilot / modes / phase (AutopilotController) ───────────────────────
    const bool phaseChangedNow =
        m_ap.update(dt, { m_altitude, m_groundSpeed, m_vsi });
    if (phaseChangedNow) emit phaseChanged();
    emit autopilotChanged();

    // ── Fuel burn ─────────────────────────────────────────────────────────────
    // Fuel burn is now handled inside SystemsManager::updateFuel()
    emit dataChanged();
}

// ── Physics ───────────────────────────────────────────────────────────────────

void AirDataComputer::updatePhysics(double dt)
{
    FlightDataManager *fdm = FlightDataManager::instance();

    // Gentle turbulence oscillation
    double turbulence = fdm ? fdm->turbulence() : 0.0;
    double turbScale = turbulence / 10.0 * 0.6;
    double turbPitch = std::sin(m_simTime * 0.7) * turbScale;
    double turbRoll  = std::sin(m_simTime * 1.1) * turbScale * 1.5;

    // Failure effects
    bool pitotBlocked = m_activeFailures.contains("PITOT_BLOCKAGE");

    // Attitude behaviour (FlightControlLaws): drift when AP off, capture when on
    FlightControlLaws::updateAttitude(dt, turbPitch, turbRoll,
                                      m_ap.apEngaged(), m_pitch, m_roll);

    // Managed LNAV steering:
    if (m_ap.headingMode == "MANAGED" && fdm) {
        QVariantList waypoints = fdm->waypoints();
        if (m_activeWaypointIndex < waypoints.size()) {
            QVariantMap wp = waypoints.at(m_activeWaypointIndex).toMap();
            double latTarget = wp["lat"].toDouble();
            double lonTarget = wp["lon"].toDouble();

            // Calculate distance to waypoint
            double dist = FlightDataManager::calculateHaversineDistance(m_latitude, m_longitude, latTarget, lonTarget);
            if (dist < 1.0) {
                // Waypoint sequenced!
                m_activeWaypointIndex++;
                if (m_activeWaypointIndex >= waypoints.size()) {
                    // Flight plan completed, hold at destination
                    m_activeWaypointIndex = waypoints.size() - 1;
                }
                emit activeWaypointIndexChanged();
            }

            // Calculate bearing to waypoint
            double piVal = 3.141592653589793;
            double lat1Rad = m_latitude * piVal / 180.0;
            double lat2Rad = latTarget * piVal / 180.0;
            double dLonRad = (lonTarget - m_longitude) * piVal / 180.0;

            double y = std::sin(dLonRad) * std::cos(lat2Rad);
            double x = std::cos(lat1Rad) * std::sin(lat2Rad) - std::sin(lat1Rad) * std::cos(lat2Rad) * std::cos(dLonRad);
            double bearing = std::atan2(y, x) * 180.0 / piVal;
            if (bearing < 0) bearing += 360.0;

            m_ap.selectedHeading = bearing;
        }
    }

    // Heading drift/autopilot steering
    if (m_ground.onGround && !m_ap.apEngaged()) {
        // Manual ground taxi: nosewheel steering from rudder pedal input
        // (GroundModel::headingRateDegPerSec), not the AP heading-hold logic.
        m_heading += m_ground.headingRateDegPerSec * dt;
    } else {
        double hdgTarget = m_heading;
        if (m_ap.headingMode == "MANAGED") {
            hdgTarget = m_ap.selectedHeading;
        } else if (m_ap.lateralMode == "HDG" || m_ap.headingMode == "SELECTED") {
            hdgTarget = m_ap.selectedHeading;
        }
        double diff = hdgTarget - m_heading;
        while (diff >  180.0) diff -= 360.0;
        while (diff < -180.0) diff += 360.0;
        m_heading += diff * dt * 0.5;
    }
    if (m_heading < 0)   m_heading += 360.0;
    if (m_heading > 360) m_heading -= 360.0;

    // IAS drift / autopilot speed
    if (!pitotBlocked) {
        double iasTarget = (m_ap.athrActive) ? m_ap.selectedSpeed : m_ias;
        m_prevIas = m_ias;
        if (m_ground.onGround) {
            if (m_throttle.parkingBrake) {
                m_ias += (0.0 - m_ias) * dt * 0.5;
            } else if (m_ground.effectiveAutobrakeDecel > 0.0) {
                // Decel rate scales with the mu- and hydraulic-channel-scaled
                // target (LO/MED/MAX differ; a degraded/failed braking channel
                // or a wet/icy runway measurably lengthens the stop).
                double decayRate = qBound(0.05, m_ground.effectiveAutobrakeDecel / 6.0 * 0.4, 0.4);
                m_ias += (0.0 - m_ias) * dt * decayRate;
            } else if (m_ground.autobrakeDecel > 0.0) {
                // Autobrake selected but the hydraulic braking channel is NONE
                // (all systems failed) — selecting a mode does not stop the
                // aircraft; fall through to the taxi/thrust model below.
                double tlaAvg = (m_throttle.getNormalizedThrust(m_throttle.tla1) + m_throttle.getNormalizedThrust(m_throttle.tla2)) / 2.0;
                double targetSpeed = tlaAvg * 180.0 + 10.0;
                m_ias += (targetSpeed - m_ias) * dt * 0.1;
            } else {
                // taxi speed model on ground
                if (m_ap.athrActive) {
                    m_ias += (iasTarget - m_ias) * dt * 0.3;
                } else {
                    double tlaAvg = (m_throttle.getNormalizedThrust(m_throttle.tla1) + m_throttle.getNormalizedThrust(m_throttle.tla2)) / 2.0;
                    double targetSpeed = tlaAvg * 180.0 + 10.0;
                    m_ias += (targetSpeed - m_ias) * dt * 0.1;
                }
            }
            m_ias = qBound(0.0, m_ias, 400.0);
        } else {
            m_ias += (iasTarget - m_ias) * dt * 0.3;
            m_ias = qBound(80.0, m_ias, 400.0);
        }
        m_speedTrend = (m_ias - m_prevIas) / dt; // kt/s raw → scale for arrow
    }

    // Mach and position update
    m_mach = iasToMach(m_ias, m_altitude);
    m_mach = qBound(0.0, m_mach, 0.99);

    // Calculate TAS, Ground Speed, Track and update Latitude/Longitude
    double piVal = 3.141592653589793;
    double tempVal = isaTemperature(m_altitude);
    if (tempVal <= 0.0) tempVal = 216.65;
    double pVal = isaPressure(m_altitude);
    double T0Val = isaTemperature(0.0);
    double p0Val = 101325.0;
    double sigma = (pVal / p0Val) * (T0Val / tempVal);
    if (sigma <= 1e-6) sigma = 1e-6;
    m_tas = m_ias / std::sqrt(sigma);

    double windHeading = fdm ? fdm->windHeading() : 0.0;
    double windSpeed = fdm ? fdm->windSpeed() : 0.0;
    double windHdgRad = windHeading * piVal / 180.0;
    double hdgRad = m_heading * piVal / 180.0;

    double windX = windSpeed * std::sin(windHdgRad);
    double windY = windSpeed * std::cos(windHdgRad);

    double acX = m_tas * std::sin(hdgRad);
    double acY = m_tas * std::cos(hdgRad);

    double gsX = acX - windX;
    double gsY = acY - windY;

    m_groundSpeed = std::sqrt(gsX * gsX + gsY * gsY);
    double trackRad = std::atan2(gsX, gsY);

    m_latitude  += (m_groundSpeed * std::cos(trackRad) / (3600.0 * 60.0)) * dt;
    double cosLat = std::cos(m_latitude * piVal / 180.0);
    if (std::abs(cosLat) < 1e-3) cosLat = (cosLat >= 0) ? 1e-3 : -1e-3;
    m_longitude += (m_groundSpeed * std::sin(trackRad) / (3600.0 * 60.0 * cosLat)) * dt;

    // Altitude / VSI
    if (m_ap.verticalMode == "ALT" || m_ap.verticalMode == "ALT_CAPTURE") {
        double altDiff = m_ap.selectedAltitude - m_altitude;
        m_vsi = qBound(-6000.0, altDiff * 0.5, 6000.0);
    } else if (m_ap.verticalMode == "VS") {
        m_vsi = m_ap.selectedVS;
    } else {
        // Idle drift
        m_vsi += (0.0 - m_vsi) * dt * 0.5;
    }

    if (m_ground.onGround) {
        m_altitude = 0.0;
        if (m_vsi < 0.0) m_vsi = 0.0;
    } else {
        m_altitude += m_vsi * dt / 60.0; // fpm to ft/s
        m_altitude = qBound(0.0, m_altitude, 45000.0);
    }
}

void AirDataComputer::updateSpeedProtection()
{
    // Dynamic VLS based on altitude/phase and flap handle (config 0..4).
    // Illustrative factors (documented as data, not FCOM-exact): more flap
    // extension lowers VLS. Real A320 flap 0=clean, 1=slats, 2/3=flap+slat, FULL.
    static constexpr double kFlapFactor[5] = { 1.00, 0.95, 0.85, 0.78, 0.68 };
    double flapFactor = kFlapFactor[qBound(0, m_flapConfig, 4)];
    m_vLs        = 195.0 * flapFactor + (m_altitude / 10000.0) * 8.0;
    m_vAlphaProt = m_vLs - 10.0;
    m_vAlphaMax  = m_vAlphaProt - 15.0;
    m_vStallWarn = m_vAlphaProt - 5.0;
    m_greenDot   = 215.0 + (m_altitude / 10000.0) * 5.0;
    m_slatRetract= 175.0;
    m_flapRetract= 190.0;
    m_vFeNext    = 225.0;

    // VMO/MMO
    double vmoKt = 350.0;
    double mmoKt = machToIas(0.82, m_altitude);
    m_vMax = qMin(vmoKt, mmoKt);

    emit speedProtChanged();
}

// ── Setters ───────────────────────────────────────────────────────────────────

void AirDataComputer::setAp1Active(bool v)  { m_ap.ap1Active  = v; emit autopilotChanged(); }
void AirDataComputer::setAp2Active(bool v)  { m_ap.ap2Active  = v; emit autopilotChanged(); }
void AirDataComputer::setAthrActive(bool v) { m_ap.athrActive = v; emit autopilotChanged(); }
void AirDataComputer::setFdActive(bool v)   { m_ap.fdActive   = v; emit autopilotChanged(); }
void AirDataComputer::setSelectedSpeed(double v)    { m_ap.selectedSpeed    = v; emit fcuChanged(); }
void AirDataComputer::setSelectedHeading(double v)  { m_ap.selectedHeading  = v; emit fcuChanged(); }
void AirDataComputer::setSelectedAltitude(double v) { m_ap.selectedAltitude = v; emit fcuChanged(); }
void AirDataComputer::setSelectedVS(double v)       { m_ap.selectedVS       = v; emit fcuChanged(); }
void AirDataComputer::setSelectedMach(double v)     { m_ap.selectedMach     = v; emit fcuChanged(); }
void AirDataComputer::setV1(double v)   { m_v1   = v; emit vSpeedsChanged(); }
void AirDataComputer::setVr(double v)   { m_vr   = v; emit vSpeedsChanged(); }
void AirDataComputer::setV2(double v)   { m_v2   = v; emit vSpeedsChanged(); }
void AirDataComputer::setVapp(double v) { m_vapp = v; emit vSpeedsChanged(); }

// ── AP Actions ────────────────────────────────────────────────────────────────

void AirDataComputer::engageAP1()    { m_ap.ap1Active = true;  emit autopilotChanged(); }
void AirDataComputer::disengageAP1() { m_ap.ap1Active = false; emit autopilotChanged(); }
void AirDataComputer::engageAP2()    { m_ap.ap2Active = true;  emit autopilotChanged(); }
void AirDataComputer::disengageAP2() { m_ap.ap2Active = false; emit autopilotChanged(); }
void AirDataComputer::toggleFD()     { m_ap.fdActive = !m_ap.fdActive; emit autopilotChanged(); }
void AirDataComputer::toggleATHR()   { m_ap.athrActive = !m_ap.athrActive; emit autopilotChanged(); }

void AirDataComputer::setLateralMode(const QString &mode)
{
    m_ap.lateralMode = mode;
    emit autopilotChanged();
}

void AirDataComputer::setVerticalMode(const QString &mode)
{
    m_ap.verticalMode = mode;
    emit autopilotChanged();
}

void AirDataComputer::setAutoThrustMode(const QString &mode)
{
    m_ap.autoThrustMode = mode;
    emit autopilotChanged();
}

void AirDataComputer::setFlightPhase(const QString &phase)
{
    m_ap.flightPhase = phase;
    emit phaseChanged();
}

void AirDataComputer::applyFailure(const QString &failureId, bool active)
{
    if (active && !m_activeFailures.contains(failureId)) {
        m_activeFailures.append(failureId);
    } else if (!active) {
        m_activeFailures.removeAll(failureId);
    }
}

// ── FCU Push/Pull Logic ──────────────────────────────────────────────────────
void AirDataComputer::pushSpeed() { m_ap.speedMode = "MANAGED"; emit autopilotChanged(); }
void AirDataComputer::pullSpeed() { m_ap.speedMode = "SELECTED"; emit autopilotChanged(); }
void AirDataComputer::pushHeading() { m_ap.headingMode = "MANAGED"; emit autopilotChanged(); }
void AirDataComputer::pullHeading() { m_ap.headingMode = "SELECTED"; emit autopilotChanged(); }
void AirDataComputer::pushAltitude() { m_ap.altitudeMode = "MANAGED"; emit autopilotChanged(); }
void AirDataComputer::pullAltitude() { m_ap.altitudeMode = "SELECTED"; emit autopilotChanged(); }

// ── Manual flight control (yoke) ───────────────────────────────────────────────
void AirDataComputer::setManualAttitude(double pitch, double roll)
{
    // Autopilot holds the attitude — manual input is ignored while AP is engaged.
    if (m_ap.apEngaged()) return;
    FlightControlLaws::applyManual(pitch, roll, m_pitch, m_roll);
    emit dataChanged();
}

void AirDataComputer::setEngine1Thrust(double v)
{
    setTla1(v);
}

void AirDataComputer::setEngine2Thrust(double v)
{
    setTla2(v);
}

void AirDataComputer::setTla1(double v)
{
    if (m_throttle.tla1 != v) {
        m_throttle.tla1 = std::clamp(v, -20.0, 45.0);
        emit dataChanged();
    }
}

void AirDataComputer::setTla2(double v)
{
    if (m_throttle.tla2 != v) {
        m_throttle.tla2 = std::clamp(v, -20.0, 45.0);
        emit dataChanged();
    }
}

void AirDataComputer::setSpeedbrakeLever(double v)
{
    if (m_throttle.speedbrakeLever != v) {
        m_throttle.speedbrakeLever = std::clamp(v, 0.0, 1.0);
        emit dataChanged();
    }
}

void AirDataComputer::setSpeedbrakeArmed(bool v)
{
    if (m_throttle.speedbrakeArmed != v) {
        m_throttle.speedbrakeArmed = v;
        emit dataChanged();
    }
}

void AirDataComputer::setFlapHandleIndex(int v)
{
    if (m_throttle.flapHandleIndex != v) {
        m_throttle.flapHandleIndex = std::clamp(v, 0, 4);
        emit dataChanged();
    }
}

void AirDataComputer::setGearDown(bool v)
{
    if (m_throttle.gearDown != v) {
        m_throttle.gearDown = v;
        emit dataChanged();
    }
}

void AirDataComputer::setAutobrakeSelector(int v)
{
    if (m_throttle.autobrakeSelector != v) {
        m_throttle.autobrakeSelector = std::clamp(v, 0, 3);
        m_ground.autobrakeMode = m_throttle.autobrakeSelector;
        emit dataChanged();
    }
}

void AirDataComputer::setParkingBrake(bool v)
{
    if (m_throttle.parkingBrake != v) {
        m_throttle.parkingBrake = v;
        emit dataChanged();
    }
}

void AirDataComputer::setRunwayCondition(int v)
{
    if (m_ground.runwayCondition != v) {
        m_ground.runwayCondition = std::clamp(v, 0, 2);
        emit dataChanged();
    }
}
