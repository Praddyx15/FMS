# 13 — Missing Modules Report & Architecture Coverage Audit

> **Purpose**: Explicit audit of every prompt requirement against existing Architecture documents.
> Companion to `01_GAP_ANALYSIS.md` (which audits the codebase), this document audits the *architecture docs* themselves.

---

## 1. Architecture Document Coverage Matrix

### 1.1 Prompt Requirements → Document Mapping

| Requirement Area | Prompt Section | Architecture Doc | Coverage |
|-----------------|---------------|-----------------|---------|
| Primary design philosophy | §PHILOSOPHY | `00_MASTER_INDEX.md` | ✅ Full |
| Aircraft model (A320neo, fleet, variants) | §AIRCRAFT | `03_AIRCRAFT_STATE_MODEL.md` | ✅ Full |
| Flight dynamics state model (74 params) | §FLIGHT DYNAMICS | `03_AIRCRAFT_STATE_MODEL.md` | ✅ Full |
| 6-DOF physics (translational + rotational) | §FLIGHT PHYSICS | `03_AIRCRAFT_STATE_MODEL.md` §3 | ✅ Full |
| Aerodynamic forces (L/D/Y) | §FLIGHT PHYSICS | `03_AIRCRAFT_STATE_MODEL.md` | ✅ Full |
| Control surfaces (all 7 types) | §FLIGHT PHYSICS | `03_AIRCRAFT_STATE_MODEL.md` §6 | ✅ Full |
| Ground interaction model | §FLIGHT PHYSICS | `03_AIRCRAFT_STATE_MODEL.md` §5 | ✅ Full |
| FMS/ARINC 702A compliance | §FMS | `04_FMS_NAV_ARCHITECTURE.md` | ✅ Full |
| Route management (SID/STAR/approach) | §FMS | `04_FMS_NAV_ARCHITECTURE.md` §1-2 | ✅ Full |
| Three-plan management (active/sec/tmp) | §FMS | `04_FMS_NAV_ARCHITECTURE.md` §1.2 | ✅ Full |
| Performance management (all 5 phases) | §FMS | `04_FMS_NAV_ARCHITECTURE.md` §3.1 | ✅ Full |
| Fuel/time/distance predictions | §FMS | `04_FMS_NAV_ARCHITECTURE.md` §3.2 | ✅ Full |
| TOC/TOD/VNAV/LNAV | §FMS | `04_FMS_NAV_ARCHITECTURE.md` §3.2 | ✅ Full |
| Speed/altitude constraints | §FMS | `04_FMS_NAV_ARCHITECTURE.md` §1.2 | ✅ Full |
| Navigation DB / ARINC 424 | §NAVDB | `04_FMS_NAV_ARCHITECTURE.md` §4 | ✅ Full |
| AIRAC cycle management | §NAVDB | `04_FMS_NAV_ARCHITECTURE.md` §4.2 | ✅ Full |
| Holding procedures | §NAVDB | `04_FMS_NAV_ARCHITECTURE.md` §4.1 | ✅ Full |
| ADIRS (3 units) architecture | §AVIONICS | `05_AVIONICS_AUTOPILOT.md` §1.2 | ✅ Full |
| FMGC (dual) architecture | §AVIONICS | `05_AVIONICS_AUTOPILOT.md` §1.1 | ✅ Full |
| FAC architecture | §AVIONICS | `05_AVIONICS_AUTOPILOT.md` §1.1 | ⚠️ Listed, not detailed |
| ELAC architecture | §AVIONICS | `05_AVIONICS_AUTOPILOT.md` §3 | ✅ FBW laws defined |
| SEC architecture | §AVIONICS | `05_AVIONICS_AUTOPILOT.md` §1.1 | ⚠️ Listed, not detailed |
| FCU architecture | §AVIONICS | `05_AVIONICS_AUTOPILOT.md` §2 | ✅ Full |
| ECAM/DMC architecture | §AVIONICS | `06_COCKPIT_DISPLAYS_UI.md` §3 | ✅ Full |
| TCAS (TA/RA logic) | §AVIONICS | `05_AVIONICS_AUTOPILOT.md` §1.1 | ⚠️ Listed, logic not defined |
| EGPWS | §AVIONICS | `05_AVIONICS_AUTOPILOT.md` §1.1 | ⚠️ Listed only |
| Weather Radar (parametric) | §AVIONICS | `05_AVIONICS_AUTOPILOT.md` §1.1 | ⚠️ Listed, mock model |
| Transponder (Mode S) | §AVIONICS | `05_AVIONICS_AUTOPILOT.md` §1.1 | ⚠️ Listed only |
| **ADF** | §AVIONICS | — | ❌ **Not architected** |
| DME | §AVIONICS | `04_FMS_NAV_ARCHITECTURE.md` §4.1 | ⚠️ DB only, no tuning logic |
| VOR | §AVIONICS | `04_FMS_NAV_ARCHITECTURE.md` §4.1 | ⚠️ DB only, no tuning logic |
| ILS | §AVIONICS | `05_AVIONICS_AUTOPILOT.md` §2 | ✅ LOC/GS capture defined |
| **MLS** | §AVIONICS | — | ❌ **Not architected** |
| GPS/GNSS | §AVIONICS | `01_GAP_ANALYSIS.md` §2.5 | ⚠️ Gap only, no arch |
| AP lateral modes (all 9) | §AUTOPILOT | `05_AVIONICS_AUTOPILOT.md` §2.1 | ✅ Full enum |
| AP vertical modes (all 14) | §AUTOPILOT | `05_AVIONICS_AUTOPILOT.md` §2.1 | ✅ Full enum |
| A/THR modes (all 10) | §AUTOPILOT | `05_AVIONICS_AUTOPILOT.md` §2.1 | ✅ Full enum |
| Mode transition rules | §AUTOPILOT | `05_AVIONICS_AUTOPILOT.md` §2.2 | ✅ Key examples |
| FBW Normal / Alternate / Direct Law | §AUTOPILOT | `05_AVIONICS_AUTOPILOT.md` §3 | ✅ Full |
| PFD with 5-column FMA | §DISPLAYS | `06_COCKPIT_DISPLAYS_UI.md` §1 | ✅ Full |
| Speed tape color bands | §DISPLAYS | `06_COCKPIT_DISPLAYS_UI.md` §1 | ✅ Full |
| ND all 5 modes | §DISPLAYS | `06_COCKPIT_DISPLAYS_UI.md` §2 | ✅ Full |
| ND overlays (7 types) | §DISPLAYS | `06_COCKPIT_DISPLAYS_UI.md` §2 | ✅ Full |
| MCDU all major pages | §DISPLAYS | `04_FMS_NAV_ARCHITECTURE.md` §5 | ✅ Full |
| ECAM upper/lower + 12 pages | §DISPLAYS | `06_COCKPIT_DISPLAYS_UI.md` §3 | ✅ Full |
| Overhead panel (all 12 sections) | §OHP | `06_COCKPIT_DISPLAYS_UI.md` §4 | ✅ Full |
| **Throttle quadrant (dedicated arch)** | §THROTTLE | `05_AVIONICS_AUTOPILOT.md` §4 | ⚠️ Detents only, no standalone |
| Flap lever / Landing gear / Autobrake | §THROTTLE | `01_GAP_ANALYSIS.md` §2.7 | ⚠️ Gap only |
| Reverse thrust model | §THROTTLE | `11_IMPLEMENTATION_ROADMAP.md` | ⚠️ Task listed, not architected |
| Failure engine (types + progression) | §FAILURES | `08_FAILURE_MANAGEMENT.md` §1 | ✅ Full |
| Engine failure catalogue | §FAILURES | `08_FAILURE_MANAGEMENT.md` §2.1 | ✅ 7 failures |
| Hydraulic failure catalogue | §FAILURES | `08_FAILURE_MANAGEMENT.md` §2.2 | ✅ 5 failures |
| Electrical failure catalogue | §FAILURES | `08_FAILURE_MANAGEMENT.md` §2.3 | ✅ 5 failures |
| Flight control failure catalogue | §FAILURES | `08_FAILURE_MANAGEMENT.md` §2.4 | ✅ 6 failures |
| ADIRS/sensor failure catalogue | §FAILURES | `08_FAILURE_MANAGEMENT.md` §2.5 | ✅ 6 failures |
| Navigation failure catalogue | §FAILURES | `08_FAILURE_MANAGEMENT.md` §2.6 | ✅ 6 failures |
| Pressurization failure catalogue | §FAILURES | `08_FAILURE_MANAGEMENT.md` §2.7 | ✅ 4 failures |
| **Fire (cargo smoke / lav smoke)** | §FAILURES | — | ❌ **Not in catalogue** |
| **Landing gear failures** | §FAILURES | — | ❌ **Not in catalogue** |
| **Communication failures** | §FAILURES | — | ❌ **Not in catalogue** |
| Failure cascading logic | §FAILURES | `08_FAILURE_MANAGEMENT.md` §3 | ✅ Full |
| All 12 training modes | §TRAINING | `07_TRAINING_INSTRUCTOR.md` §1 | ✅ Full |
| Mode configuration (per mode) | §TRAINING | `07_TRAINING_INSTRUCTOR.md` §1.2 | ✅ Full |
| Instructor station full arch | §INSTRUCTOR | `07_TRAINING_INSTRUCTOR.md` §2 | ✅ Full |
| Scenario creation/editing | §INSTRUCTOR | `07_TRAINING_INSTRUCTOR.md` §2.2 | ✅ Full |
| Recording system | §RECORDING | `07_TRAINING_INSTRUCTOR.md` §3 | ✅ Full |
| Replay / debrief | §RECORDING | `07_TRAINING_INSTRUCTOR.md` §3.1 | ✅ Full |
| Analytics dashboard | §ANALYTICS | `07_TRAINING_INSTRUCTOR.md` §4.2 | ✅ Full |
| Assessment engine with tolerances | §ANALYTICS | `07_TRAINING_INSTRUCTOR.md` §4.1 | ✅ Full |
| Multi-user roles (Inst/Student/Obs) | §MULTIPLAYER | `07_TRAINING_INSTRUCTOR.md` §5 | ✅ Full |
| WebSocket network protocol | §MULTIPLAYER | `07_TRAINING_INSTRUCTOR.md` §5.3 | ✅ Full |
| Supabase organizations schema | §SUPABASE | `09_SUPABASE_SCHEMA.md` | ✅ Full |
| Supabase fleet/aircraft schema | §SUPABASE | `09_SUPABASE_SCHEMA.md` | ✅ Full |
| Supabase AIRAC schema | §SUPABASE | `09_SUPABASE_SCHEMA.md` | ✅ Full |
| Supabase failure definitions schema | §SUPABASE | `09_SUPABASE_SCHEMA.md` | ✅ Full |
| Supabase recording schema | §SUPABASE | `09_SUPABASE_SCHEMA.md` | ✅ Full |
| Supabase assessments/certs schema | §SUPABASE | `09_SUPABASE_SCHEMA.md` | ✅ Full |
| ARINC 424/702A compliance mapping | §COMPLIANCE | `12_COMPLIANCE_READINESS.md` | ✅ Full |
| DO-178C design patterns | §COMPLIANCE | `12_COMPLIANCE_READINESS.md` §2 | ✅ Full |
| FAA AC 120-45A / EASA CS-FSTD | §COMPLIANCE | `12_COMPLIANCE_READINESS.md` §5 | ✅ Full |
| MISRA/JSF AV C++ rules | §COMPLIANCE | `12_COMPLIANCE_READINESS.md` §2.2 | ✅ Full |
| FTD Level 4-5 target | §COMPLIANCE | `12_COMPLIANCE_READINESS.md` §5 | ✅ Full |
| System architecture overview | Deliverable 1 | `02_SYSTEM_ARCHITECTURE.md` | ✅ Full |
| Supabase schema (complete) | Deliverable 2 | `09_SUPABASE_SCHEMA.md` | ✅ Full |
| **Entity relationship diagrams (visual)** | Deliverable 3 | `09_SUPABASE_SCHEMA.md` (text) | ⚠️ Text only |
| Data flow diagrams | Deliverable 4 | `10_DATA_FLOW_API.md` | ✅ Full (Mermaid) |
| Aircraft state model | Deliverable 5 | `03_AIRCRAFT_STATE_MODEL.md` | ✅ Full |
| Instructor architecture | Deliverable 6 | `07_TRAINING_INSTRUCTOR.md` | ✅ Full |
| Training architecture | Deliverable 7 | `07_TRAINING_INSTRUCTOR.md` | ✅ Full |
| Avionics architecture | Deliverable 8 | `05_AVIONICS_AUTOPILOT.md` | ✅ Full |
| Failure architecture | Deliverable 9 | `08_FAILURE_MANAGEMENT.md` | ✅ Full |
| Navigation architecture | Deliverable 10 | `04_FMS_NAV_ARCHITECTURE.md` | ✅ Full |
| API architecture | Deliverable 11 | `10_DATA_FLOW_API.md` §5 | ✅ Full |
| **Communication architecture** | Deliverable 12 | `10_DATA_FLOW_API.md` §6 | ⚠️ Partial |
| Multi-user architecture | Deliverable 13 | `07_TRAINING_INSTRUCTOR.md` §5 | ✅ Full |
| Migration roadmap | Deliverable 14 | `12_COMPLIANCE_READINESS.md` §6 | ✅ Full |
| Gap analysis | Deliverable 15 | `01_GAP_ANALYSIS.md` | ✅ Full |
| **Missing modules report** | Deliverable 16 | — | ❌ **This document** |
| Priority implementation roadmap | Deliverable 17 | `11_IMPLEMENTATION_ROADMAP.md` | ✅ Full |
| **Technical debt report** | Deliverable 18 | `01_GAP_ANALYSIS.md` §3 (partial) | ⚠️ Needs dedicated doc |
| Certification-readiness report | Deliverable 19 | `12_COMPLIANCE_READINESS.md` | ✅ Full |
| **Airline-grade product arch doc** | Deliverable 20 | Distributed across all 12 docs | ⚠️ No single doc |

