#pragma once

#include <QObject>
#include <QTimer>
#include <QtQml/qqml.h>

#include "AutopilotController.hpp"
#include "EngineModel.hpp"
#include "FlightControlLaws.hpp"
#include "ThrottleQuadrantModel.hpp"
#include "GroundModel.hpp"

/**
 * AirDataComputer — Flight Simulation Core (QML façade).
 *
 * Phase 1 decomposition (IMPLEMENTATION_PLAN §3): this class now owns the
 * sub-modules and forwards their state to QML — it no longer implements
 * autopilot, engine, or control-law logic itself:
 *   - EngineModel          → N1/EGT/thrust dynamics
 *   - AutopilotController  → AP/FD/A-THR modes, FCU targets, phase, ILS, FD bars
 *   - FlightControlLaws    → attitude behaviour + manual input limits
 * Physics (kinematic point-mass + LNAV steering) and speed protection remain
 * here until Phase 2/4 move them into their own modules.
 *
 * All public Q_PROPERTYs remain in aviation units (kt, ft, deg) — the QML
 * contract is unchanged by the decomposition.
 *
 * Tick rate: 80 ms (12.5 Hz) — bounded so canvas-repaint churn stays GC-safe
 * (IMPLEMENTATION_PLAN §1.1).
 */
class AirDataComputer : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    // ── Position / Attitude ──────────────────────────────────────────────────
    Q_PROPERTY(double pitch     READ pitch     NOTIFY dataChanged)
    Q_PROPERTY(double roll      READ roll      NOTIFY dataChanged)
    Q_PROPERTY(double heading   READ heading   NOTIFY dataChanged)
    Q_PROPERTY(double latitude  READ latitude  NOTIFY dataChanged)
    Q_PROPERTY(double longitude READ longitude NOTIFY dataChanged)
    Q_PROPERTY(int activeWaypointIndex READ activeWaypointIndex NOTIFY activeWaypointIndexChanged)

    // ── Speed ────────────────────────────────────────────────────────────────
    Q_PROPERTY(double ias        READ ias        NOTIFY dataChanged)
    Q_PROPERTY(double mach       READ mach       NOTIFY dataChanged)
    Q_PROPERTY(double tas        READ tas        NOTIFY dataChanged)
    Q_PROPERTY(double groundSpeed READ groundSpeed NOTIFY dataChanged)

    // ── Altitude / VSI ───────────────────────────────────────────────────────
    Q_PROPERTY(double altitude  READ altitude  NOTIFY dataChanged)
    Q_PROPERTY(double vsi       READ vsi       NOTIFY dataChanged)

    // ── Aerodynamic state ────────────────────────────────────────────────────
    Q_PROPERTY(double alpha     READ alpha     NOTIFY dataChanged)  // AoA, deg
    Q_PROPERTY(double beta      READ beta      NOTIFY dataChanged)  // sideslip, deg
    Q_PROPERTY(double nz        READ nz        NOTIFY dataChanged)  // load factor, g
    Q_PROPERTY(double gamma     READ gamma     NOTIFY dataChanged)  // flight-path angle, deg
    Q_PROPERTY(double pRate     READ pRate     NOTIFY dataChanged)  // roll rate, deg/s
    Q_PROPERTY(double qRate     READ qRate     NOTIFY dataChanged)  // pitch rate, deg/s
    Q_PROPERTY(double rRate     READ rRate     NOTIFY dataChanged)  // yaw rate, deg/s

    // ── Speed Protection ─────────────────────────────────────────────────────
    Q_PROPERTY(double vLs        READ vLs        NOTIFY speedProtChanged)
    Q_PROPERTY(double vMax       READ vMax       NOTIFY speedProtChanged)
    Q_PROPERTY(double vAlphaProt READ vAlphaProt NOTIFY speedProtChanged)
    Q_PROPERTY(double vAlphaMax  READ vAlphaMax  NOTIFY speedProtChanged)
    Q_PROPERTY(double vStallWarn READ vStallWarn NOTIFY speedProtChanged)
    Q_PROPERTY(double greenDot   READ greenDot   NOTIFY speedProtChanged)
    Q_PROPERTY(double slatRetract READ slatRetract NOTIFY speedProtChanged)
    Q_PROPERTY(double flapRetract READ flapRetract NOTIFY speedProtChanged)
    Q_PROPERTY(double vFeNext    READ vFeNext    NOTIFY speedProtChanged)
    Q_PROPERTY(double speedTrend READ speedTrend NOTIFY dataChanged)

    // ── Engine ───────────────────────────────────────────────────────────────
    Q_PROPERTY(double engine1Thrust READ engine1Thrust WRITE setEngine1Thrust NOTIFY dataChanged)
    Q_PROPERTY(double engine2Thrust READ engine2Thrust WRITE setEngine2Thrust NOTIFY dataChanged)
    Q_PROPERTY(double n1Left     READ n1Left     NOTIFY dataChanged)
    Q_PROPERTY(double n1Right    READ n1Right    NOTIFY dataChanged)
    Q_PROPERTY(double egtLeft    READ egtLeft    NOTIFY dataChanged)
    Q_PROPERTY(double egtRight   READ egtRight   NOTIFY dataChanged)

    // ── Detailed Engine Parameters for Upper ECAM ────────────────────────────
    Q_PROPERTY(double n2Left READ n2Left NOTIFY dataChanged)
    Q_PROPERTY(double n2Right READ n2Right NOTIFY dataChanged)
    Q_PROPERTY(double ffLeft READ ffLeft NOTIFY dataChanged)
    Q_PROPERTY(double ffRight READ ffRight NOTIFY dataChanged)
    Q_PROPERTY(double oilPressureLeft READ oilPressureLeft NOTIFY dataChanged)
    Q_PROPERTY(double oilPressureRight READ oilPressureRight NOTIFY dataChanged)
    Q_PROPERTY(double oilTempLeft READ oilTempLeft NOTIFY dataChanged)
    Q_PROPERTY(double oilTempRight READ oilTempRight NOTIFY dataChanged)
    Q_PROPERTY(double vibN1Left READ vibN1Left NOTIFY dataChanged)
    Q_PROPERTY(double vibN1Right READ vibN1Right NOTIFY dataChanged)
    Q_PROPERTY(double vibN2Left READ vibN2Left NOTIFY dataChanged)
    Q_PROPERTY(double vibN2Right READ vibN2Right NOTIFY dataChanged)

    // ── Throttle & Ground Model Properties ───────────────────────────────────
    Q_PROPERTY(double tla1 READ tla1 WRITE setTla1 NOTIFY dataChanged)
    Q_PROPERTY(double tla2 READ tla2 WRITE setTla2 NOTIFY dataChanged)
    Q_PROPERTY(double speedbrakeLever READ speedbrakeLever WRITE setSpeedbrakeLever NOTIFY dataChanged)
    Q_PROPERTY(bool speedbrakeArmed READ speedbrakeArmed WRITE setSpeedbrakeArmed NOTIFY dataChanged)
    Q_PROPERTY(int flapHandleIndex READ flapHandleIndex WRITE setFlapHandleIndex NOTIFY dataChanged)
    Q_PROPERTY(bool gearDown READ gearDown WRITE setGearDown NOTIFY dataChanged)
    Q_PROPERTY(int autobrakeSelector READ autobrakeSelector WRITE setAutobrakeSelector NOTIFY dataChanged)
    Q_PROPERTY(bool parkingBrake READ parkingBrake WRITE setParkingBrake NOTIFY dataChanged)
    Q_PROPERTY(bool onGround READ onGround NOTIFY dataChanged)
    Q_PROPERTY(int runwayCondition READ runwayCondition WRITE setRunwayCondition NOTIFY dataChanged)
    Q_PROPERTY(bool athrManualOverrideActive READ athrManualOverrideActive NOTIFY dataChanged)
    Q_PROPERTY(bool reverseInterlockTripped READ reverseInterlockTripped NOTIFY dataChanged)
    Q_PROPERTY(QString brakingChannel READ brakingChannel NOTIFY dataChanged)

    // ── Autopilot ────────────────────────────────────────────────────────────
    Q_PROPERTY(bool   ap1Active       READ ap1Active  WRITE setAp1Active  NOTIFY autopilotChanged)
    Q_PROPERTY(bool   ap2Active       READ ap2Active  WRITE setAp2Active  NOTIFY autopilotChanged)
    Q_PROPERTY(bool   athrActive      READ athrActive WRITE setAthrActive NOTIFY autopilotChanged)
    Q_PROPERTY(bool   fdActive        READ fdActive   WRITE setFdActive   NOTIFY autopilotChanged)
    Q_PROPERTY(QString lateralMode        READ lateralMode       NOTIFY autopilotChanged)
    Q_PROPERTY(QString verticalMode       READ verticalMode      NOTIFY autopilotChanged)
    Q_PROPERTY(QString armedLateralMode   READ armedLateralMode  NOTIFY autopilotChanged)
    Q_PROPERTY(QString armedVerticalMode  READ armedVerticalMode NOTIFY autopilotChanged)
    Q_PROPERTY(QString approachMode       READ approachMode      NOTIFY autopilotChanged)
    Q_PROPERTY(QString speedMode          READ speedMode         NOTIFY autopilotChanged)
    Q_PROPERTY(QString headingMode        READ headingMode       NOTIFY autopilotChanged)
    Q_PROPERTY(QString altitudeMode       READ altitudeMode      NOTIFY autopilotChanged)
    Q_PROPERTY(QString autoThrustMode     READ autoThrustMode    NOTIFY autopilotChanged)

    // ── Flight Director targets ───────────────────────────────────────────────
    Q_PROPERTY(double targetPitch READ targetPitch NOTIFY autopilotChanged)
    Q_PROPERTY(double targetRoll  READ targetRoll  NOTIFY autopilotChanged)

    // ── ILS Deviation ────────────────────────────────────────────────────────
    Q_PROPERTY(double ilsLocDeviation READ ilsLocDeviation NOTIFY dataChanged)
    Q_PROPERTY(double ilsGsDeviation  READ ilsGsDeviation  NOTIFY dataChanged)
    Q_PROPERTY(bool   ilsArmed        READ ilsArmed        NOTIFY autopilotChanged)

    // ── FCU Targets ──────────────────────────────────────────────────────────
    Q_PROPERTY(double selectedSpeed    READ selectedSpeed    WRITE setSelectedSpeed    NOTIFY fcuChanged)
    Q_PROPERTY(double selectedHeading  READ selectedHeading  WRITE setSelectedHeading  NOTIFY fcuChanged)
    Q_PROPERTY(double selectedAltitude READ selectedAltitude WRITE setSelectedAltitude NOTIFY fcuChanged)
    Q_PROPERTY(double selectedVS       READ selectedVS       WRITE setSelectedVS       NOTIFY fcuChanged)
    Q_PROPERTY(double selectedMach     READ selectedMach     WRITE setSelectedMach     NOTIFY fcuChanged)

    // ── V-Speeds ─────────────────────────────────────────────────────────────
    Q_PROPERTY(double v1   READ v1   WRITE setV1   NOTIFY vSpeedsChanged)
    Q_PROPERTY(double vr   READ vr   WRITE setVr   NOTIFY vSpeedsChanged)
    Q_PROPERTY(double v2   READ v2   WRITE setV2   NOTIFY vSpeedsChanged)
    Q_PROPERTY(double vapp READ vapp WRITE setVapp NOTIFY vSpeedsChanged)

    // ── Flight Phase ─────────────────────────────────────────────────────────
    Q_PROPERTY(QString flightPhase READ flightPhase NOTIFY phaseChanged)
    Q_PROPERTY(QString flightMode  READ flightMode  NOTIFY phaseChanged)

    // ── Normal Law ───────────────────────────────────────────────────────────
    Q_PROPERTY(bool normalLawActive READ normalLawActive NOTIFY autopilotChanged)

    // ── Pilot inputs (written by Yoke/RudderPedals QML) ──────────────────────
    Q_PROPERTY(double sidestickPitch READ sidestickPitch WRITE setSidestickPitch NOTIFY dataChanged)
    Q_PROPERTY(double sidestickRoll  READ sidestickRoll  WRITE setSidestickRoll  NOTIFY dataChanged)
    Q_PROPERTY(double rudderPedal    READ rudderPedal    WRITE setRudderPedal    NOTIFY dataChanged)

    // ── Configuration ─────────────────────────────────────────────────────────
    Q_PROPERTY(int flapConfig READ flapConfig WRITE setFlapConfig NOTIFY dataChanged)

