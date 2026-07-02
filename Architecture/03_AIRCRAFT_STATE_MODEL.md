# 03 — Aircraft State Model & Flight Dynamics

## 1. Complete Aircraft State Vector

```cpp
struct AircraftState {
    // ── Position ──────────────────────────────────────
    double latitude;          // deg (WGS-84)
    double longitude;         // deg (WGS-84)
    double altitudeGeometric; // ft (GPS/geometric)
    double altitudePressure;  // ft (barometric, QNH-corrected)
    double altitudeRadio;     // ft AGL (radio altimeter)

    // ── Velocity ──────────────────────────────────────
    double heading;           // deg magnetic
    double track;             // deg magnetic (heading + drift angle)
    double groundSpeed;       // kt
    double trueAirspeed;      // kt
    double indicatedAirspeed; // kt (CAS)
    double machNumber;        // dimensionless
    double verticalSpeed;     // ft/min

    // ── Attitude ──────────────────────────────────────
    double pitch;             // deg (+ nose up)
    double roll;              // deg (+ right wing down)
    double yaw;               // deg (body axis)

    // ── Angular Rates ─────────────────────────────────
    double pRate;             // deg/s roll rate
    double qRate;             // deg/s pitch rate
    double rRate;             // deg/s yaw rate

    // ── Aerodynamic ───────────────────────────────────
    double alpha;             // deg angle of attack
    double beta;              // deg sideslip
    double nz;                // g load factor
    double gamma;             // deg flight path angle

    // ── Acceleration ──────────────────────────────────
    double axBody;            // m/s² longitudinal
    double ayBody;            // m/s² lateral
    double azBody;            // m/s² normal

    // ── Wind ──────────────────────────────────────────
    double windDirection;     // deg (from)
    double windSpeed;         // kt
    double windComponentHead; // kt (headwind +, tailwind -)
    double windComponentCross;// kt (from left +)

    // ── Atmosphere ────────────────────────────────────
    double oat;               // °C outside air temperature (SAT)
    double tat;               // °C total air temperature
    double isaDeviation;      // °C delta from ISA
    double pressure;          // hPa static pressure
    double density;           // kg/m³

    // ── Weight & Balance ──────────────────────────────
    double aircraftMass;      // kg (instantaneous, fuel-burn adjusted)
    double cgPercMAC;         // % MAC center of gravity
    double zeroFuelWeight;    // kg
    double grossWeight;       // kg (ZFW + total fuel)

    // ── Fuel State ────────────────────────────────────
    double fuelLeftOuter;     // kg
    double fuelLeftInner;     // kg
    double fuelCenter;        // kg
    double fuelRightInner;    // kg
    double fuelRightOuter;    // kg
    double fuelTotalKg;       // kg (sum)
    double fuelFlowLeft;      // kg/hr
    double fuelFlowRight;     // kg/hr
    double fuelUsedLeft;      // kg (cumulative)
    double fuelUsedRight;     // kg (cumulative)
};
```

---

## 2. A320neo / LEAP-1A Specific Constants

```cpp
namespace A320neo {
    // ── Geometry ──────────────────────────────────────
    constexpr double kWingArea      = 122.6;    // m²
    constexpr double kMAC           =   4.194;  // m
    constexpr double kWingspan      =  35.80;   // m (A320neo has sharklets)
    constexpr double kAspectRatio   =  10.45;   // b²/S (neo value)

    // ── Mass Limits ───────────────────────────────────
    constexpr double kMTOW          = 79000.0;  // kg
    constexpr double kMLW           = 67400.0;  // kg
    constexpr double kMZFW          = 64300.0;  // kg
    constexpr double kOEW           = 44300.0;  // kg (typical)
    constexpr double kMaxFuel       = 24210.0;  // kg (USG * density)
    constexpr double kMaxPayload    = 20000.0;  // kg

    // ── Speed Limits ──────────────────────────────────
    constexpr double kVMO           = 350.0;    // kt CAS
    constexpr double kMMO           =   0.82;   // Mach
    constexpr double kMaxAltitude   = 39800.0;  // ft (service ceiling)

    // ── Engine: CFM LEAP-1A ───────────────────────────
    constexpr double kThrustMaxTOGA = 132000.0; // N per engine (LEAP-1A26)
    constexpr double kThrustMaxMCT  = 118000.0; // N per engine
    constexpr double kN1MaxTOGA     =  96.0;    // %
    constexpr double kN1MaxMCT      =  92.5;    // %
    constexpr double kN1MaxClimb    =  90.0;    // %
    constexpr double kN1Idle        =  19.5;    // %
    constexpr double kN1SpoolTime   =   4.0;    // seconds (idle to TOGA)
    constexpr double kEGTMaxTOGA    = 1083.0;   // °C (LEAP-1A limit)
    constexpr double kEGTMaxMCT     = 1043.0;   // °C
    constexpr double kSFC           =  0.0463;  // kg/(N·hr) (LEAP-1A typical)

    // ── Moments of Inertia ────────────────────────────
    constexpr double kIxx           =  8.4e6;   // kg·m²
    constexpr double kIyy           = 25.0e6;   // kg·m²
    constexpr double kIzz           = 32.0e6;   // kg·m²
    constexpr double kIxz           =  0.5e6;   // kg·m²

    // ── Flap/Slat Schedule ────────────────────────────
    //  Config  Flap°  Slat°   VFE(kt)
    //  0       0      0       350/M0.82
    //  1       0      18      230
    //  1+F     10     18      215
    //  2       15     22      200
    //  3       20     22      185
    //  FULL    35     27      177
}
```

> [!WARNING]
> Current code has `kTmax = 120000 N` labeled "CFM56-5B". The A320neo uses LEAP-1A at 132 kN. This must be corrected.

