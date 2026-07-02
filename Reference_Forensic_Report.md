# Reference Forensic Analysis — Master Report
> Aircraft: Airbus A320neo CFM LEAP-1A | Stack: C++20/Qt6 | Date: 2026-06-25

---

## PART 1 — COMPLETE INVENTORY

### Directory Structure

```
Reference/
├── A320-family-dev/          FlightGear A320 (Nasal/XML) — REFERENCE GRADE
├── A320-fms-master/          React/TS FMS Trainer — INTERNAL LEGACY
├── fms-trainer-main/         React/TS FMS Trainer — INTERNAL LEGACY (identical to above)
└── FMS-Work/
    ├── FMS Docs/             PDFs: FCOM, AC 120-40B, ICAO Doc 8168, A320 procedures
    ├── Main Project/         Zip archives of prior Qt/React work
    ├── Reference files and repos/
    │   ├── FMS_Final_Files/  47-repo analysis + organized usable code
    │   ├── FMS_pending/      36 reference repos (backend focus)
    │   └── FMS_Frontend/     24 reference repos (frontend focus)
    └── Reference_feature document/  Feature list PDF/DOCX
```

---

## PART 2 — REPOSITORY ANALYSIS

### A320-family-dev (FlightGear A320 — REFERENCE ONLY)
**Platform**: FlightGear simulator | **Language**: Nasal (proprietary scripting) + XML
**License**: GPL-2.0 — cannot copy code, can reference algorithms
**Variants**: A320-200 CFM56, A320-200 IAE V2500, A320-251N CFM LEAP, A320-271N PW1100G

#### Subsystems Implemented (Nasal scripts):
| Module | Files | Lines | Quality |
|--------|-------|-------|---------|
| FMGC | FMGC.nas (46KB), FMGC-b.nas, FMGC-c.nas | ~3,200 | HIGH |
| Flight Plan | flightplan.nas (35KB) | ~1,000 | HIGH |
| MCDU | MCDU.nas (55KB) + 34 page files | ~6,000 | HIGH |
| ECAM | ECAM-logic.nas (149KB), ECAM-messages.nas (77KB) | ~6,500 | HIGH |
| Electrical | electrical.nas | 247 | HIGH |
| Hydraulics | hydraulics.nas | 234 | HIGH |
| FADEC CFM | fadec-cfm.nas + fadec-common.nas | 475 | HIGH |
| Fire | fire.nas | ~800 | HIGH |
| FBW | fbw.nas | ~300 | MEDIUM |
| APU | APU.nas | ~250 | MEDIUM |

#### Key Algorithms Extractable (conceptual only):
1. **FMGC Phase Logic** — 7-phase state machine: Preflight→Takeoff→Climb→Cruise→Descent→Approach→GoAround
2. **Fuel Prediction** — Polynomial regression model (6th-order) for trip fuel vs distance/altitude
3. **Speed Computation** — VLS, Vapp, Green Dot, S/F speeds from weight and configuration
4. **Flight Plan Manager** — 3-plan system (flightplans[0]=tmp1, [1]=tmp2, [2]=active)
5. **Decel Point Calculation** — Geometry-based 7nm from approach threshold
6. **Wind Integration** — FL50/FL150/FL250/CRZ wind capture at altitude
7. **FADEC Detent Logic** — IDLE/MAN/CL/MCT/FLX/MAN_THR/TOGA enum with A/THR coupling
8. **Braking System** — Normal/Alternate/Emergency brake cascade with accumulator
9. **Electrical Bus Architecture** — AC1/AC2/ACESS/ACESS-SHED/DC1/DC2/DCESS/DCBAT topology
10. **Failure Catalogue** (fail.xml) — ELAC1/2, SEC1/2/3, FAC1/2, RTLU1/2, THS, YD1/2, HYD leaks, ELEC buses, Fuel pumps, Fire (AFT/FWD cargo, LAV, Engine L/R, APU)

#### Reusable: Algorithms and design patterns only. No direct code copy (GPL).

---

### A320-fms-master / fms-trainer-main (INTERNAL — React/TS)
**Status**: These two directories are IDENTICAL (byte-for-byte same README, same package.json)
**Platform**: React 18 + Vite + TypeScript + TailwindCSS + Electron + Zustand + Supabase
**Version**: fms-trainer-main has a .git directory; A320-fms-master does not