public:
    explicit AirDataComputer(QObject *parent = nullptr);
    ~AirDataComputer() override;

    // ── Getters ───────────────────────────────────────────────────────────────
    double pitch()        const { return m_pitch; }
    double roll()         const { return m_roll; }
    double heading()      const { return m_heading; }
    double latitude()     const { return m_latitude; }
    double longitude()    const { return m_longitude; }
    int    activeWaypointIndex() const { return m_activeWaypointIndex; }

    double ias()          const { return m_ias; }
    double mach()         const { return m_mach; }
    double tas()          const { return m_tas; }
    double groundSpeed()  const { return m_groundSpeed; }
    double altitude()     const { return m_altitude; }
    double vsi()          const { return m_vsi; }

    double alpha()        const { return m_alpha; }
    double beta()         const { return m_beta; }
    double nz()           const { return m_nz; }
    double gamma()        const { return m_gamma; }
    double pRate()        const { return m_pRate; }
    double qRate()        const { return m_qRate; }
    double rRate()        const { return m_rRate; }

    double vLs()          const { return m_vLs; }
    double vMax()         const { return m_vMax; }
    double vAlphaProt()   const { return m_vAlphaProt; }
    double vAlphaMax()    const { return m_vAlphaMax; }
    double vStallWarn()   const { return m_vStallWarn; }
    double greenDot()     const { return m_greenDot; }
    double slatRetract()  const { return m_slatRetract; }
    double flapRetract()  const { return m_flapRetract; }
    double vFeNext()      const { return m_vFeNext; }
    double speedTrend()   const { return m_speedTrend; }

    // Engine (delegates to EngineModel)
    double engine1Thrust() const { return m_engines.thrust1; }
    double engine2Thrust() const { return m_engines.thrust2; }
    double n1Left()        const { return m_engines.n1Left; }
    double n1Right()       const { return m_engines.n1Right; }
    double egtLeft()       const { return m_engines.egtLeft; }
    double egtRight()      const { return m_engines.egtRight; }
    double n2Left()        const { return m_engines.n2Left; }
    double n2Right()       const { return m_engines.n2Right; }
    double ffLeft()        const { return m_engines.ffLeft; }
    double ffRight()       const { return m_engines.ffRight; }
    double oilPressureLeft() const { return m_engines.oilPressureLeft; }
    double oilPressureRight() const { return m_engines.oilPressureRight; }
    double oilTempLeft()   const { return m_engines.oilTempLeft; }
    double oilTempRight()  const { return m_engines.oilTempRight; }
    double vibN1Left()     const { return m_engines.vibN1Left; }
    double vibN1Right()    const { return m_engines.vibN1Right; }
    double vibN2Left()     const { return m_engines.vibN2Left; }
    double vibN2Right()    const { return m_engines.vibN2Right; }

    // Throttle / Flight deck controls / Ground state
    double tla1()              const { return m_throttle.tla1; }
    double tla2()              const { return m_throttle.tla2; }
    double speedbrakeLever()   const { return m_throttle.speedbrakeLever; }
    bool   speedbrakeArmed()   const { return m_throttle.speedbrakeArmed; }
    int    flapHandleIndex()   const { return m_throttle.flapHandleIndex; }
    bool   gearDown()          const { return m_throttle.gearDown; }
    int    autobrakeSelector() const { return m_throttle.autobrakeSelector; }
    bool   parkingBrake()      const { return m_throttle.parkingBrake; }
    bool   onGround()          const { return m_ground.onGround; }
    int    runwayCondition()   const { return m_ground.runwayCondition; }
    bool   athrManualOverrideActive() const { return m_throttle.athrManualOverrideActive; }
    bool   reverseInterlockTripped()  const { return m_throttle.reverseInterlockTripped; }
    QString brakingChannel()   const { return m_brakingChannel; }

    // Autopilot (delegates to AutopilotController)
    bool    ap1Active()         const { return m_ap.ap1Active; }
    bool    ap2Active()         const { return m_ap.ap2Active; }
    bool    athrActive()        const { return m_ap.athrActive; }
    bool    fdActive()          const { return m_ap.fdActive; }
    QString lateralMode()       const { return m_ap.lateralMode; }
    QString verticalMode()      const { return m_ap.verticalMode; }
    QString armedLateralMode()  const { return m_ap.armedLateralMode; }
    QString armedVerticalMode() const { return m_ap.armedVerticalMode; }
    QString approachMode()      const { return m_ap.approachMode; }
    QString speedMode()         const { return m_ap.speedMode; }
    QString headingMode()       const { return m_ap.headingMode; }
    QString altitudeMode()      const { return m_ap.altitudeMode; }
    QString autoThrustMode()    const { return m_ap.autoThrustMode; }
    double  targetPitch()       const { return m_ap.targetPitch; }
    double  targetRoll()        const { return m_ap.targetRoll; }
    double  ilsLocDeviation()   const { return m_ap.ilsLocDeviation; }
    double  ilsGsDeviation()    const { return m_ap.ilsGsDeviation; }
    bool    ilsArmed()          const { return m_ap.ilsArmed; }

    double selectedSpeed()    const { return m_ap.selectedSpeed; }
    double selectedHeading()  const { return m_ap.selectedHeading; }
    double selectedAltitude() const { return m_ap.selectedAltitude; }
    double selectedVS()       const { return m_ap.selectedVS; }
    double selectedMach()     const { return m_ap.selectedMach; }

    double v1()   const { return m_v1; }
    double vr()   const { return m_vr; }
    double v2()   const { return m_v2; }
    double vapp() const { return m_vapp; }

    QString flightPhase()    const { return m_ap.flightPhase; }
    QString flightMode()     const { return m_ap.flightMode; }
    bool    normalLawActive() const { return m_ap.normalLawActive; }

    double sidestickPitch() const { return m_sidestickPitch; }
    double sidestickRoll()  const { return m_sidestickRoll; }
    double rudderPedal()    const { return m_rudderPedal; }
    int    flapConfig()     const { return m_flapConfig; }

    // ── Setters ───────────────────────────────────────────────────────────────
    void setAp1Active(bool v);
    void setAp2Active(bool v);
    void setAthrActive(bool v);
    void setFdActive(bool v);
    void setSelectedSpeed(double v);
    void setSelectedHeading(double v);
    void setSelectedAltitude(double v);
    void setSelectedVS(double v);
    void setSelectedMach(double v);
    void setV1(double v);
    void setVr(double v);
    void setV2(double v);
    void setVapp(double v);
    void setSidestickPitch(double v) { m_sidestickPitch = v; }
    void setSidestickRoll(double v)  { m_sidestickRoll  = v; }
    void setRudderPedal(double v)    { m_rudderPedal    = v; }
    void setFlapConfig(int v) { m_flapConfig = v; emit dataChanged(); }

    void setEngine1Thrust(double v);
    void setEngine2Thrust(double v);
    void setTla1(double v);
    void setTla2(double v);
    void setSpeedbrakeLever(double v);
    void setSpeedbrakeArmed(bool v);
    void setFlapHandleIndex(int v);
    void setGearDown(bool v);
    void setAutobrakeSelector(int v);
    void setParkingBrake(bool v);
    void setRunwayCondition(int v);

    // ── QML Invokables ────────────────────────────────────────────────────────
    Q_INVOKABLE void tick(double dt);
    Q_INVOKABLE void engageAP1();
    Q_INVOKABLE void disengageAP1();
    Q_INVOKABLE void engageAP2();
    Q_INVOKABLE void disengageAP2();
    Q_INVOKABLE void toggleFD();
    Q_INVOKABLE void toggleATHR();
    Q_INVOKABLE void setLateralMode(const QString &mode);
    Q_INVOKABLE void setVerticalMode(const QString &mode);
    Q_INVOKABLE void setAutoThrustMode(const QString &mode);
    Q_INVOKABLE void setFlightPhase(const QString &phase);
    Q_INVOKABLE void applyFailure(const QString &failureId, bool active);
    Q_INVOKABLE void pushSpeed();
    Q_INVOKABLE void pullSpeed();
    Q_INVOKABLE void pushHeading();
    Q_INVOKABLE void pullHeading();
    Q_INVOKABLE void pushAltitude();
    Q_INVOKABLE void pullAltitude();

    // Legacy manual attitude — kept for Yoke backward compat
    Q_INVOKABLE void setManualAttitude(double pitch, double roll);

    // ISA utilities
    Q_INVOKABLE static double isaTemperature(double altitudeFt);
    Q_INVOKABLE static double isaPressure(double altitudeFt);
    Q_INVOKABLE static double iasToMach(double ias, double altitudeFt);
    Q_INVOKABLE static double machToIas(double mach, double altitudeFt);

