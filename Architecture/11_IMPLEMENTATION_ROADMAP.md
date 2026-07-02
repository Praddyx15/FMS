# 11 — Implementation Roadmap

## Priority Implementation Phases

### Phase 1: Foundation Refactoring (Weeks 1-4)
**Goal**: Decompose monolith, fix tech debt, establish module boundaries

| Task | Current File | Action | Priority |
|------|-------------|--------|----------|
| Split `AirDataComputer` | `AirDataComputer.hpp/cpp` | Extract → `AutopilotController`, `EngineModel`, `FlightControlLaws` | 🔴 P0 |
| Upgrade C++ standard | `CMakeLists.txt` | Change C++17 → C++20 | 🟡 P1 |
| Fix engine constants | `AirDataComputer.hpp:452` | `kTmax` 120000→132000 (LEAP-1A) | 🔴 P0 |
| Remove legacy paths | `main.cpp:51-66` | Remove `c:/Users/akass/` hardcodes | 🟡 P1 |
| Create unit type system | NEW `Core/Units.hpp` | Type-safe `Feet`, `Knots`, `Radians` | 🟡 P1 |
| Create `FlightDataBus` | From `FlightDataManager` | Restructure into channels | 🔴 P0 |
| Linux build path | `CMakeLists.txt` | Add Linux deployment alongside Windows | 🟡 P1 |
| Test framework | `Backend/tests/` | Set up Catch2/GoogleTest, write ISA+Haversine tests | 🟡 P1 |

### Phase 2: Aircraft Systems (Weeks 5-10)
**Goal**: Every switch drives real state

| Task | Priority |
|------|----------|
| Implement `SystemsManager` — hydraulic (3 systems, pressure, pump logic) | 🔴 P0 |
| Implement `SystemsManager` — electrical (2 GEN, APU GEN, buses, TR) | 🔴 P0 |
| Implement `SystemsManager` — fuel (5 tanks, crossfeed, fuel flow) | 🔴 P0 |
| Implement `SystemsManager` — pneumatic (engine bleed, APU bleed, packs) | 🟡 P1 |
| Implement `SystemsManager` — pressurization (cabin alt, outflow valve) | 🟡 P1 |
| Implement `SystemsManager` — fire protection | 🟡 P1 |
| Implement ADIRS — alignment sequence, degraded modes | 🔴 P0 |
| Wire Overhead Panel QML → `SystemsManager` (every switch functional) | 🔴 P0 |
| Wire ECAM pages to `SystemsManager` (live data, not mock) | 🔴 P0 |

### Phase 3: Engine & Ground Model (Weeks 7-12)
**Goal**: Complete flight envelope — takeoff to landing

| Task | Priority |
|------|----------|
| Implement `EngineModel` — LEAP-1A N1/N2/EGT/FF dynamics | 🔴 P0 |
| Implement throttle detent logic (IDLE/CL/MCT/FLX/TOGA) | 🔴 P0 |
| Implement `GroundModel` — weight-on-wheels, gear compression | 🔴 P0 |
| Ground friction model (braking, nosewheel steering) | 🔴 P0 |
| Autobrake system (LO/MED/MAX, decel rate targeting) | 🟡 P1 |
| Ground spoiler deployment logic | 🟡 P1 |
| Reverse thrust model | 🟡 P1 |
| Crosswind effects on ground | 🟡 P1 |
| Landing gear transit animation | 🟢 P2 |

### Phase 4: FMS & Navigation (Weeks 10-16)
**Goal**: Full ARINC 702A-conceptual flight management

| Task | Priority |
|------|----------|
| Implement `FlightPlanManager` — active/secondary/temporary plans | 🔴 P0 |
| SID selection → active plan insertion | 🔴 P0 |
| STAR selection → active plan insertion | 🔴 P0 |
| Approach selection (ILS/RNAV/VOR/NDB) | 🔴 P0 |
| Airway-based route building | 🟡 P1 |
| Speed/altitude constraints on flight plan legs | 🔴 P0 |
| TOC/TOD computation | 🔴 P0 |
| `PerformanceManager` — V-speeds (weight/config dependent) | 🔴 P0 |
| `PerformanceManager` — fuel predictions (EFOB per waypoint) | 🟡 P1 |
| `PredictionEngine` — ETA, distance-to-go per waypoint | 🟡 P1 |
| VNAV profile (managed descent) | 🟡 P1 |
| AIRAC cycle management | 🟢 P2 |
| HOLD page implementation | 🟢 P2 |
| OFFSET page implementation | 🟢 P2 |

### Phase 5: Autopilot & FBW (Weeks 12-18)
**Goal**: Full AP/FD mode logic with flight control laws

