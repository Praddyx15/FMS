# 07 — Training & Instructor Architecture

## 1. Training Mode Framework

### 1.1 Twelve Training Modes

```cpp
enum class TrainingMode {
    MODE_1_AIRCRAFT_FAMILIARIZATION,  // Interactive 3D cockpit tour
    MODE_2_COCKPIT_FAMILIARIZATION,   // Panel-by-panel walkthrough
    MODE_3_MCDU_TRAINING,             // Guided MCDU page exercises
    MODE_4_FMS_PROCEDURES,            // SID/STAR/approach entry practice
    MODE_5_FLIGHT_PLANNING,           // Full flight plan creation
    MODE_6_NORMAL_PROCEDURES,         // SOPs: preflight→shutdown
    MODE_7_ABNORMAL_PROCEDURES,       // Non-normal checklists (ECAM)
    MODE_8_EMERGENCY_PROCEDURES,      // Memory items + QRH
    MODE_9_SYSTEMS_TRAINING,          // Individual system deep-dives
    MODE_10_INSTRUMENT_PROCEDURES,    // ILS/RNAV/VOR/NDB approaches
    MODE_11_TYPE_RATING_PREP,         // Full syllabus exam mode
    MODE_12_INSTRUCTOR_LED_SESSION    // Live instructor control
};
```

### 1.2 Mode Configuration

```cpp
struct TrainingModeConfig {
    TrainingMode mode;
    QString displayName;
    QString description;

    // What's active
    bool aircraftSimActive;       // 6DOF running?
    bool mcduEnabled;             // MCDU interactive?
    bool fcuEnabled;              // FCU interactive?
    bool overheadEnabled;         // OHP interactive?
    bool failuresEnabled;         // Can failures occur?
    bool assessmentActive;        // Grading active?

    // Initial conditions
    QString scenarioId;           // preset scenario (optional)
    FlightPhase startPhase;       // preflight, cruise, approach, etc.

    // Display config
    bool showHints;               // Show tooltips/guidance
    bool showProcedureChecklist;  // Side panel with SOP steps
    bool freezeOnError;           // Pause sim on wrong action
    bool allowSkip;               // Can skip steps
};
```

### 1.3 Mode Details

| Mode | Sim Active | MCDU | FCU | OHP | Failures | Grading | Description |
|------|------------|------|-----|-----|----------|---------|-------------|
| 1 Aircraft Fam. | ❌ | View | View | View | ❌ | ❌ | Click-to-learn cockpit tour |
| 2 Cockpit Fam. | ❌ | View | View | View | ❌ | ❌ | Panel identification exercises |
| 3 MCDU Training | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | Guided MCDU data entry |
| 4 FMS Procedures | Partial | ✅ | ✅ | ❌ | ❌ | ✅ | SID/STAR/approach selection |
| 5 Flight Planning | Partial | ✅ | ✅ | ❌ | ❌ | ✅ | Complete flight plan entry |
| 6 Normal Procs | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | Full SOP flow |
| 7 Abnormal Procs | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ECAM non-normal response |
| 8 Emergency Procs | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Memory items + QRH |
| 9 Systems Training | ❌ | View | View | ✅ | ✅ | ✅ | System operation exercises |
| 10 Instrument Procs | ✅ | ✅ | ✅ | ❌ | Optional | ✅ | Approach procedures |
| 11 Type Rating | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Full exam (timed) |
| 12 Instructor Led | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Instructor controls everything |

---

## 2. Instructor Station Architecture

### 2.1 Instructor Capabilities