---

## 2. Missing Modules — Explicit Report

### 2.1 Architecture-Level Missing Modules (Not Architected)

These systems appear in the prompt requirements but have **no architecture definition** in any existing document:

#### ❌ ADF — Automatic Direction Finder

```
What it is:   Radio navigation sensor receiving NDB (Non-Directional Beacon) signals
A320 usage:   ADF 1 + ADF 2 receivers; bearing displayed on ND as pointer
Training use: NDB approaches (Mode 10), navigation exercises
```

**Missing architecture needs:**
- `ADFReceiver` class with frequency, bearing, RMI display output
- Integration with ND pointer (green pointer = ADF1, yellow = ADF2)
- Tuning via MCDU RAD NAV page
- Failure modes: ADF1/2 fail (no NDB display)
- NDB approach coupling (Mode 10 — Instrument Procedures)

#### ❌ MLS — Microwave Landing System

```
What it is:   Precision approach system alternative to ILS; uses microwave freq (5 GHz)
A320 usage:   Optional fitment; azimuth + elevation guidance like ILS
Training use: MLS approaches in Mode 10; future-proofing for non-ILS airports
```

**Missing architecture needs:**
- `MLSReceiver` class with azimuth/elevation deviation outputs
- AP coupling (similar to LOC/GS but MLS-specific)
- MCDU RAD NAV MLS frequency entry
- Failure modes

