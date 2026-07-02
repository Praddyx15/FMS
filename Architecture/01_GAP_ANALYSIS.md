# 01 — Gap Analysis & Forensic Review

## 1. Executive Summary

The current FMS-Trainer has a solid foundation: a working 6-DOF `AirDataComputer`, functional MCDU with 31 pages, PFD/ND/ECAM displays, an ARINC 424 parser, and a 26-table Supabase schema. However, it is architecturally structured as a **display trainer**, not an **aircraft systems trainer**. The aircraft state engine is incomplete, systems are decorative rather than functional, and the training/instructor subsystems are UI shells without backend logic.

To reach airline-grade status, approximately **70% of the backend** and **40% of the frontend** require new implementation or significant rework.

---

## 2. What EXISTS vs What is REQUIRED

### 2.1 Aircraft State Model

| Parameter | EXISTS | REQUIRED | Gap |
|-----------|--------|----------|-----|
| Position (lat/lon/alt) | ✅ | ✅ | — |
| Pressure Altitude | ❌ | ✅ | **Missing** — uses geometric alt only |
| Radio Altitude | ❌ | ✅ | **Missing** — no terrain model |
| Heading / Track | ✅ heading | ✅ both | **Track missing** — no wind correction |
| Ground Speed | ✅ | ✅ | — |
| TAS / IAS / Mach | ✅ | ✅ | — |
| Vertical Speed | ✅ | ✅ | — |
| Pitch / Roll / Yaw | ✅ | ✅ | — |
| Angle of Attack | ✅ | ✅ | — |
| Sideslip | ✅ | ✅ | — |
| Load Factor (Nz) | ✅ | ✅ | — |
| Wind Vector | Partial | ✅ | **Heading/speed only** — no 3D wind model |
| Temperature / Pressure | ISA only | ✅ | **No ISA deviation, SAT/TAT** |
| Aircraft Weight | Static | ✅ | **Mass fixed at 62000 kg** — no dynamic CG |
| CG Position | ❌ | ✅ | **Missing** |
| Fuel State (per tank) | ✅ 5 tanks | ✅ | Exists but not consumed dynamically by flight model |

### 2.2 Flight Physics (6-DOF)

| Component | EXISTS | Gap |
|-----------|--------|-----|
| Translational dynamics (X/Y/Z) | ✅ | — |
| Rotational dynamics (P/Q/R) | ✅ | — |
| Lift / Drag / Side Force | ✅ | Simplified — no Mach/config-dependent tables |
| Pitching / Rolling / Yawing Moments | ✅ | Fixed coefficients — no lookup tables |
| Ailerons / Elevators / Rudder | ✅ | Control surface deflection computed but not as separate systems |
| Spoilers / Speed Brakes | ❌ | **Missing** |
| Flaps / Slats | Config 0-4 exists | No aerodynamic effect modelled per config |
| Ground Interaction | ❌ | **Missing** — no ground model, taxi, braking, nosewheel |
| Engine Model | Simplified N1 | **No spool-up dynamics, bleed effects, fuel flow** |

### 2.3 FMS Architecture (ARINC 702A)

| Feature | EXISTS | Gap |
|---------|--------|-----|
| Route Management (origin/dest/alt) | ✅ | — |
| Waypoints / Flight Plan | ✅ | No SID/STAR/Approach integration in active plan |
| SID / STAR / Approach Selection | DB exists | **Not selectable in MCDU, not loaded into FMS** |
| Active / Secondary / Temporary Plan | ❌ | **Missing** — single plan only |
| Performance (TO/CLB/CRZ/DES/APP) | Page stubs | **No performance computation engine** |
| Fuel Predictions (EFOB/ETA) | ❌ | **Missing** |
| TOC / TOD Computation | ❌ | **Missing** |
| VNAV / LNAV | LNAV partial | **VNAV missing** |
| Speed / Altitude Constraints | ❌ | **Missing** |
| Cost Index Optimization | Stored only | **Not used in computations** |

### 2.4 Navigation Database (ARINC 424)

| Feature | EXISTS | Gap |
|---------|--------|-----|
| CIFP File Parser | ✅ ~4383 wpts | — |
| Airport Data | Supabase seed | Not integrated with CIFP |
| Runway Data | Supabase seed | — |
| SID/STAR/Approach Data | Supabase seed | Not loaded into FMS runtime |
| Airway Data | Schema exists | No airway-based routing |
| AIRAC Cycle Management | ❌ | **Missing** |
| Database Versioning | ❌ | **Missing** |
| Holding Procedures | ❌ | **Missing** |

### 2.5 Avionics Systems

| System | EXISTS | Gap |
|--------|--------|-----|
| ADIRS (3-unit) | Flags only | **No alignment sequence, no degraded modes** |
| FMGC | Partial | Single FMS, no dual FMGC |
| FAC | ❌ | **Missing** |
| SEC / ELAC | ❌ | **Missing** — FBW law mentioned but not implemented |
| FCU | ✅ functional | — |
| ECAM | ✅ 12 pages | System pages are display-only, not driven by state |
| TCAS | Overlay only | **No TA/RA logic** |
| EGPWS | ❌ | **Missing** |
| Weather Radar | Overlay only | **Mock blobs, no model** |
| Transponder | ❌ | **Missing** |
| Radio Nav (VOR/DME/ILS/NDB) | ILS partial | **VOR/DME/NDB not functional** |
| GPS/GNSS | Flag only | **No position solution model** |

