# A320neo FMS-Trainer — Architecture Analysis

> **Documents Analysed**: 13 files in `Architecture/` | **Total**: ~105 KB of specifications
> **Aircraft**: Airbus A320neo CFM LEAP-1A | **Stack**: C++20 / Qt 6 / QML / Supabase

---

## Executive Summary

The FMS-Trainer architecture package defines a **complete, airline-grade transformation** of an existing Qt/C++ prototype into a DO-178C-aware, ARINC 702A-conceptual A320neo Flight Management System and Procedures Trainer. The 13 documents are internally consistent and form a coherent blueprint. However, they make clear that the project is currently only ~30% complete: the backend requires ~70% new work and the frontend ~40%. The estimated delivery timeline is **30 weeks** across 10 overlapping phases.

---

## Document-by-Document Breakdown

### `00_MASTER_INDEX.md` — Master Index
- Serves as the top-level table of contents for all 12 deliverable architecture documents
- Inventories the existing codebase: **5 C++ modules**, **47 QML files** (across 5 domains), **26 Supabase tables**
- Establishes the design philosophy mantra: **Aircraft First → Systems Second → Training Third → UI Fourth**
- All 12 deliverables are marked ✅ complete (i.e., the architecture docs themselves are finished)

---

### `01_GAP_ANALYSIS.md` — Forensic Gap Analysis
The most critical document. Provides a line-by-line audit of what exists vs. what is required across 9 domains.

| Domain | Completeness | Key Gaps |
|--------|-------------|----------|
| Aircraft State Model | ~65% | No pressure alt, no radio alt, fixed mass, no CG |
| Flight Physics (6-DOF) | ~55% | No spoilers, no ground model, no per-config aero |
| FMS (ARINC 702A) | ~30% | No VNAV, no SID/STAR runtime, no performance engine |
| Navigation DB | ~50% | SID/STAR/approaches not loaded at runtime |
| Avionics Systems | ~15% | FAC, ELAC, SEC all missing; ADIRS decorative |
| Autopilot/A-THR | ~35% | NAV, CLB, DES, GS, FPA all missing |
| Cockpit Displays | ~60% | FMA not 5-column, OHP is a 3-toggle stub |
| Training Architecture | ~5% | All 12 training modes missing |
| Supabase Schema | ~65% | No orgs, no AIRAC, no recording tables |