#### ❌ Fire Failure Catalogue (Cargo / Lavatory)

```
Missing IDs:
  FIRE_CARGO_FWD   → FWD cargo smoke detection
  FIRE_CARGO_AFT   → AFT cargo smoke detection  
  FIRE_LAVATORY    → Lavatory smoke detection
  FIRE_AVIONICS    → Avionics bay overheat
```

**Cascade effects:** ECAM "SMOKE FWD CARGO DET FAULT" → cargo isolation procedure → may require diversion.

#### ❌ Landing Gear Failure Catalogue

```
Missing IDs:
  GEAR_DOOR_UNSAFE      → Gear door not closed/open as commanded
  GEAR_ASYMMETRIC       → One gear down, others not
  GEAR_GRAVITY_EXT      → Normal extension failed, gravity extension required
  GEAR_LGCIU1_FAIL      → LGCIU 1 failure → LGCIU 2 takes over
  NOSEWHEEL_STEER_FAIL  → NWS inoperative
  GEAR_RETRACT_FAIL     → Gear fails to retract after takeoff
```

#### ❌ Communication Failure Catalogue

```
Missing IDs:
  COMM_VHF1_FAIL   → VHF 1 communication radio failure
  COMM_VHF2_FAIL   → VHF 2 communication radio failure
  COMM_ACARS_FAIL  → ACARS data link failure
  COMM_SELCAL_FAIL → SELCAL receiver failure
  COMM_HF1_FAIL    → HF radio failure (long-range)
```

