# 04 — FMS & Navigation Architecture

## 1. FMS Architecture (ARINC 702A Conceptual Compliance)

### 1.1 Dual FMGC Model

```
┌──────────────┐    ┌──────────────┐
│   FMGC 1     │    │   FMGC 2     │
│  (Master)    │←──→│  (Slave)     │
│  MCDU 1      │    │  MCDU 2      │
│  FM + FG     │    │  FM + FG     │
└──────┬───────┘    └──────┬───────┘
       │ crosslink          │
       └────────┬───────────┘
                │
        ┌───────▼────────┐
        │  Active Plan   │
        │  (synchronized)│
        └────────────────┘
```

Each FMGC contains:
- **FM (Flight Management)**: Route, performance, predictions
- **FG (Flight Guidance)**: AP/FD command generation

Current state: Single `FMSComputer` — no dual redundancy.

### 1.2 Flight Plan Management

```cpp
class FlightPlanManager {
    // Three concurrent plans (A320 standard)
    FlightPlan m_activePlan;     // Currently executing
    FlightPlan m_secondaryPlan;  // SEC F-PLN
    FlightPlan m_temporaryPlan;  // During MCDU editing

    // Plan structure
    struct FlightPlan {
        QString origin;          // ICAO
        QString destination;     // ICAO
        QString alternate;       // ICAO
        int cruiseFL;
        int costIndex;

        // Departure
        QString departureRunway;
        QString sid;
        QString sidTransition;

        // Enroute
        QVector<FlightPlanLeg> legs;  // waypoints + constraints

        // Arrival
        QString star;
        QString starTransition;
        QString approach;
        QString arrivalRunway;
        QString missedApproach;

        // Computed
        double totalDistance;     // NM
        double totalTime;        // minutes
        double totalFuel;        // kg
    };

    struct FlightPlanLeg {
        QString ident;
        double lat, lon;
        double altitude;         // constraint alt (0=none)
        double speed;            // constraint speed (0=none)
        char altConstraintType;  // 'A'=at, 'B'=at-or-below, 'C'=at-or-above
        char speedConstraintType;
        double legDistance;      // NM
        double cumulativeDistance; // NM
        double etaMinutes;       // from origin
        double efobKg;           // estimated fuel on board
        QString airway;          // airway ident if on airway
        bool discontinuity;      // flight plan discontinuity
        bool overfly;            // must overfly (not fly-by)
    };

    // Operations
    void activateTemporary();   // TMPY → Active
    void cancelTemporary();     // Discard TMPY
    void copyToSecondary();     // Active → SEC
    void insertWaypoint(int index, const QString& ident);
    void deleteWaypoint(int index);
    void insertDiscontinuity(int index);
    void directTo(const QString& ident);
};
```

---

## 2. Route Management

### 2.1 SID/STAR/Approach Integration

```cpp
class ProcedureManager {
    // Load from NavigationDatabase
    QVector<SIDProcedure> getSIDsForRunway(const QString& airport, const QString& runway);
    QVector<STARProcedure> getSTARsForRunway(const QString& airport, const QString& runway);
    QVector<ApproachProcedure> getApproachesForRunway(const QString& airport, const QString& runway);

    struct SIDProcedure {
        QString name;
        QString runway;
        QVector<ProcedureWaypoint> waypoints;
        QVector<Transition> transitions;
    };

    struct ApproachProcedure {
        QString name;
        ApproachType type;  // ILS, RNAV, VOR, NDB, VISUAL, RNP, LOC
        QString runway;
        ApproachCategory category;  // CAT I/II/IIIA/IIIB/IIIC
        int decisionAltitude;       // ft
        int minimumRVR;             // m
        double glideslopeAngle;     // deg
        int finalApproachCourse;    // deg
        QVector<ProcedureWaypoint> waypoints;
        MissedApproachProcedure missedApproach;
    };
};
```

### 2.2 Airway-Based Routing

```
Example: EDDF → LFPG via airways
  EDDF/25L OBOKA1A OBOKA UL607 MASAK UT180 VALDA STAR LFPG/26L
```

Currently missing — routing is waypoint-to-waypoint only.

---

## 3. Performance Management

### 3.1 Performance Phases

