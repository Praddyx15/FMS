# 05 — Avionics & Autopilot Architecture

## 1. Avionics Computer Architecture

### 1.1 Computer Inventory (A320neo)

| Computer | Qty | Current | Required |
|----------|-----|---------|----------|
| FMGC (Flight Management & Guidance) | 2 | 1 (partial) | Full dual |
| FAC (Flight Augmentation Computer) | 2 | ❌ | Yaw damper, rudder travel limit |
| ELAC (Elevator Aileron Computer) | 2 | ❌ | Normal/alternate law pitch+roll |
| SEC (Spoiler Elevator Computer) | 3 | ❌ | Spoiler control, pitch backup |
| FCDC (Flight Control Data Concentrator) | 2 | ❌ | Data relay to ECAM |
| FCU (Flight Control Unit) | 1 | ✅ | — |
| ADIRS (Air Data Inertial Ref) | 3 | Flags only | Full alignment + degradation |
| ECAM/DMC (Display Management) | 2+3 | Display only | State-driven |
| LGCIU (Landing Gear Control) | 2 | ❌ | Gear logic |
| GPWS/EGPWS | 1 | ❌ | Terrain alerts |
| TCAS | 1 | Overlay only | TA/RA logic |
| WXR (Weather Radar) | 1 | Mock | Parametric model |
| Transponder | 1 | ❌ | Mode S |
| Radio Management Panel | 2 | ❌ | VHF/NAV frequency mgmt |
| Clock (CPIOM) | 1 | ❌ | Chrono/ET/UTC |

### 1.2 ADIRS Architecture

```cpp
class ADIRS {
    struct ADIRUnit {
        enum State { OFF, ALIGN, NAV, ATT, FAULT };
        State state = OFF;
        double alignTimeRemaining;  // seconds (full align = 600s / 10min)
        double alignProgress;       // 0.0 to 1.0

        // IR outputs (valid after alignment)
        double latitude, longitude;
        double heading, track;
        double pitch, roll;
        double groundSpeed;
        double windSpeed, windDirection;
        double drift;               // deg/hr (gyro drift in ATT mode)

        // ADR outputs
        double ias, tas, mach;
        double altitude;
        double verticalSpeed;
        double aoa;
        double tat, sat;
        double pressure;

        bool irValid() const { return state == NAV; }
        bool adrValid() const { return state == NAV || state == ATT; }
    };

    ADIRUnit m_unit[3];  // ADIRS 1, 2, 3

    // Switching logic
    bool m_attHdgSwitchToIR3 = false;
    bool m_airDataSwitch = false;  // normal=false → ADR1→PFD1, ADR2→PFD2

    void tick(double dt);
    void startAlignment(int unit);  // 0-2
};
```

### 1.3 IRS Alignment Sequence
```
OFF → knob to NAV → ALIGN begins
  0-10 min: Position converges
  At ~90s: ADR data available (IAS, ALT)
  At ~600s: Full NAV mode → heading, position, groundspeed valid
  
Fast align (on ground, known position): ~7 minutes
Full align (no GPS): 10 minutes
Degraded (ATT only): immediate attitude, no position
```

---

## 2. Autopilot / Flight Director Architecture

### 2.1 AP/FD Mode State Machine

```cpp
class AutopilotController {
    // Engagement
    bool m_ap1Engaged, m_ap2Engaged;
    bool m_fdActive;
    bool m_athrEngaged;

    // Lateral modes
    enum class LatMode {
        NONE, HDG, TRK, NAV, LOC, ROLLOUT, GA_TRK, RWY, RWY_TRK
    };
    LatMode m_activeLatMode;
    LatMode m_armedLatMode;

    // Vertical modes
    enum class VertMode {
        NONE, ALT, ALT_STAR, ALT_CRZ, ALT_CST,
        CLB, DES, OP_CLB, OP_DES,
        VS, FPA,
        GS, GS_STAR, FINAL, FLARE,
        SRS, TCAS,
        EXPEDITE
    };
    VertMode m_activeVertMode;
    VertMode m_armedVertMode;

    // A/THR modes
    enum class AThrMode {
        NONE, SPEED, MACH,
        THR_CLB, THR_MCT, THR_IDLE,
        THR_LVR, A_FLOOR, TOGA_LK,
        RETARD
    };
    AThrMode m_activeAThrMode;

    // Approach
    enum class ApprMode { NONE, ILS, RNAV, VOR, NDB };
    ApprMode m_approachCapability;

    // Mode transitions
    void engageAP(int which);
    void disengageAP(int which);
    void selectLateralMode(LatMode mode);
    void selectVerticalMode(VertMode mode);
    void pushSpeed();   // managed speed
    void pullSpeed();   // selected speed
    void pushHeading(); // managed heading (NAV)
    void pullHeading(); // selected heading (HDG/TRK)
    void pushAltitude();// managed altitude
    void pullAltitude();// selected altitude (open CLB/DES)

    // FMA output
    struct FMAState {
        // Column 1: Speed/Mach
        QString thrustMode;      // "THR CLB", "SPEED", "MACH", etc.
        bool thrustModeArmed;

        // Column 2: Vertical
        QString verticalMode;    // "CLB", "ALT*", "VS +1500", etc.
        QString verticalArmed;   // "ALT"

        // Column 3: Lateral
        QString lateralMode;     // "NAV", "HDG 284", "LOC*", etc.
        QString lateralArmed;    // "LOC"

        // Column 4: Approach
        QString approachMode;    // "CAT 3 DUAL", "CAT 2", etc.
        bool dualApEnabled;

        // Column 5: AP/FD/A-THR engagement
        QString apFdStatus;      // "AP1+2", "1FD2", etc.
        QString athrStatus;      // "A/THR"
    };
};
```