signals:
    void dataChanged();
    void speedProtChanged();
    void autopilotChanged();
    void fcuChanged();
    void vSpeedsChanged();
    void phaseChanged();
    void activeWaypointIndexChanged();

private slots:
    void onTick();

private:
    void updatePhysics(double dt);
    void updateSpeedProtection();

    // ── Timer ─────────────────────────────────────────────────────────────────
    QTimer m_timer;

    // ── Sub-modules (Phase 1 decomposition) ───────────────────────────────────
    EngineModel         m_engines;
    AutopilotController m_ap;
    ThrottleQuadrantModel m_throttle;
    GroundModel         m_ground;

    // ── Simulation clock ──────────────────────────────────────────────────────
    double m_simTime = 0.0;
    double m_prevIas = 270.0;

    // ── Aircraft state (aviation units) ───────────────────────────────────────
    double  m_pitch       = 2.5;
    double  m_roll        = 0.0;
    double  m_heading     = 284.0;
    double  m_latitude    = 50.0379;
    double  m_longitude   =  8.5622;
    int     m_activeWaypointIndex = 1;

    double  m_ias         = 270.0;
    double  m_mach        = 0.78;
    double  m_tas         = 460.0;
    double  m_groundSpeed = 450.0;
    double  m_altitude    = 32000.0;
    double  m_vsi         = 0.0;
    double  m_speedTrend  = 0.0;

    double  m_alpha       = 2.5;   // AoA deg
    double  m_beta        = 0.0;   // sideslip deg
    double  m_nz          = 1.0;   // load factor g
    double  m_gamma       = 0.0;   // flight path angle deg
    double  m_pRate       = 0.0;
    double  m_qRate       = 0.0;
    double  m_rRate       = 0.0;

    // ── Speed protection ──────────────────────────────────────────────────────
    double  m_vLs           = 210.0;
    double  m_vMax          = 350.0;
    double  m_vAlphaProt    = 200.0;
    double  m_vAlphaMax     = 185.0;
    double  m_vStallWarn    = 190.0;
    double  m_greenDot      = 220.0;
    double  m_slatRetract   = 180.0;
    double  m_flapRetract   = 195.0;
    double  m_vFeNext       = 230.0;

    // ── V-Speeds ──────────────────────────────────────────────────────────────
    double  m_v1     = 140.0;
    double  m_vr     = 145.0;
    double  m_v2     = 150.0;
    double  m_vapp   = 135.0;

    // ── Pilot inputs ──────────────────────────────────────────────────────────
    double m_sidestickPitch = 0.0; // -1..+1  (+ = pitch up demand)
    double m_sidestickRoll  = 0.0; // -1..+1  (+ = right roll)
    double m_rudderPedal    = 0.0; // -1..+1
    int    m_flapConfig     = 0;   // 0=clean, 1..4=F1/2/3/FULL

    // ── Ground braking (SystemsManager::getBrakingChannel bridged in) ────────
    QString m_brakingChannel = "NORMAL";
    bool    m_wasBraking     = false; // rising-edge detector for accumulator drain

    QStringList m_activeFailures;
};