#### Tech Stack:
```
React 18.3.1 + TypeScript 5.5 + Vite 7.2 + Electron 40
Zustand 5.0 (state management)
@supabase/supabase-js 2.89
@tanstack/react-query 5.56
Radix UI (complete set of primitives)
Recharts 3.3 (analytics)
react-router-dom 6.26
```

#### Architecture:
- `src/state/` — Zustand store (`useFMSStore`) as single source of truth
- `src/hooks/usePhysicsSim.ts` — Physics loop (60Hz target)
- `src/hooks/useTelemetrySim.ts` — Sensor simulation
- `src/hooks/useTelemetryWS.ts` — WebSocket telemetry
- `src/features/training/TrainingMode.tsx` — Training mode framework
- `src/features/training/ExamMode.tsx` — Exam/certification mode
- `src/components/` — 13 subdirs: displays, instruments, overhead, fms, instructor, training, analytics, controls, layout, ai, demo, setup, ui

#### Supabase Schema (minimal, from Docs/schema.md):
- `flight_sessions`: id, user_id, score, telemetry_log (JSONB)
- `user_profiles`: id, certification_level, training_progress (JSONB)

#### Critical Issues:
- Physics at 60Hz in a React hook — not deterministic, subject to GC pauses
- State management in Zustand (JS) — not suitable for C++ backend integration
- No separation between UI logic and aircraft physics
- Violates "Aircraft First" principle — UI drives state

#### Reusable Components (conceptually):
- `ExamMode.tsx` (14KB) — Exam scoring and timing framework
- `TrainingMode.tsx` (8KB) — Training mode state machine
- Radix UI component library — can inspire Qt widget design
- Recharts analytics patterns — reference for Qt analytics views

#### NOT Reusable:
- Physics hooks (too simplistic, React-coupled)
- Zustand store (JS/React pattern, incompatible with C++/Qt)
- All display components (need Qt/QML equivalents)

---

## PART 3 — FMS-Work Repository Ecosystem (47 repos analyzed)

### Pre-existing Analysis (from TIER1–4 reports, Jan-Oct 2025)
**Total repos analyzed**: 47 | **Files scanned**: 29,626 | **Usable files extracted**: 4,995
**Lines of code analyzed**: ~800,000+

### Priority Repository Map

#### CRITICAL — Must Reference (algorithm extraction)
| Repo | Language | Purpose | Key Value |
|------|----------|---------|-----------|
| **jsbsim-master** | C++ | 6-DOF flight dynamics | Atmosphere model, aerodynamics, propulsion |
| **littlenavmap-master** | C++/Qt | Navigation | ARINC 424 parsing, route planning algorithms |
| **ARINC424Parser-master** | Python | Nav DB parsing | Direct ARINC 424 spec implementation |
| **A320-family-dev** | Nasal | A320 systems | ECAM, MCDU, FMGC logic (reference only) |
| **BasicFMC-master** | C++ | FMC core | Routing algorithms, airway logic |

#### HIGH — Algorithm Reference
| Repo | Language | Purpose | Key Value |
|------|----------|---------|-----------|
| **hopsan-master** | C++ | System dynamics | Hydraulic/pneumatic simulation patterns |
| **openap-master** | Python | Performance DB | A320 drag polars, fuel burn tables |
| **pybada-main** | Python | BADA performance | Aircraft performance modeling |
| **aircraft-master** | TS/React | A320 cockpit | Display behavior reference (3,364 files) |
| **msfs-a320neo-master** | TS/JS | MSFS A320 | A320 display logic reference |
| **Flex-Calculator-TS-master** | TS | FLEX/TOGA perf | V-speed and FLEX temp algorithms |
| **QFlightinstruments-master** | C++/Qt | Qt instruments | Reusable Qt instrument widgets |
| **metaf-master** | C++ | METAR parser | Weather string parsing |
| **Terrain-Awareness-Warning-System-TAWS** | — | TAWS/EGPWS | Warning system logic |
| **cduhub-main** | C# | CDU display hub | CDU rendering patterns (242 files) |

#### MEDIUM — Concept Reference
| Repo | Purpose |
|------|---------|
| pipecat-main | Voice/audio pipeline for ATC voice |
| vosk-api-master | Offline speech recognition |
| whisper-main | AI speech-to-text |
| metar-taf-parser-main | Weather data UI |
| GeoFS-alerts-master | Web-based GPWS alert system |
| airport-codes-main | Airport ICAO database |