```cpp
class PerformanceManager {
    // Phase-specific computation
    TakeoffPerf computeTakeoff(const TakeoffParams& params);
    ClimbPerf computeClimb(double fromAlt, double toAlt);
    CruisePerf computeCruise(double distance, double fl);
    DescentPerf computeDescent(double fromAlt, double toAlt);
    ApproachPerf computeApproach(const ApproachParams& params);

    struct TakeoffPerf {
        double v1, vr, v2;           // kt
        double flexTemp;             // °C (if FLEX TO)
        double takeoffThrust;        // N1%
        double accelerationAlt;      // ft
        double thrustReductionAlt;   // ft
        double toDistance;            // m
    };

    struct ClimbPerf {
        double climbSpeed;            // kt or Mach
        double climbN1;               // %
        double timeToTOC;             // min
        double fuelToTOC;             // kg
        double distanceToTOC;         // NM
    };

    struct CruisePerf {
        double optFL;                 // optimal FL
        double maxFL;                 // max FL for weight
        double recMaxFL;              // recommended max
        double stepClimbFL;           // next step
        double specificRange;         // NM/kg
        double mach;                  // cruise Mach
    };

    // V-Speed computation (weight/config dependent)
    double computeVLS(double mass, int flapConfig);
    double computeGreenDot(double mass);
    double computeF_Speed(double mass);
    double computeS_Speed(double mass);
    double computeVFE(int flapConfig);
    double computeVapp(double mass, double windComponent);
};
```

### 3.2 Prediction Engine

```cpp
class PredictionEngine {
    // Per-waypoint predictions
    struct WaypointPrediction {
        double eta;           // seconds from now
        double efob;          // kg fuel remaining
        double distanceToGo;  // NM
        double predictedAlt;  // ft
        double predictedSpeed;// kt
    };

    // Key points
    double computeTOC();     // Top of Climb — NM from departure
    double computeTOD();     // Top of Descent — NM from destination
    double computeDecelPoint(); // Speed reduction point

    // Fuel predictions
    double tripFuel();       // kg
    double alternateFuel();  // kg
    double holdingFuel();    // kg
    double extraFuel();      // kg
    double minFuelAtDest();  // kg

    void updatePredictions(); // called at 1 Hz
};
```

---

## 4. Navigation Database (ARINC 424 Compliance)

### 4.1 Database Structure

```cpp
class NavigationDatabase {
    // Data stores (loaded from CIFP/custom sources)
    QHash<QString, Airport> m_airports;
    QHash<QString, Navaid> m_navaids;      // VOR, DME, NDB, ILS
    QHash<QString, Waypoint> m_waypoints;   // named fixes
    QHash<QString, Airway> m_airways;
    QHash<QString, QVector<SIDProcedure>> m_sids;    // keyed by airport
    QHash<QString, QVector<STARProcedure>> m_stars;
    QHash<QString, QVector<ApproachProcedure>> m_approaches;
    QHash<QString, QVector<HoldingProcedure>> m_holdings;

    // AIRAC management
    AIRACCycle m_currentCycle;
    AIRACCycle m_nextCycle;
    QDate m_effectiveDate;
    QDate m_expirationDate;

    struct AIRACCycle {
        int year;
        int cycle;          // 1-13
        QDate effectiveDate;
        QDate expirationDate;
        QString dataSource;
        QString checksum;
    };

    // Lookup
    bool lookupWaypoint(const QString& ident, double& lat, double& lon);
    QVector<Navaid> findNavaidsInRange(double lat, double lon, double rangeNM);
    Airport getAirport(const QString& icao);
};
```

### 4.2 AIRAC Cycle Management

```
AIRAC cycles: 28-day update intervals (13 per year)
Current cycle format: YYNN (e.g., 2613 = year 2026, cycle 13)

NavDB update flow:
  1. Load CIFP file → parse ARINC 424 records
  2. Validate checksums
  3. Store with cycle metadata
  4. Support dual-database (current + next cycle)
  5. Auto-switch on effective date
```

---

## 5. MCDU Page Architecture

### Required Pages (A320 Standard)

| Page | Key | Current | Status |
|------|-----|---------|--------|
| MCDU MENU | MCDU MENU | ✅ | Exists |
| INIT A | INIT | ✅ | Exists — needs SID linking |
| INIT B | (scroll) | ✅ | Exists — needs perf computation |
| F-PLN | F-PLN | ✅ | Exists — needs SID/STAR/constraint display |
| RAD NAV | RAD NAV | ✅ | Exists — needs live nav tuning |
| PERF (all phases) | PERF | ✅ stubs | **Needs computation backend** |
| PROG | PROG | ✅ | Needs live predictions |
| DIR TO | DIR | ✅ stub | **Needs active plan integration** |
| SEC F-PLN | SEC F-PLN | ✅ stub | **Needs secondary plan engine** |
| FUEL PRED | FUEL PRED | ✅ stub | **Needs prediction engine** |
| DATA | DATA | ✅ | — |
| DEPARTURE | (from F-PLN) | ✅ stub | **Needs SID selection logic** |
| ARRIVAL | (from F-PLN) | ✅ stub | **Needs STAR/APP selection logic** |
| WIND | (from PERF) | ✅ | — |
| HOLD | NEW | ❌ | **Missing** |
| OFFSET | NEW | ❌ | **Missing** |
| FIX INFO | NEW | ❌ | **Missing** |