```cpp
class InstructorStationEngine {
    // ── Scenario Management ──────────────────────────
    void createScenario(const ScenarioConfig& config);
    void editScenario(const QString& id, const ScenarioConfig& config);
    void loadScenario(const QString& id);
    void saveScenario(const QString& id);
    QVector<ScenarioSummary> listScenarios();

    // ── Failure Injection ────────────────────────────
    void injectFailure(const FailureConfig& failure);
    void scheduleFailure(const FailureConfig& failure, double triggerTime);
    void scheduleFailureAtPhase(const FailureConfig& failure, FlightPhase phase);
    void clearFailure(const QString& failureId);
    void clearAllFailures();

    // ── Position & State Control ─────────────────────
    void setAircraftPosition(double lat, double lon, double alt, double hdg);
    void setAircraftSpeed(double ias);
    void setFlightPhase(FlightPhase phase);
    void freezeSimulation();
    void unfreezeSimulation();
    void resetToInitialConditions();

    // ── Weather Control ──────────────────────────────
    void setWind(double direction, double speed, double gust);
    void setVisibility(double meters);
    void setCeiling(double feet);
    void setTemperature(double oat, double dewpoint);
    void setRunwayCondition(RunwayCondition cond);
    void setTurbulence(TurbulenceLevel level);
    void setWindshear(bool active, double intensity);

    // ── Traffic Control ──────────────────────────────
    void addTraffic(const TrafficConfig& traffic);
    void removeTraffic(const QString& id);
    void clearAllTraffic();

    // ── Performance Monitoring ───────────────────────
    SessionMetrics getSessionMetrics() const;
    QVector<DeviationEvent> getDeviations() const;

    // ── Session Control ──────────────────────────────
    void startSession(const SessionConfig& config);
    void pauseSession();
    void resumeSession();
    void endSession();
    SessionReport generateReport();
};
```

### 2.2 Scenario Configuration

```cpp
struct ScenarioConfig {
    QString name;
    QString description;
    DifficultyLevel difficulty;
    ScenarioCategory category;

    // Initial conditions
    struct InitialConditions {
        double latitude, longitude;
        double altitude;           // ft
        double heading;            // deg
        double ias;                // kt
        double grossWeight;        // kg
        int flapConfig;
        bool onGround;
        bool enginesRunning;
        FlightPhase phase;

        // Flight plan
        QString departure;         // ICAO
        QString destination;       // ICAO
        QString sid, star, approach;
        QVector<QString> enrouteWaypoints;

        // Weather
        double windDir, windSpeed;
        double visibility;
        double ceiling;
        double oat;
        RunwayCondition runwayState;
    } initial;

    // Objectives
    QVector<Objective> objectives;
    struct Objective {
        QString description;
        ObjectiveType type;      // maintain_alt, complete_approach, handle_failure, etc.
        QVariantMap criteria;    // tolerances, time limits
        int points;
    };

    // Scheduled failures
    QVector<ScheduledFailure> scheduledFailures;
    struct ScheduledFailure {
        FailureConfig failure;
        TriggerType trigger;     // TIME, PHASE, ALTITUDE, SPEED, POSITION
        double triggerValue;
        double triggerDelay;     // seconds after trigger condition
    };

    // Time limit
    int timeLimitMinutes;
    double passingScore;
};
```

---

## 3. Recording & Replay System

### 3.1 State Recording

```cpp
class RecordingEngine {
    // Record state at configurable rate (default: 4 Hz)
    struct StateSnapshot {
        double timestamp;          // seconds from session start
        AircraftState aircraft;    // full aircraft state
        AvionicsState avionics;    // AP/FD/FMA/FCU targets
        SystemsState systems;      // hydraulic/elec/fuel
        QStringList activeFailures;
        QString mcduPage;
        QString scratchpad;
    };

    struct EventRecord {
        double timestamp;
        EventType type;            // PILOT_INPUT, FAILURE, MODE_CHANGE, etc.
        QString description;
        QVariantMap data;
    };

    void startRecording(const QString& sessionId);
    void stopRecording();
    void addSnapshot(const StateSnapshot& snap);
    void addEvent(const EventRecord& event);

    // Replay
    void loadRecording(const QString& sessionId);
    void play();
    void pause();
    void seekTo(double timestamp);
    void setPlaybackSpeed(double factor);  // 0.25x to 8x
    StateSnapshot getSnapshotAt(double timestamp);
};
```