**Technical Debt Highlights:**
- Engine thrust constant is wrong: `kTmax = 120000 N` labelled "CFM56-5B" — should be LEAP-1A at **132,000 N**
- Hardcoded `C:\Users\akass\` Windows paths in `main.cpp`
- C++ standard mismatch: CMakeLists says C++17, docs say C++20
- `AirDataComputer` violates SRP — acts as physics engine, autopilot, FBW, and engine computer simultaneously
- Canvas-based displays leak memory; render rate capped at 12.5 Hz to avoid OOM

---

### `02_SYSTEM_ARCHITECTURE.md` — System Architecture Overview
Defines the layered module decomposition and data flow:

```
Aircraft State Engine → Systems Simulation → Training Framework → UI Presentation
```

**Key design decisions:**
- **Strict unidirectional data flow**: UI reads from `FlightDataBus` only; never computes flight state
- **Module decomposition**: The monolithic `AirDataComputer` is split into 6+ modules; `FlightDataManager` into 3; `FMSComputer` into 4; `InstructorEngine` into 4
- **4-thread architecture**: Main/QML thread (UI), Simulation thread (80ms/12.5 Hz), Navigation thread (1 Hz), Recording thread (configurable)
- **Channel-based DataBus**: `AircraftState`, `AvionicsState`, `SystemsState`, `TrainingState` — mutex-protected, Qt signal/slot bridge to QML
- **Build target**: CMake with 8 sub-libraries (`Core`, `Aircraft`, `Avionics`, `Navigation`, `Training`, `DataBus`, `Frontend`, `Tests`)

---

### `03_AIRCRAFT_STATE_MODEL.md` — Aircraft State & Flight Dynamics
The most physics-dense document. Defines the complete `AircraftState` struct (74 fields covering position, velocity, attitude, rates, aerodynamics, accelerations, wind, atmosphere, weight, and fuel).

**A320neo / LEAP-1A Constants defined:**
- MTOW: 79,000 kg | MLW: 67,400 kg | MZFW: 64,300 kg
- Wing area: 122.6 m² | Span: 35.80 m (with sharklets) | AR: 10.45
- VMO: 350 kt | MMO: 0.82 | Service ceiling: 39,800 ft
- TOGA thrust: **132,000 N/engine** (corrected from wrong CFM56 value)
- N1 spool time: 4s (idle → TOGA)
- SFC: 0.0463 kg/(N·hr)

**New components to implement:**
1. **EngineModel** — N1/N2/EGT/fuel flow with spool dynamics (`τ = 1–4s`), detents (IDLE/CL/MCT/FLX/TOGA), thrust = `T_max × σ(alt) × f(Mach) × g(N1)`
2. **GroundModel** — weight-on-wheels, gear compression, braking (`μ` table per surface), nosewheel steering (±75° tiller, ±6° rudder), autobrake modes (LO/MED/MAX)
3. **ControlSurfaces struct** — elevators, ailerons, rudder, 5 spoilers per side, speed brakes, flap/slat schedule (configs 0, 1, 1+F, 2, 3, FULL)

> [!WARNING]
> The 6-DOF EOM integration (8 sub-steps, Euler kinematics, WGS-84 position) is already implemented in `AirDataComputer::integrateEOM()` and is one of the project's strong foundations.

---

### `04_FMS_NAV_ARCHITECTURE.md` — FMS & Navigation Architecture
Defines the full ARINC 702A-conceptual FMS, covering route management, performance, and navigation database.

**Key structures:**
- **Dual FMGC model**: FMGC-1 (Master) ↔ FMGC-2 (Slave) crosslink; currently single FMS only
- **FlightPlanManager**: Three concurrent plans (active, secondary, temporary); each leg carries speed/altitude constraints with `A/B/C` type codes
- **ProcedureManager**: SID/STAR/Approach querying by runway; `ApproachProcedure` includes CAT I/II/IIIA/B/C, DA, RVR, GPA, FAC
- **PerformanceManager**: Computes V-speeds (VLS, Green Dot, F/S speeds, Vapp) and phase performance (TO/CLB/CRZ/DES/APP)
- **PredictionEngine**: TOC/TOD computation, per-waypoint ETA/EFOB, 1 Hz update cycle
- **NavigationDatabase**: Airports, navaids, waypoints, airways, SIDs, STARs, approaches, holdings — all with AIRAC cycle metadata

**MCDU page gaps:** 3 pages missing (HOLD, OFFSET, FIX INFO); 8 existing pages need backend computation wiring.

---

### `05_AVIONICS_AUTOPILOT.md` — Avionics & Autopilot Architecture
Defines the full A320neo computer suite and AP/FD/A-THR state machines.

**Computer inventory vs. current state:**

| Computer | Qty | Status |
|----------|-----|--------|
| FMGC | 2 | 1 partial |
| FAC | 2 | ❌ Missing |
| ELAC | 2 | ❌ Missing |
| SEC | 3 | ❌ Missing |
| ADIRS | 3 | Flags only |
| EGPWS | 1 | ❌ Missing |
| TCAS | 1 | Overlay only |

**ADIRS alignment sequence**: OFF → ALIGN (0-600s) → NAV; ADR data at ~90s, full NAV at ~600s; ATT-only degraded mode.

**AP/FD mode state machine** (full set defined):
- Lateral: NONE, HDG, TRK, **NAV**, LOC, ROLLOUT, GA_TRK, RWY, RWY_TRK
- Vertical: NONE, ALT, ALT_STAR, ALT_CRZ, ALT_CST, **CLB**, **DES**, OP_CLB, OP_DES, **VS**, FPA, **GS**, GS_STAR, FINAL, FLARE, **SRS**, TCAS, EXPEDITE
- A/THR: NONE, SPEED, MACH, THR_CLB, THR_MCT, THR_IDLE, THR_LVR, **A_FLOOR**, TOGA_LK, RETARD

**FBW laws**: Normal Law (C\* pitch, roll rate, auto-coordination), Alternate Law (no protections), Direct Law (stick-to-surface).

**Throttle detents**: IDLE (0°) → CL (25°) → MCT (35°) → FLX/MCT (35°) → TOGA (45°) → REV (-20°)

---

### `06_COCKPIT_DISPLAYS_UI.md` — Cockpit Displays & UI Architecture
Complete specification for all cockpit display elements.

**PFD requirements:**
- 5-column FMA (currently basic/non-standard)
- Speed tape with 9 color bands (VFE, VMO, VLS, αprot, αmax, Green Dot, F, S, V1/VR/V2)
- Cyan altitude target box (missing)
- Radio altimeter indication (missing)

**ND (all 5 modes exist)**: Missing CSTR and ARPT overlays; TOC/TOD pseudo-waypoints not displayed.

**ECAM**: 12 system pages exist but render static mock data — all must be wired to `SystemsManager`.

**Overhead Panel**: Currently a 3-toggle stub. Full specification covers ADIRS, Electrical (GEN1/2, APU, BAT, Bus Tie), Hydraulic, Fuel (5 tanks + crossfeed), Pneumatic/Bleed, Air Conditioning, Pressurization, Fire Protection, APU, Anti-Ice, Signs, Lighting. **Every switch must drive actual aircraft state.**

**UI principles**: QML reads `Q_PROPERTY` only; Canvas throttled (PFD 12.5 Hz, ND 10 Hz); future migration path Canvas → QQuickPaintedItem → Scene Graph for 30+ Hz.

---

### `07_TRAINING_INSTRUCTOR.md` — Training & Instructor Architecture
Defines the 12 training modes, instructor station, recording/replay system, and assessment engine.

**12 Training Modes:**

| # | Mode | Sim | MCDU | Grading |
|---|------|-----|------|---------|
| 1 | Aircraft Familiarization | ❌ | View | ❌ |
| 2 | Cockpit Familiarization | ❌ | View | ❌ |
| 3 | MCDU Training | ❌ | ✅ | ✅ |
| 4 | FMS Procedures | Partial | ✅ | ✅ |
| 5 | Flight Planning | Partial | ✅ | ✅ |
| 6 | Normal Procedures | ✅ | ✅ | ✅ |
| 7 | Abnormal Procedures | ✅ | ✅ | ✅ |
| 8 | Emergency Procedures | ✅ | ✅ | ✅ |
| 9 | Systems Training | ❌ | View | ✅ |
| 10 | Instrument Procedures | ✅ | ✅ | ✅ |
| 11 | Type Rating Prep | ✅ | ✅ | ✅ |
| 12 | Instructor-Led Session | ✅ | ✅ | ✅ |

**InstructorStationEngine capabilities**: Scenario CRUD, failure injection (manual/scheduled/conditional/random), position & state teleport, weather control (wind/vis/ceiling/OAT/turbulence/windshear), traffic management, session lifecycle.

**RecordingEngine**: 4 Hz state snapshots (`AircraftState + AvionicsState + SystemsState`), full event log (pilot inputs, MCDU keys, AP modes, failures, phase transitions), playback at 0.25×–8×.

**AssessmentEngine tolerances** (airline-grade):
- Altitude: ±100 ft | Speed: ±10 kt | Heading: ±5° | Cross-track: 2.5 NM
- Glideslope: ±0.5 dot | Localizer: ±0.5 dot | VSI at touchdown: ≤600 ft/min

**Multi-user architecture**: Instructor/Student/Observer roles via WebSocket; 4 Hz state sync, immediate command/event messages.

---

### `08_FAILURE_MANAGEMENT.md` — Failure Management Architecture
Defines the failure engine and a catalogue of **40+ A320-specific failures** across 7 categories.

**Failure engine features:**
- Progression types: IMMEDIATE, PROGRESSIVE, INTERMITTENT, LATENT
- Trigger types: MANUAL, SCHEDULED, CONDITIONAL, RANDOM
- Cascading logic (e.g., ENG1 flame-out → GEN1 off → Hyd Green decay → Pack 1 off → yaw tendency → ECAM "ENG 1 FAIL")

**Failure catalogue summary:**

| Category | Count | Examples |
|----------|-------|---------|
| Engine | 7 | Flame-out, Fire, Oil Low, Surge, Dual |
| Hydraulic | 5 | Green/Blue/Yellow low press/leak, Dual |
| Electrical | 5 | GEN1/2 fail, Dual GEN, Battery, TR |
| Flight Control | 6 | ELAC dual, SEC, FAC, Direct Law, Rudder Jam |
| Sensors/ADIRS | 6 | IR fail, ADR fail, Pitot block (single/dual), Static |
| Navigation | 6 | GPS, ILS, VOR, DME, FMS1, Dual FMS |
| Pressurization | 4 | Excess cab alt, Outflow valve, Dual pack, Rapid depress |

---

### `09_SUPABASE_SCHEMA.md` — Supabase Schema
Defines **10 new tables** to add to the existing 26, expanding to **36 tables total**.

New schema additions:
- **`organizations`** — Multi-tenant support (airline, ATO, university, OEM)
- **`user_organizations`** — Membership/role mapping
- **`fleet_aircraft`** — Per-org aircraft with registration, tail number, engine variant
- **`airac_cycles`** — AIRAC cycle management (effective/expiry dates, checksum, `is_current`/`is_next` flags)
- **`failure_definitions`** — Persistent failure catalogue with ECAM messages, expected actions, memory item flag
- **`session_recordings`** — Recording metadata (rate, snapshot count, duration, file path)
- **`session_events`** — Per-session event log (timestamp, type, JSONB data)
- **`assessments`** — Graded results with per-category scores, deviations, feedback
- **`certificates`** — Issued certificates (module_completion, type_rating_prep, line_check, etc.)
- Schema alterations to existing `users`, `training_sessions`, and all nav tables for AIRAC linking

---

### `10_DATA_FLOW_API.md` — Data Flow & API Architecture
Defines all internal C++↔QML data flows and external API surfaces using Mermaid sequence diagrams.

**Internal flows covered:**
1. **Simulation → QML**: `AircraftStateEngine → FlightDataBus → Q_PROPERTY → QML displays`
2. **MCDU workflow**: Pilot keystroke → FMGC scratchpad → LSK handler → NavDB lookup → FlightPlanManager → bus → ND/MCDU update
3. **Failure injection**: Instructor → InstructorStationEngine → FailureEngine → AircraftStateEngine + SystemsManager → bus → ECAM
4. **Recording**: 4 Hz sim snapshots → RecordingEngine buffer → Supabase upload on session end

**External REST API** (future): 30+ endpoints covering Auth, Users, Orgs, Training Sessions, Scenarios, Navigation (airport/procedure/AIRAC queries), Analytics

**WebSocket** (multi-user): `/sim/{sessionId}` channel with state.update (4 Hz), event messages, failure injection, session control

**ARINC 429 conceptual mapping**: Documents how DataBus properties map to real ARINC 429 labels (e.g., Label 012 → `bus.aircraft.velocity.ias`)

---

### `11_IMPLEMENTATION_ROADMAP.md` — Implementation Roadmap
Defines **10 development phases** with task-level prioritization (🔴P0 / 🟡P1 / 🟢P2).

```
Phase 1  Weeks 1-4:   Foundation Refactoring (decompose monolith, fix tech debt)
Phase 2  Weeks 5-10:  Aircraft Systems (hydraulic, electrical, fuel, ADIRS, OHP)
Phase 3  Weeks 7-12:  Engine & Ground Model (LEAP-1A, taxi/takeoff/landing)
Phase 4  Weeks 10-16: FMS & Navigation (FlightPlanManager, SID/STAR, performance)
Phase 5  Weeks 12-18: Autopilot & FBW (full AP/FD mode set, A-THR, FBW laws)
Phase 6  Weeks 16-22: Training Framework (12 modes, recording, assessment)
Phase 7  Weeks 18-22: Failure Engine (40+ failures, ECAM integration)
Phase 8  Weeks 20-24: Instructor Station & Analytics
Phase 9  Weeks 24-30: Multi-User & Enterprise (WebSocket, org schema)
Phase 10 Weeks 22-28: Display Fidelity (5-col FMA, speed bands, 30 Hz target)
```

Phases 3-5 overlap intentionally. The critical path is: **Foundation → Aircraft Core → FMS → Autopilot**.

---

### `12_COMPLIANCE_READINESS.md` — Compliance & Certification Readiness
Maps the project against 14 aviation standards.

**Key standards:**
- **ARINC 424**: Parser exists; needs full record type coverage
- **ARINC 702A**: Partial → full route/perf/prediction architecture targeted
- **DO-178C**: Not certified, but certification-readiness patterns applied (traceability, determinism, no heap in sim loop, 80% test coverage target)
- **MISRA C++:2023** and **JSF AV C++**: Referenced; to be enforced via static analysis
- **FAA AC 120-45A**: Targeting **FTD Level 4** (primary) and **FTD Level 5** (stretch)
- **EASA CS-FSTD(A)**: Targeting **FTD Level 1-2** as design reference

**Safety-critical coding rules already documented:**
- No dynamic allocation in sim loop (use pre-allocated `std::array`)
- Division-by-zero guards (`safeDiv`)
- NaN/Inf guards (`safeSqrt`)
- Physical clamps on all state variables

**Certification checklist items completed (✅):** Modular architecture, data bus, thread safety, boundary validation, representative displays, FCU managed/selected logic, ARINC 424 parser, Supabase RLS.

**Not yet complete (❌):** Formal requirements spec, MISRA static analysis, >80% test coverage, full OHP functionality, ground handling, complete AP mode set, functional IOS, recording/replay.

---

## Cross-Cutting Observations

### Strengths
1. **Solid 6-DOF physics core** — `integrateEOM()` with 8 sub-steps is a real foundation
2. **Rich MCDU frontend** — 31 pages already exist (even if LSK bindings are incomplete)
3. **ND mode coverage** — all 5 ND modes (ROSE ILS/VOR/NAV, ARC, PLAN) implemented
4. **ARINC 424 parser** — ~4,383 waypoints loaded, CIFP-based
5. **Supabase schema** — 26-table schema with RLS policies is enterprise-ready
6. **Architecture documents are thorough** — every module has class-level C++ pseudocode and clear gap identification

### Critical Risks

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Monolithic `AirDataComputer` | 🔴 High | Phase 1 decomposition — highest priority |
| No ground model | 🔴 High | Phase 3 blocks all takeoff/landing training |
| No VNAV | 🔴 High | Blocks all FMS performance training |
| Wrong engine constants (CFM56 vs LEAP-1A) | 🔴 High | 1-line fix — must be done immediately |
| Hardcoded Windows paths | 🟡 Medium | Blocks Linux build |
| Canvas memory leaks | 🟡 Medium | OOM risk at 30+ Hz; migrate to Scene Graph |
| Zero unit-type safety | 🟡 Medium | `double` everywhere — feet/meters/radians confusion |
| Empty test suite | 🟡 Medium | `Backend/tests/` exists but empty |

### Architecture Consistency Issues
- **C++ Standard**: CMakeLists.txt says C++17; all architecture docs say C++20 → must align to C++20
- **Render rate**: 12.5 Hz is insufficient for training fidelity; 30+ Hz target requires Canvas → Scene Graph migration (Phase 10)
- **State coupling**: `AirDataComputer` doing SRP violations — decomposition must precede all other backend work

---

## Recommended Immediate Actions (Before Phase 1)

> [!IMPORTANT]
> These are zero-cost fixes that unblock all subsequent work:

1. **Fix engine thrust constant** (`AirDataComputer.hpp:452`): `kTmax = 120000 → 132000` and rename from CFM56-5B to LEAP-1A26
2. **Upgrade CMakeLists.txt**: `CMAKE_CXX_STANDARD 17 → 20`
3. **Remove hardcoded Windows paths** from `main.cpp:51-66`
4. **Add Linux deployment path** to CMakeLists.txt
5. **Create a skeleton test in `Backend/tests/`** (ISA atmosphere and Haversine distance tests are trivial and provide CI baseline)

---

## Implementation Complexity Assessment

| Phase | Effort | Dependency | Risk |
|-------|--------|-----------|------|
| 1 — Foundation Refactoring | Medium | None | Low |
| 2 — Aircraft Systems | High | Phase 1 | Medium |
| 3 — Engine & Ground | High | Phase 1 | Medium |
| 4 — FMS & Navigation | Very High | Phases 1, 2 | High |
| 5 — Autopilot & FBW | Very High | Phases 1, 3, 4 | High |
| 6 — Training Framework | High | Phases 2, 5 | Medium |
| 7 — Failure Engine | Medium | Phases 2, 6 | Low |
| 8 — Instructor & Analytics | Medium | Phase 6 | Low |
| 9 — Multi-User | Low-Medium | Phase 6 | Low |
| 10 — Display Fidelity | Medium | All phases | Medium |

**Total estimated effort: 30 weeks** (single developer, full-time) or ~15 weeks with 2 engineers splitting backend/frontend.

---

## Summary

The architecture is **well-designed, internally consistent, and technically sound**. The design philosophy (Aircraft First, UI Last) is correct for a training system of this fidelity. The primary challenge is not architectural — it is execution volume: approximately **70% of backend logic** needs to be built from scratch, and the monolithic `AirDataComputer` must be surgically decomposed before any new systems work can begin safely.

The most impactful single action is **Phase 1 decomposition** of `AirDataComputer`, which unblocks all 9 subsequent phases.