| Task | Priority |
|------|----------|
| Implement full AP lateral modes (HDG, TRK, NAV, LOC, RWY) | 🔴 P0 |
| Implement full AP vertical modes (CLB, DES, ALT*, OP CLB/DES, VS, FPA, GS) | 🔴 P0 |
| Implement A/THR modes (SPEED, MACH, THR CLB, THR IDLE, A.FLOOR) | 🔴 P0 |
| Mode transition logic (arm → capture → engage) | 🔴 P0 |
| EXPEDITE mode | 🟡 P1 |
| SRS mode (initial climb) | 🟡 P1 |
| Go-around mode (GA TRK + SRS) | 🟡 P1 |
| Normal Law pitch/roll (C* law, bank angle protection) | 🟡 P1 |
| Alternate Law / Direct Law degradation | 🟢 P2 |
| Alpha floor protection | 🟡 P1 |
| FMA 5-column display update | 🔴 P0 |

### Phase 6: Training Framework (Weeks 16-22)
**Goal**: All 12 training modes functional

| Task | Priority |
|------|----------|
| Implement `TrainingModeFramework` — mode config, state machine | 🔴 P0 |
| Mode 3 (MCDU Training) — guided exercises with step validation | 🔴 P0 |
| Mode 6 (Normal Procedures) — SOP checklist + auto-grading | 🔴 P0 |
| Mode 7/8 (Abnormal/Emergency) — failure + QRH workflow | 🟡 P1 |
| Mode 10 (Instrument Procedures) — approach training | 🟡 P1 |
| Mode 12 (Instructor Led) — full instructor control | 🔴 P0 |
| Implement `RecordingEngine` — state snapshots + events | 🟡 P1 |
| Implement `AssessmentEngine` — scoring + deviations | 🟡 P1 |
| Implement replay system | 🟢 P2 |
| Mode 1/2 (Familiarization) — interactive tour | 🟢 P2 |
| Mode 11 (Type Rating) — full exam framework | 🟢 P2 |

### Phase 7: Failure Engine (Weeks 18-22)
**Goal**: Airline-grade failure management

| Task | Priority |
|------|----------|
| Implement `FailureEngine` — activation, progression, cascading | 🔴 P0 |
| Engine failure catalogue (6 failure types) | 🔴 P0 |
| Hydraulic failure catalogue (5 types) | 🟡 P1 |
| Electrical failure catalogue (5 types) | 🟡 P1 |
| Flight control failure catalogue (6 types) | 🟡 P1 |
| Sensor/ADIRS failure catalogue (6 types) | 🟡 P1 |
| Pressurization failure catalogue (4 types) | 🟡 P1 |
| Random failure mode (probability-based) | 🟢 P2 |
| Conditional failure triggers | 🟢 P2 |
| ECAM warning/caution integration | 🔴 P0 |

### Phase 8: Instructor Station & Analytics (Weeks 20-24)
**Goal**: Production-grade instructor tools

| Task | Priority |
|------|----------|
| `InstructorStationEngine` — scenario CRUD | 🔴 P0 |
| Position/weather/traffic control | 🟡 P1 |
| Real-time student monitoring dashboard | 🟡 P1 |
| Session debrief with recorded data | 🟡 P1 |
| Analytics computation (flight path, fuel, stability) | 🟡 P1 |
| Student progress tracking over time | 🟢 P2 |
| PDF report generation | 🟢 P2 |

### Phase 9: Multi-User & Enterprise (Weeks 24-30)
**Goal**: Network-ready multi-user deployment

| Task | Priority |
|------|----------|
| WebSocket infrastructure | 🟢 P2 |
| Instructor-student state sync | 🟢 P2 |
| Observer mode (read-only) | 🟢 P2 |
| Supabase schema upgrade (organizations, fleet, AIRAC) | 🟡 P1 |
| API layer for external integrations | 🟢 P2 |
| Certificate generation | 🟢 P2 |

### Phase 10: Display Fidelity (Weeks 22-28)
**Goal**: Airline-grade visual accuracy

| Task | Priority |
|------|----------|
| PFD — 5-column FMA with correct colors | 🔴 P0 |
| PFD — speed tape color bands (VLS, αprot, αmax, VMO) | 🔴 P0 |
| PFD — cyan altitude target | 🟡 P1 |
| PFD — radio altimeter indication | 🟡 P1 |
| ND — CSTR overlay (constraints display) | 🟡 P1 |
| ND — TOC/TOD pseudo-waypoints | 🟡 P1 |
| Canvas → QQuickPaintedItem migration (30 Hz target) | 🟢 P2 |

---

## Summary Timeline

```
Weeks 1-4:   ████ Foundation Refactoring
Weeks 5-10:  ██████ Aircraft Systems
Weeks 7-12:      ██████ Engine & Ground Model
Weeks 10-16:       ███████ FMS & Navigation
Weeks 12-18:         ███████ Autopilot & FBW
Weeks 16-22:            ███████ Training Framework
Weeks 18-22:              █████ Failure Engine
Weeks 20-24:                █████ Instructor & Analytics
Weeks 22-28:                  ███████ Display Fidelity
Weeks 24-30:                    ███████ Multi-User & Enterprise
```

**Total estimated: ~30 weeks for full airline-grade implementation**