### 2.2 Architecture-Level Thin Coverage (Defined but Under-Specified)

These systems are listed in the avionics inventory but have insufficient architecture definition:

#### ⚠️ FAC — Flight Augmentation Computer

**What exists:** Listed in computer inventory table (doc 05)
**What's missing:**
- `FAC` class definition with I/O
- Yaw damper law (sideslip damping)
- Rudder Travel Limiter (RTL) logic — speed-dependent rudder authority reduction
- Speed computation (Green Dot, S-speed, F-speed, VLS) — currently unassigned
- Low-energy warning ("SPEED SPEED SPEED")
- Low-energy protection logic

#### ⚠️ SEC — Spoiler Elevator Computer

**What exists:** Listed in computer inventory table (doc 05)
**What's missing:**
- `SEC` class definition with I/O
- Spoiler deflection logic (5 spoilers per side, differential)
- Speedbrake control (spoiler as speed brake)
- Ground spoiler deployment logic (weight-on-wheels + throttle + reverse)
- Pitch backup (SEC acts as elevator backup to ELAC in degraded mode)
- SEC failure cascade → reduced spoiler authority

#### ⚠️ TCAS — Traffic Collision Avoidance System

**What exists:** Listed as "Overlay only / TA/RA logic" gap (docs 01 & 05)
**What's missing:**
- `TCASComputer` class with TA/RA computation
- Threat detection algorithm (relative bearing, closure rate, separation)
- Resolution Advisory (RA) vertical guidance (CLIMB / DESCEND / MONITOR VS)
- FMA TCAS mode (when RA active, AP responds to TCAS command)
- ND traffic symbol types (open diamond = proximate, filled = TA, red = RA)