---

## 3. 6-DOF Equations of Motion

### Translational (Body Frame)

```
u̇ = (Fx / m) + rv − qw − g·sin(θ)
v̇ = (Fy / m) + pw − ru + g·sin(φ)·cos(θ)
ẇ = (Fz / m) + qu − pv + g·cos(φ)·cos(θ)
```

### Rotational (Body Frame)

```
ṗ = (Izz·L + Ixz·N − (Izz·(Izz−Iyy) + Ixz²)·qr + Ixz·(Ixx−Iyy+Izz)·pq) / (Ixx·Izz − Ixz²)
q̇ = (M − (Ixx−Izz)·pr − Ixz·(p²−r²)) / Iyy
ṙ = (Ixz·L + Ixx·N + (Ixx·(Ixx−Iyy) + Ixz²)·pq − Ixz·(Ixx−Iyy+Izz)·qr) / (Ixx·Izz − Ixz²)
```

### Euler Angle Kinematics

```
φ̇ = p + (q·sin(φ) + r·cos(φ))·tan(θ)
θ̇ = q·cos(φ) − r·sin(φ)
ψ̇ = (q·sin(φ) + r·cos(φ)) / cos(θ)
```

### Position Integration (WGS-84)

```
laṫ = (u·cos(ψ)·cos(θ) + ...) / R_earth
loṅ = (u·sin(ψ)·cos(θ) + ...) / (R_earth · cos(lat))
ḣ   = −ẇ_earth = u·sin(θ) − v·sin(φ)·cos(θ) − w·cos(φ)·cos(θ)
```

> Current implementation: ✅ Present in `AirDataComputer::integrateEOM()` with 8 sub-steps.

---

## 4. Engine Model (LEAP-1A) — NEW

```cpp
class EngineModel {
    // State per engine
    double m_n1;              // % N1 (fan speed)
    double m_n2;              // % N2 (core speed)
    double m_egt;             // °C exhaust gas temperature
    double m_ff;              // kg/hr fuel flow
    double m_oilPressure;     // psi
    double m_oilTemperature;  // °C
    double m_vibN1;           // mils vibration
    double m_vibN2;           // mils vibration

    // Inputs
    double m_thrustLeverAngle; // 0.0 (idle) to 1.0 (TOGA)
    bool   m_started;
    bool   m_fuelValveOpen;

    // Computed
    double m_thrustN;          // Newtons output
    double m_bleedFlow;        // kg/s

    // Detent positions
    enum Detent { IDLE, CL, MCT, FLX, TOGA };
    Detent currentDetent() const;

    void tick(double dt, double altM, double mach, double oat);
};
```

### Thrust Model

```
T = T_max_SL × σ(alt) × f(Mach) × g(N1)

where:
  σ(alt) = (ρ / ρ₀)^0.7          lapse rate
  f(M)   = 1 − 0.3 × M²          ram drag correction
  g(N1)  = (N1/N1_max)²           quadratic thrust-N1 relation
```

### N1 Spool Dynamics

```
N1̇ = (N1_target − N1) / τ

where:
  τ = 1.0s  (accel, high N1)
  τ = 4.0s  (accel from idle)
  τ = 2.0s  (decel)
```

---

## 5. Ground Model — NEW (Currently Missing)

```cpp
class GroundModel {
    bool   m_onGround;
    bool   m_weightOnWheels;
    double m_noseGearCompression;  // 0-1
    double m_mainGearCompression;  // 0-1

    // Tire/runway friction
    double m_mu;                    // friction coefficient
    double m_runwayHeading;         // deg
    double m_crosswindComponent;    // kt

    // Braking
    double m_brakePressure;         // 0-1 (pilot)
    int    m_autobrakeMode;         // 0=OFF, 1=LO, 2=MED, 3=MAX
    double m_autobrakeDecel;        // m/s² target

    // Nosewheel steering
    double m_nosewheelAngle;        // deg (-75 to +75 via tiller)
    double m_rudderSteerAngle;      // deg (limited ±6° via pedals)

    void tick(double dt, AircraftState& state);
};
```

### Ground Forces

```
Normal force:  N = m·g − L  (when on ground)
Friction:      F_friction = μ · N
Braking:       F_brake = μ_brake · N × brakePressure
Steering:      Yaw torque = f(nosewheelAngle, groundSpeed)
```

### Runway Surface Types

| Surface | μ_dry | μ_wet | μ_icy |
|---------|-------|-------|-------|
| Concrete | 0.5 | 0.3 | 0.1 |
| Asphalt | 0.5 | 0.3 | 0.1 |
| Grass | 0.4 | 0.2 | — |

---

## 6. Control Surfaces Architecture — NEW

```cpp
struct ControlSurfaces {
    // Primary (driven by ELAC/SEC via FBW)
    double elevatorLeft;      // deg (-30 to +17)
    double elevatorRight;     // deg
    double aileronLeft;       // deg (-25 to +25)
    double aileronRight;      // deg
    double rudder;            // deg (-30 to +30)

    // Secondary
    double spoiler[5];        // per side (1-5), deg (0 to 50)
    double speedBrakeHandle;  // 0 (retract) to 1 (full)
    bool   groundSpoilersArmed;
    bool   groundSpoilersDeployed;

    // High-lift
    int    flapConfig;        // 0, 1, 1+F, 2, 3, FULL
    double flapAngle;         // actual deflection deg
    double slatAngle;         // actual deflection deg
    double flapTransitTime;   // seconds remaining

    // Landing gear
    bool   gearDown;
    double gearPosition;      // 0=up, 1=down (transit animation)
    bool   gearLocked;
};
```