### 3.2 Events to Record

| Category | Events |
|----------|--------|
| Pilot Inputs | Sidestick, rudder, throttle, brake, gear, flap, FCU knob/button |
| MCDU Inputs | Key press, LSK select, page navigation, scratchpad entry |
| AP/FD | Mode engage/disengage, mode arm/capture, FMA change |
| Failures | Injection, clearance, cascading effects |
| Navigation | Active waypoint change, direct-to, plan modification |
| Flight Phase | Phase transition (preflight→taxi→takeoff→climb, etc.) |
| ECAM | Warning/caution trigger, system page auto-display |
| Instructor | Position resets, weather changes, freeze/unfreeze |

---

## 4. Assessment & Analytics Engine

### 4.1 Assessment Criteria

```cpp
class AssessmentEngine {
    struct AssessmentResult {
        double overallScore;       // 0-100
        bool passed;

        // Category scores
        double flightPathScore;    // altitude, track, speed adherence
        double procedureScore;     // checklist compliance
        double decisionMakingScore;// failure response time/accuracy
        double fuelManagementScore;
        double approachStabilityScore;

        QVector<Deviation> deviations;
        QVector<ChecklistCompletion> checklistResults;
    };

    // Tolerances (airline-grade)
    struct Tolerances {
        double altitudeDeviation = 100.0;   // ft (±)
        double speedDeviation = 10.0;       // kt (±)
        double headingDeviation = 5.0;      // deg (±)
        double trackDeviation = 2.5;        // NM (cross-track)
        double glideslopeDeviation = 0.5;   // dot
        double localizerDeviation = 0.5;    // dot
        double vsiAtTouchdown = -600.0;     // ft/min max
        double lateralAtTouchdown = 10.0;   // m from centerline
    };
};
```

### 4.2 Analytics Dashboard Data

| Metric | Computation |
|--------|-------------|
| Flight Path Accuracy | Cross-track error vs planned route |
| Altitude Compliance | Deviation from assigned altitude over time |
| Speed Compliance | Deviation from managed/selected speed |
| Fuel Efficiency | Actual vs predicted fuel burn |
| Approach Stability | Gates: 1000ft (speed±10, config, descent rate) |
| Checklist Compliance | Items completed in sequence, none skipped |
| Failure Response | Time from failure onset to correct action |
| Training Progress | Sessions completed, scores over time, weak areas |

---

## 5. Multi-User Architecture (Future-Ready)

### 5.1 Roles

```
Instructor ──┬── Controls simulation
              ├── Injects failures
              ├── Monitors student
              └── Grades performance

Student    ──┬── Operates cockpit
              ├── Follows procedures
              └── Views own analytics

Observer   ──┬── Read-only view
              └── Can view any display
```

### 5.2 Communication Protocol

```
┌──────────────┐        WebSocket / LAN        ┌──────────────┐
│  Instructor  │◄──────────────────────────────►│   Student    │
│  Station     │    State sync (4 Hz)           │   Cockpit    │
│              │    Events (immediate)          │              │
│              │    Commands (immediate)        │              │
└──────────────┘                                └──────────────┘
                          ▲
                          │
                    ┌─────┴──────┐
                    │  Observer  │
                    │  (read)    │
                    └────────────┘
```

### 5.3 Network Message Types

```cpp
enum class NetMessageType {
    // State sync (high frequency)
    AIRCRAFT_STATE,
    AVIONICS_STATE,
    SYSTEMS_STATE,

    // Commands (instructor → student)
    SET_POSITION,
    INJECT_FAILURE,
    CLEAR_FAILURE,
    SET_WEATHER,
    FREEZE_SIM,
    UNFREEZE_SIM,

    // Events (any → all)
    MODE_CHANGE,
    PHASE_CHANGE,
    MCDU_INPUT,
    SESSION_START,
    SESSION_END,

    // Admin
    ROLE_ASSIGN,
    HEARTBEAT
};
```