#### NOT USEFUL for our project:
- KSP_GPWS-master (KSP game, C# Unity)
- g3-master (Garmin G3000, unrelated avionics)
- glfw-master (OpenGL — we use Qt)
- cj4-mcdu-master (CJ4 geometry, not A320)

---

## PART 4 — OFFICIAL DOCUMENTATION INVENTORY

### FMS-Work/FMS Docs/ (6 files)
| File | Type | Value |
|------|------|-------|
| FCOM_21 Feb 2024.pdf | 206MB | **CRITICAL** — Airbus A320 Flight Crew Operating Manual |
| a320-normal-procedures.pdf | 4.8MB | **HIGH** — Normal checklists and procedures |
| a320-abnormal-notes.pdf | 1.2MB | **HIGH** — Abnormal/Emergency procedure reference |
| ICAO-Doc-8168-Volume-I-Flight-Procedures.pdf | 5MB | **HIGH** — ICAO PANS-OPS procedures |
| 120-40B1.pdf | 8.7MB | **MEDIUM** — FAA AC 120-40B FFS criteria |
| FMS trainer oerview Blueprint.docx | 29KB | **INTERNAL** — Early project planning doc |

### FMS-Work/Reference_feature document/
| File | Value |
|------|-------|
| Feature list_FMS.pdf / .docx | Original feature requirements spec |

---

## PART 5 — CODE FORENSICS SUMMARY

### What Exists in Our Project (current Qt/C++ codebase)
- `AirDataComputer` — monolithic class (physics + AP + FBW + engine)
- `FlightDataManager` — data singleton (not channel-based)
- 47 QML files — display-only, canvas-based, 12.5Hz cap
- Basic MCDU stub — decorative pages
- Supabase: 26 tables (missing orgs, AIRAC, recording)

### What Must Be Built From Scratch
1. `FlightDataBus` — channel-based Qt signal/slot data bus
2. `FlightDynamicsModel` — 6-DOF EOM (can use JSBSim as reference)
3. `EngineModel` (LEAP-1A) — N1/N2/EGT/FF/EPR model
4. `GroundModel` — taxi, braking, NWS
5. `AutopilotController` — full AP/FD/A-THR state machine
6. `FMGCCore` — dual FMGC with 3-plan flight plan management
7. `FlightPlanManager` — ARINC 702A compliant
8. `PerformanceEngine` — V-speeds, FLEX, fuel predictions
9. `NavigationDatabase` — ARINC 424 loader
10. `FailureEngine` — 40+ failures with cascade
11. `TrainingEngine` — 12 mode framework
12. `InstructorStation` — scenario/failure/position control
13. `RecordingEngine` — 4Hz state snapshot
14. `AssessmentEngine` — deviation scoring

---

## PART 6 — KEY ALGORITHM EXTRACTIONS (from A320-family-dev)

### Fuel Prediction (from FMGC.nas lines 447-494)
```
trip_fuel = f(dist, crz_fl) — 6th-order polynomial
trip_time = g(dist, crz_fl) — 6th-order polynomial
landing_weight_correction = h(dist, crz_fl, landing_weight)
final_fuel = final_time × 2 × ((zfw²×-2e-10) + (zfw×0.0003) + 2.8903)
```
**For C++**: Port these polynomials to `PerformanceEngine::computeTripFuel(dist_nm, crz_fl, zfw_kg)`

### FMGC Phase State Machine (from FMGC.nas lines 627-673)
```
Phase 0 (PREFLIGHT) → N1≥85% AND GS≥90kt → Phase 1 (TAKEOFF)
Phase 1 (TAKEOFF) → SRS ended AND airborne → Phase 2 (CLIMB)
Phase 2 (CLIMB) → ALT CRZ captured → Phase 3 (CRUISE)
Phase 3 (CRUISE) → dist≤200nm OR altSel<20000 → Phase 4 (DESCENT)
Phase 4 (DESCENT) → decel point reached → Phase 5 (APPROACH)
Phase 5 (APPROACH) → TOGA+TOGA → Phase 6 (GO-AROUND)
Phase 6 (GO-AROUND) → alt≥accel_ft → Phase 2 (CLIMB)
```

### FADEC Detent Mapping (from fadec-common.nas)
```
Detent 0 = IDLE    → idleAthrOff()
Detent 1 = MAN
Detent 2 = CL      → A/THR manages
Detent 3 = MAN_THR (between CL and MCT)
Detent 4 = MCT     → cancelFlex() if flex active
Detent 5 = MAN_THR (above MCT)
Detent 6 = TOGA    → engage A/THR if on ground
```

### Vapp Computation (from FMGC.nas)
```cpp
// Port to C++:
double vapp = vls + std::max(5.0, headwindComponent);
headwindComponent = std::clamp(destWindComponent / 3.0, 0.0, 15.0);
```

### Failure Property Tree (from fail.xml — complete catalogue)
**FCTL**: ELAC1, ELAC2, SEC1, SEC2, SEC3, FAC1, FAC2, RTLU1, RTLU2, THS-JAM, YD1, YD2
**PNEU**: Bleed1/2 valve, HP1/2 valve, Hot Air, Ram Air, Pack1/2, X-Bleed
**HYD**: Blue/Green/Yellow leak, Blue ELEC pump, Green EDP, Yellow EDP, Yellow ELEC, PTU
**ELEC**: AC ESS bus, APU GEN, DC ESS bus, EMER GEN, GEN1, GEN2
**FUEL**: L pump 1/2, C pump 1/2, R pump 1/2
**FIRE**: AFT CRG, FWD CRG, LAV, Engine Left, Engine Right, APU

---

## PART 7 — DUPLICATE KNOWLEDGE REPORT

| Topic | Sources | Best Source |
|-------|---------|------------|
| FMGC phase logic | A320-family-dev, fms-trainer-main | A320-family-dev |
| MCDU pages | A320-family-dev (34 pages), fms-trainer-main (stub) | A320-family-dev |
| ECAM logic | A320-family-dev (149KB ECAM-logic.nas) | A320-family-dev |
| Electrical system | A320-family-dev (detailed), fms-trainer-main (none) | A320-family-dev |
| Hydraulic system | A320-family-dev, hopsan-master | A320-family-dev |
| Flight plan manager | A320-family-dev, BasicFMC-master | A320-family-dev (more complete) |
| ARINC 424 parsing | ARINC424Parser-master, littlenavmap | ARINC424Parser-master |
| Performance tables | openap-master, pybada-main | openap-master (better A320 data) |
| 6-DOF physics | jsbsim-master, hopsan-master | jsbsim-master |
| Repo gap analysis | FMS_Final_Files/docs/ (already done Jan 2025) | Already complete |

---

## PART 8 — LICENSING RISK MATRIX

| Repository | License | Risk | Action |
|-----------|---------|------|--------|
| A320-family-dev | GPL-2.0 | 🔴 HIGH | Reference only — no code copy |
| JSBSim | LGPL-2.1 | 🟡 MEDIUM | Can link as library |
| littlenavmap | GPL-3.0 | 🔴 HIGH | Reference only |
| BasicFMC-master | MIT | 🟢 LOW | Can use freely |
| ARINC424Parser | MIT/Apache | 🟢 LOW | Can use freely |
| openap-master | MIT | 🟢 LOW | Can use freely |
| hopsan-master | Apache 2.0 | 🟢 LOW | Can use freely |
| A320-fms-master | Educational | 🟢 LOW | Internal project |
| QFlightinstruments | LGPL | 🟡 MEDIUM | Dynamic link OK |

---

## PART 9 — REUSABLE MODULE REPORT

### Directly Adaptable to C++/Qt (algorithm extraction — clean-room)
1. **Fuel polynomial model** → `PerformanceEngine` class
2. **FMGC phase state machine** → `FMGCController::FlightPhase` enum + transitions
3. **3-plan flight plan architecture** → `FlightPlanManager::Plan[3]`
4. **FADEC detent logic** → `ThrottleQuadrantModel::Detent` enum
5. **Vapp/VLS/Green-Dot computation** → `SpeedComputations` class
6. **Failure property tree structure** → `FailureEngine::FailureId` catalogue
7. **Electrical bus topology** → `ElectricalSystem` with relay/bus nodes
8. **Hydraulic braking cascade** → `BrakeSystem` with normal/alt/emergency modes
9. **ARINC 424 parsing** — ARINC424Parser-master (MIT, adapt to C++)
10. **openap A320 performance data** — Extract JSON tables to C++ constexpr arrays

### Usable React Patterns (reference for QML equivalent)
- ExamMode.tsx — scoring/timing → QML `ExamModeView`
- TrainingMode.tsx — mode state machine → QML `TrainingModeView`
- Recharts analytics → Qt Charts equivalent

---

## PART 10 — ENGINEERING RECOMMENDATIONS

### Priority 1: Immediate (before any feature work)
1. Fix `kTmax = 132000` (LEAP-1A26 N1-to-thrust)
2. `CMAKE_CXX_STANDARD 20`
3. Remove `c:/Users/akass/` hardcoded paths
4. Create `FlightDataBus` replacing `FlightDataManager` singleton
5. Decompose `AirDataComputer` into SRP-compliant modules

### Priority 2: Foundation (Weeks 1-4)
6. Implement `FMGCController` with 7-phase state machine (reference: A320-family-dev)
7. Implement `PerformanceEngine` with fuel polynomials (reference: A320-family-dev FMGC.nas)
8. Implement `FlightPlanManager` with 3-plan architecture
9. Integrate ARINC424Parser concepts for nav DB loading
10. Add `openap` A320 drag polars and fuel burn tables as constexpr tables

### Priority 3: Systems (Weeks 5-10)
11. Implement `FailureEngine` with full catalogue (reference: fail.xml)
12. Implement `ElectricalSystem` with bus topology (reference: electrical.nas)
13. Implement `HydraulicSystem` with braking cascade (reference: hydraulics.nas)
14. Implement `FADECModel` with detent logic (reference: fadec-common.nas)
15. Implement `ECAMController` with warning logic (reference: ECAM-logic.nas concepts)

### Priority 4: Training (Weeks 11-20)
16. Implement 12 training modes in `TrainingEngine`
17. Implement `InstructorStation` with failure injection
18. Implement `RecordingEngine` at 4Hz
19. Deploy Supabase 36-table schema
20. Implement `AssessmentEngine` with tolerance-based scoring

---

## PART 11 — CROSS-REFERENCE INDEX

| Future Dev Task | Supporting Reference |
|----------------|---------------------|
| FMGC phase state machine | A320-family-dev/Nasal/FMGC/FMGC.nas lines 612-703 |
| Fuel prediction polynomials | A320-family-dev/Nasal/FMGC/FMGC.nas lines 447-550 |
| 3-plan flight plan system | A320-family-dev/Nasal/FMGC/flightplan.nas |
| MCDU page architecture | A320-family-dev/Nasal/MCDU/ (34 pages) |
| ECAM warning logic | A320-family-dev/Nasal/ECAM/ECAM-logic.nas |
| ECAM message strings | A320-family-dev/Nasal/ECAM/ECAM-messages.nas |
| Failure catalogue | A320-family-dev/AircraftConfig/fail.xml |
| Electrical bus model | A320-family-dev/Nasal/Systems/electrical.nas |
| Hydraulic + braking | A320-family-dev/Nasal/Systems/hydraulics.nas |
| FADEC/throttle detents | A320-family-dev/Nasal/Systems/fadec-common.nas |
| Fire system | A320-family-dev/Nasal/Systems/fire.nas |
| APU logic | A320-family-dev/Nasal/Systems/APU.nas |
| FBW laws | A320-family-dev/Nasal/Systems/fbw.nas |
| ARINC 424 parsing | FMS_pending/ARINC424Parser-master |
| 6-DOF flight dynamics | FMS_pending/jsbsim-master |
| A320 performance tables | FMS_pending/openap-master |
| BADA performance model | FMS_pending/pybada-main |
| METAR parsing | FMS_pending/metaf-master |
| Qt instrument widgets | FMS_Frontend/QFlightinstruments-master |
| A320 display behavior | FMS_Frontend/msfs-a320neo-master |
| Training mode patterns | A320-fms-master/src/features/training/ |
| Supabase schema baseline | A320-fms-master/Docs/schema.md |
| FCOM procedures | FMS-Work/FMS Docs/FCOM_21 Feb 2024.pdf |
| Normal procedures | FMS-Work/FMS Docs/a320-normal-procedures.pdf |
| Abnormal procedures | FMS-Work/FMS Docs/a320-abnormal-notes.pdf |
| ICAO instrument procedures | FMS-Work/FMS Docs/ICAO-Doc-8168-Volume-I.pdf |
| FAA FFS criteria | FMS-Work/FMS Docs/120-40B1.pdf |
| Prior 47-repo analysis | FMS-Work/Reference files and repos/FMS_Final_Files/docs/ |