### 2.2 Mode Transition Rules (Key Examples)

```
FCU ALT knob PUSH (with AP in CLB):
  → If above selected ALT: arm ALT, continue CLB
  → If at selected ALT: engage ALT (hold)
  → ALT* captures within ±200ft

FCU ALT knob PULL:
  → If current ALT < selected ALT: OP CLB (open climb)
  → If current ALT > selected ALT: OP DES (open descent)

LOC arm → LOC capture:
  → When LOC deviation < 0.5 dot: LAT = LOC*
  → When LOC track established: LAT = LOC

GS arm → GS capture:
  → When G/S deviation < 0.5 dot from below: VERT = GS*
  → When GS tracked: VERT = GS
```

### 2.3 Flight Director Guidance

```cpp
struct FDCommand {
    double pitchBar;   // deg (+ up)
    double rollBar;    // deg (+ right)
};

// FD computes guidance for:
//   - SRS (initial climb: V2+10)
//   - CLB/DES (managed speed schedule)
//   - VS/FPA (hold vertical rate/angle)
//   - LOC/GS (ILS tracking)
//   - GA (go-around guidance: SRS + wings level)
```

---

## 3. Flight Control Laws (Fly-By-Wire)

### 3.1 Normal Law

```
Pitch: Load-factor demand (C* law)
  - Sidestick commands Nz (load factor)
  - Neutral stick → 1g (wings level) or current g in turn
  - Auto-trim: no manual trim needed
  - Protections: alpha floor, pitch attitude (30°up / 15°down)

Roll: Direct roll rate command
  - Stick deflection → roll rate (15°/s max)
  - Release stick → roll back to 0° (if φ < 33°)
  - Bank angle protection: limit 67° (hard), soft at 33°
  - Automatic turn coordination (yaw)

Yaw: Yaw damper + turn coordination
  - Automatic rudder with roll
  - Sideslip damping
```

### 3.2 Alternate Law (Degraded)

```
Pitch: Load-factor demand without protections
  - No alpha floor
  - No pitch attitude limit
  - Manual trim available

Roll: Direct law
  - No bank angle protection
  - No auto-coordination

Triggered by: dual ELAC failure, dual ADR loss
```

### 3.3 Direct Law (Further Degraded)

```
Pitch: Direct stick-to-elevator
Roll: Direct stick-to-aileron
Yaw: Direct pedal-to-rudder
No stability augmentation
No protections
Triggered by: triple ADIRS failure, dual ELAC+SEC
```

---

## 4. Throttle Quadrant Logic

### 4.1 Detent Positions

```
Position    TLA°    N1 Target   A/THR Mode
────────    ────    ─────────   ──────────
IDLE         0      19.5%       THR IDLE
CL          25      ~85%        THR CLB (managed)
MCT         35      ~92.5%      THR MCT
FLX/MCT     35      flex temp   THR FLX (FLEX TO)
TOGA        45      ~96%        THR TOGA
REV         -20     ~75%        Reverse (ground only)
```

### 4.2 A/THR Engagement Rules

```
A/THR active + levers in CL detent:
  → A/THR commands N1 automatically (SPEED/MACH mode)

A/THR active + levers above CL:
  → A/THR disconnects, manual thrust

A/THR + alpha floor:
  → A/THR → A.FLOOR mode → TOGA thrust (protection)
  → Pilot must reset with instinctive disconnect
```