### 2.6 Autopilot / Autothrust

| Mode | EXISTS | Gap |
|------|--------|-----|
| HDG / TRK | HDG ✅ | TRK missing |
| NAV | ❌ | **Missing** — no LNAV coupling |
| LOC / APP | LOC partial | APP incomplete |
| ALT / ALT* / ALT CRZ | ALT ✅ | ALT*/CRZ missing |
| CLB / DES | ❌ | **Missing** |
| VS / FPA | VS ✅ | FPA missing |
| GS / FINAL APP | ❌ | **Missing** |
| EXPEDITE | ❌ | **Missing** |
| A/THR modes (SPEED/MACH/THR CLB/IDLE) | Partial | Only basic speed hold |
| Mode reversion logic | ❌ | **Missing** |

### 2.7 Cockpit Displays

| Display | EXISTS | Gap |
|---------|--------|-----|
| PFD — Attitude | ✅ | — |
| PFD — Speed Tape | ✅ | V-speed bugs incomplete |
| PFD — Altitude Tape | ✅ | No cyan target, no metric alt |
| PFD — FMA | ✅ basic | **Not 5-column A320 standard** |
| PFD — Heading | ✅ | — |
| PFD — Flight Director | ✅ | — |
| PFD — ILS Deviation | ✅ | — |
| ND — All 5 modes | ✅ | — |
| ND — WXR/TERR/TCAS overlays | ✅ mock | — |
| MCDU — 31 pages | ✅ | LSK data binding incomplete |
| ECAM — Upper/Lower | ✅ | System data decorative |
| Overhead Panel | 3-toggle stub | **~95% missing** |
| Throttle Quadrant | ✅ | No detent logic (CL/MCT/FLX/TOGA) |

### 2.8 Training Architecture

| Feature | EXISTS | Gap |
|---------|--------|-----|
| 12 Training Modes | ❌ | **Missing** — no modal training framework |
| Instructor Station | UI shell | **No backend logic** |
| Scenario Creation/Editing | ❌ | **Missing** |
| Failure Injection | 1 catalogue | **No progressive/random failures** |
| Session Recording | ❌ | **Missing** |
| Replay / Debrief | ❌ | **Missing** |
| Analytics (flight path/fuel/stability) | UI shell | **No computation backend** |
| Multi-user / Multiplayer | ❌ | **Missing** |

### 2.9 Supabase Schema

| Domain | EXISTS | Gap |
|--------|--------|-----|
| Users & Roles | ✅ | No organization/airline hierarchy |
| Aircraft Configurations | ✅ | No fleet/tail-number model |
| Navigation Data (airports, etc.) | ✅ | — |
| Training Sessions | ✅ | No training mode tracking |
| Flight Plans | ✅ | — |
| Scenarios | ✅ | — |
| Checklists | ✅ | — |
| Organizations/Airlines | ❌ | **Missing** |
| AIRAC Cycle Management | ❌ | **Missing** |
| Failure Library (persistent) | ❌ | **Missing** |
| Session Recording Data | ❌ | **Missing** |
| Certificates / Assessments | ❌ | **Missing** |

---

## 3. Technical Debt Summary

| Category | Items |
|----------|-------|
| **Engine constants** | `kTmax = 120000 N` labeled "CFM56-5B" but aircraft is A320neo (should be LEAP-1A at 130000 N) |
| **C++ standard** | CMakeLists sets C++17, docs say C++20 — inconsistent |
| **Legacy paths** | `main.cpp` has hardcoded `c:/Users/akass/` Windows paths |
| **Memory architecture** | Canvas-based displays leak under threaded render loop (mitigated but not solved) |
| **Render rate** | Forced to 12.5 Hz to avoid OOM — should be 30+ Hz for training fidelity |
| **No unit types** | Raw `double` everywhere — no type-safe unit system (feet vs meters vs radians) |
| **State coupling** | `AirDataComputer` is both physics engine AND autopilot AND flight computer — violates SRP |
| **Test coverage** | Test infrastructure exists but empty (`Backend/tests/`) |
| **Build system** | Windows-only windeployqt, no Linux deployment path |

---

## 4. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Monolithic AirDataComputer | 🔴 High | Decompose into FMGC, ADC, FAC, AP modules |
| No ground model | 🔴 High | Prevents taxi/takeoff/landing training |
| No VNAV | 🔴 High | Core FMS feature — blocks performance training |
| Canvas memory leaks | 🟡 Medium | Migrate PFD/ND to scene-graph items |
| Single-user only | 🟡 Medium | Add WebSocket/network layer |
| No session recording | 🟡 Medium | Add state serialization framework |