#### ⚠️ EGPWS — Enhanced Ground Proximity Warning System

**What exists:** Listed as "Missing" (docs 01 & 05)
**What's missing:**
- `EGPWSComputer` class with mode definitions
- Mode 1: Excessive descent rate ("SINK RATE")
- Mode 2: Excessive terrain closure ("TERRAIN TERRAIN")
- Mode 3: Altitude loss after takeoff
- Mode 4: Unsafe terrain clearance ("TOO LOW TERRAIN")
- Mode 5: Below glideslope ("GLIDESLOPE")
- Mode 6: Advisories ("BANK ANGLE", "MINIMUMS")
- Terrain database lookup (even simplified elevation grid)
- ND TERR overlay driven by EGPWS data

#### ⚠️ Throttle Quadrant — Standalone Architecture

**What exists:** Detents in doc 05 §4; autobrake gap in doc 01; reverse thrust as P1 roadmap task
**What's missing (dedicated architecture):**
- `ThrottleQuadrantModel` class with lever state
- Detent detection logic (TLA → detent enum)
- A/THR engagement/disengagement rules from lever position
- Speed brake lever with ARMED logic (auto-deployment on landing)
- Flap handle → `ControlSurfaces.flapConfig` mapping
- Landing gear lever (UP/OFF/DN) with LGCIU integration
- Autobrake selector (OFF/LO/MED/MAX) with decel targeting
- Parking brake toggle (physical + QML)
- Reverse thrust interlock (ground-only, thrust reverser doors)

#### ⚠️ GPS/GNSS — Position Solution Architecture

**What exists:** "Flag only / No position solution model" (doc 01)
**What's missing:**
- `GNSSReceiver` class with position, velocity, integrity outputs
- RAIM (Receiver Autonomous Integrity Monitoring) status
- RNP (Required Navigation Performance) computation
- Blending with IRS data for hybrid navigation
- GPS failure → position degrades to IRS+DME
- FMS navigation mode switching (GPS → IRS → DME-DME → VOR-DME)

### 2.3 Missing Architecture Documents

Three of the 20 prompt deliverables have no dedicated document:

| # | Deliverable | Action Required |
|---|-------------|----------------|
| 16 | **Missing Modules Report** | This document fulfills deliverable 16 |
| 18 | **Technical Debt Report** | Create `14_TECHNICAL_DEBT.md` |
| 20 | **Airline-Grade Product Architecture** | Create `15_PRODUCT_ARCHITECTURE.md` (executive summary) |
| 3 | **Entity Relationship Diagrams** | Add Mermaid ERD to `09_SUPABASE_SCHEMA.md` |
| 12 | **Communication Architecture** | Expand §6 of `10_DATA_FLOW_API.md` into dedicated section |

---

## 3. Module Implementation Priority (Adjusted for Missing Items)

### Priority 0 — Blocks Everything Else
These must be addressed before Phase 1 begins:

