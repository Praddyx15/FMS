# A320neo FMS Trainer — Airline-Grade Architecture Master Index

> Generated: 2026-06-25 | Aircraft: Airbus A320neo CFM LEAP-1A
> Design Philosophy: **Aircraft First → Systems Second → Training Third → UI Fourth**

---

## Deliverable Documents

| # | Document | File | Status |
|---|----------|------|--------|
| 1 | Gap Analysis & Forensic Review | `01_GAP_ANALYSIS.md` | ✅ |
| 2 | System Architecture Overview | `02_SYSTEM_ARCHITECTURE.md` | ✅ |
| 3 | Aircraft State Model & Flight Dynamics | `03_AIRCRAFT_STATE_MODEL.md` | ✅ |
| 4 | FMS & Navigation Architecture | `04_FMS_NAV_ARCHITECTURE.md` | ✅ |
| 5 | Avionics & Autopilot Architecture | `05_AVIONICS_AUTOPILOT.md` | ✅ |
| 6 | Cockpit Displays & UI Architecture | `06_COCKPIT_DISPLAYS_UI.md` | ✅ |
| 7 | Training & Instructor Architecture | `07_TRAINING_INSTRUCTOR.md` | ✅ |
| 8 | Failure Management Architecture | `08_FAILURE_MANAGEMENT.md` | ✅ |
| 9 | Supabase Schema (Airline-Grade) | `09_SUPABASE_SCHEMA.md` | ✅ |
| 10 | Data Flow & API Architecture | `10_DATA_FLOW_API.md` | ✅ |
| 11 | Implementation Roadmap | `11_IMPLEMENTATION_ROADMAP.md` | ✅ |
| 12 | Compliance & Certification Readiness | `12_COMPLIANCE_READINESS.md` | ✅ |
| 13 | Missing Modules Report & Coverage Audit | `13_MISSING_MODULES_REPORT.md` | ✅ |

---

## Current Codebase Inventory (Forensic Findings)

### C++ Backend (5 modules)
- `AirDataComputer` — 6-DOF sim core, 466 lines header, 20K source
- `FlightDataManager` — Singleton data bus, 282 lines header, 18K source
- `FMSComputer` — MCDU logic engine, 95 lines header, 14K source
- `InstructorEngine` — Failure injection, 60 lines header, 2.5K source
- `ArincParser` — ARINC 424 CIFP loader, 45 lines header, 4K source

### QML Frontend (47 files across 5 domains)
- **cockpit/** — 9 files (MainLayout, FCU, Yoke, Rudder, Throttle, Overhead, etc.)
- **displays/** — 13 files (PFD, ND, ECAM, FMA, tapes, etc.)
- **mcdu/** — 8 core + 31 page files (39 total)
- **instructor/** — 6 files (Station, Failures, Exam, Analytics, AI, Scenarios)
- **instruments/** — 7 files (analog six-pack)

### Supabase Schema — 26 tables, 4 functions, 20+ RLS policies

### Coding Standards Reference — DO-178C, JSF AV, MISRA, MIL-STD-1553, DO-254