```
[P0-CRITICAL] Fix kTmax: 120000 → 132000 N (LEAP-1A26)      ← 1-line fix
[P0-CRITICAL] CMakeLists: C++17 → C++20                       ← 1-line fix
[P0-CRITICAL] Remove c:/Users/akass/ Windows paths             ← main.cpp cleanup
[P0-CRITICAL] Decompose AirDataComputer (SRP violation)        ← Phase 1 core task
[P0-CRITICAL] Create FlightDataBus to replace FlightDataManager← Phase 1 core task
```

### Priority 1 — Missing From Architecture Docs

```
[P1-ARCH] Write FAC class architecture (yaw damper, RTL, speed computations)
[P1-ARCH] Write SEC class architecture (spoiler + speedbrake + pitch backup)
[P1-ARCH] Write TCAS TA/RA computation architecture
[P1-ARCH] Write EGPWS Mode 1-6 architecture
[P1-ARCH] Write ThrottleQuadrantModel architecture
[P1-ARCH] Write GNSSReceiver + RNP computation architecture
[P1-ARCH] Write ADF receiver architecture
[P1-ARCH] Add Landing Gear, Fire (cargo), and Communication failure catalogues
```

### Priority 2 — Missing Documents

```
[P2-DOC] Create 14_TECHNICAL_DEBT.md
[P2-DOC] Create 15_PRODUCT_ARCHITECTURE.md (single airline-grade product summary)
[P2-DOC] Add Mermaid ERD diagrams to 09_SUPABASE_SCHEMA.md
[P2-DOC] Expand communication architecture in 10_DATA_FLOW_API.md
```

---

## 4. Coverage Score Summary

| Category | Coverage | Score |
|----------|----------|-------|
| Design philosophy | All aspects covered | 100% |
| Aircraft model (state + physics + engine) | Fully architected | 100% |
| FMS / ARINC 702A | Fully architected | 100% |
| Navigation database / ARINC 424 | Fully architected | 100% |
| Avionics (core: ADIRS, FMGC, FCU) | Fully architected | 100% |
| Avionics (secondary: FAC, SEC, TCAS, EGPWS) | Listed, under-specified | 40% |
| Avionics (ADF, MLS) | Not architected | 0% |
| Autopilot (all modes + FBW laws) | Fully architected | 100% |
| Throttle quadrant | Detents only | 50% |
| Cockpit displays (PFD, ND, MCDU, ECAM, OHP) | Fully architected | 100% |
| Failure engine (core + catalogues) | Mostly complete | 85% |
| Failure catalogues (fire cargo, gear, comms) | Missing | 0% |
| Training modes (all 12) | Fully architected | 100% |
| Instructor station | Fully architected | 100% |
| Recording / replay / assessment | Fully architected | 100% |
| Analytics | Fully architected | 100% |
| Multi-user architecture | Fully architected | 100% |
| Supabase schema (36 tables) | Fully architected | 100% |
| Data flow (internal + MCDU + recording) | Fully architected | 100% |
| REST API | Endpoints defined | 90% |
| Communication architecture (ARINC 429) | Conceptual mapping | 60% |
| Compliance / certification readiness | Fully architected | 100% |
| Implementation roadmap (10 phases) | Fully architected | 100% |
| **Overall Coverage** | | **~87%** |

---

## 5. Recommendation: 3 Additional Architecture Documents

To achieve 100% coverage of all 20 deliverables:

### `14_TECHNICAL_DEBT.md` — Standalone Technical Debt Report
Expand `01_GAP_ANALYSIS.md` §3 into a full document covering:
- All known bugs, workarounds, and shortcuts
- Code smells and SRP violations
- Missing tests
- Build system issues
- Memory architecture concerns
- Estimated remediation effort per item

### `15_PRODUCT_ARCHITECTURE.md` — Airline-Grade Product Summary
A single executive-level document that:
- Describes the product from a business/aviation perspective
- Maps capabilities to use cases (ATO, university, airline, self-study)
- Lists supported training curricula (EASA/FAA type rating syllabi)
- Summarizes the technology stack decision rationale
- Provides version roadmap (v1.0 → v2.0 → v3.0)
- Suitable for stakeholder/investor/airline partner review

### Update `09_SUPABASE_SCHEMA.md` — Add Mermaid ERDs
Add formal entity relationship diagrams for:
- User/Organization/Role hierarchy
- Session/Recording/Assessment chain
- Navigation data (Airport → Runway → SID/STAR/Approach)
- AIRAC versioning relationships
