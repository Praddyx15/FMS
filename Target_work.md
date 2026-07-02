# FMS-Trainer — Target Work: Airline-Grade A320neo Trainer Platform

> **Status**: Requirements & Objectives Specification
> **Aircraft**: Airbus A320neo CFM LEAP-1A
> **Design Authority**: Aircraft First → Systems Second → Training Third → UI Fourth
> **Created**: 2026-06-25

---

## PROJECT OBJECTIVE

Perform a complete forensic review of the entire codebase, Supabase schema, simulator architecture, avionics architecture, training architecture, instructor architecture, aircraft systems architecture, data flow architecture, and UI architecture.

The goal is to transform the current project into an **airline-grade Airbus A320neo CFM LEAP-1A Flight Management System Trainer and Procedures Trainer platform**.

This platform must support:

1. Airline procedure training
2. FMS training
3. MCDU training
4. Navigation training
5. Systems training
6. Instructor-led training
7. Self-paced pilot training
8. Type-rating preparation
9. Abnormal and emergency procedures
10. Academic aerospace education
11. Multi-user enterprise deployment
12. Future airline integrations

> [!IMPORTANT]
> **Local-First Constraint**: The initial development of the complete project must be done entirely locally, without dependencies on Supabase, database syncing, or any cloud services. The application must run locally on the host system as a standalone offline product.

The architecture must be designed as if it may eventually support:
- Airline training organizations (ATOs)
- Universities
- OEM demonstrations
- Aviation training centers

---

## PRIMARY DESIGN PHILOSOPHY

```
Aircraft First → Systems Second → Training Third → UI Fourth
```

**Never**: UI First → Aircraft Second

- The aircraft state engine must always remain the **authoritative source of truth**
- The UI must only **visualize and control** the aircraft state

---

## AIRCRAFT MODEL

**Primary Aircraft**: Airbus A320neo
**Primary Engine**: CFM LEAP-1A

Implement architecture supporting:
- Aircraft
- Fleet
- Tail Number
- Configuration
- Airline Profile

**Future extensibility**:
- A319
- A321
- CEO Variants
- PW1100G Variants

---

## FLIGHT DYNAMICS MODEL

Implement a proper aircraft state model including:

| Parameter | Unit |
|-----------|------|
| Latitude | deg (WGS-84) |
| Longitude | deg (WGS-84) |
| Altitude (geometric) | ft |
| Pressure Altitude | ft (QNH-corrected) |
| Radio Altitude | ft AGL |
| Heading | deg magnetic |
| Track | deg magnetic |
| Ground Speed | kt |
| True Airspeed | kt |
| Indicated Airspeed (CAS) | kt |
| Mach Number | dimensionless |
| Vertical Speed | ft/min |
| Pitch | deg |
| Roll | deg |
| Yaw | deg |
| Acceleration (X/Y/Z body) | m/s² |
| Wind Vector (direction/speed) | deg / kt |
| Temperature (OAT/TAT/ISA dev) | °C |
| Static Pressure | hPa |
| Aircraft Weight (instantaneous) | kg |
| Center of Gravity | % MAC |
| Fuel State (per tank) | kg |

---

## FLIGHT PHYSICS

Develop architecture supporting 6-DOF Flight Dynamics:

### Translational (Body Frame)
- X (longitudinal)
- Y (lateral)
- Z (normal)

### Rotational
- Pitch (Q)
- Roll (P)
- Yaw (R)

### Aerodynamic Forces
- Lift
- Drag
- Side Force

### Moments
- Pitching Moment
- Rolling Moment
- Yawing Moment

### Control Surfaces
- Ailerons
- Elevators
- Rudder
- Spoilers (5 per side)
- Speed Brakes
- Flaps (configs 0, 1, 1+F, 2, 3, FULL)
- Slats

### Ground Interaction
- Taxi
- Braking (normal + autobrake LO/MED/MAX)
- Nosewheel Steering (±75° tiller, ±6° rudder)
- Crosswind effects on ground
- Runway friction (dry/wet/icy coefficients)

---

## FMS ARCHITECTURE

Must comply conceptually with **ARINC 702A**.

### Route Management
- Origin / Destination / Alternate (ICAO)
- Waypoints (named fixes)
- Airways (airway-based routing)
- SID (Standard Instrument Departure)
- STAR (Standard Terminal Arrival Route)
- Approaches (ILS, RNAV, VOR, NDB, RNP)

### Flight Plan Management
- Active Plan (currently executing)
- Secondary Plan (SEC F-PLN)
- Temporary Plan (during MCDU editing → TMPY)

### Performance Management
- Takeoff performance (V1/VR/V2, FLEX temp)
- Climb performance (speed schedule, TOC)
- Cruise performance (optimal FL, step climbs, specific range)
- Descent performance (TOD, managed descent profile)
- Approach performance (Vapp, landing distance)

### Predictions
- Fuel predictions (trip, alternate, holding, extra, EFOB)
- Time predictions (ETA per waypoint)
- Distance to go
- EFOB per waypoint

### Navigation Computations
- TOC (Top of Climb)
- TOD (Top of Descent)
- VNAV profile (managed vertical navigation)
- LNAV path (lateral navigation with leg transitions)

### Constraint Management
- Speed constraints (at/at-or-below/at-or-above)
- Altitude constraints (A/B/C types)

---

## NAVIGATION DATABASE

Implement architecture compatible with **ARINC 424**.

Include:
- Airports (with coordinates, elevation, frequencies)
- Runways (heading, length, threshold coordinates, ILS)
- SIDs (with transitions)
- STARs (with transitions)
- Approaches (ILS, RNAV, VOR, NDB, RNP — CAT I/II/III)
- Waypoints (named fixes)
- Navaids (VOR, DME, NDB, ILS, MLS, GPS)
- Airways (upper and lower)
- Holding Procedures

Support:
- Future database updates
- Database versioning
- AIRAC cycle management (28-day cycles, 13/year)
- Dual-cycle support (current + next)
- Auto-switch on effective date

---

## AVIONICS SYSTEMS

Implement architecture for:

| System | Acronym | Quantity |
|--------|---------|---------|
| Air Data Inertial Reference System | ADIRS | 3 |
| Inertial Reference System | IRS | 3 (within ADIRS) |
| Flight Management & Guidance Computer | FMGC | 2 |
| Flight Augmentation Computer | FAC | 2 |
| Spoiler Elevator Computer | SEC | 3 |
| Elevator Aileron Computer | ELAC | 2 |
| Flight Control Unit | FCU | 1 |
| Electronic Centralized Aircraft Monitor | ECAM | 2 |
| Traffic Collision Avoidance System | TCAS | 1 |
| Enhanced Ground Proximity Warning | EGPWS | 1 |
| Weather Radar | WXR | 1 |
| Transponder | XPDR | 1 |
| Automatic Direction Finder | ADF | 2 |
| Distance Measuring Equipment | DME | 2 |
| VHF Omnidirectional Range | VOR | 2 |
| Instrument Landing System | ILS | 2 |
| Microwave Landing System | MLS | 1 |
| Global Positioning System | GPS | 2 |
| Global Navigation Satellite System | GNSS | 2 |

---

## AUTOPILOT SYSTEMS

### Lateral Modes
- HDG (selected heading hold)
- TRK (selected track hold)
- NAV (managed LNAV — FMS-coupled)
- LOC (localizer capture & track)
- APP (approach — ILS/RNAV)
- GA TRK (go-around track)
- RWY / RWY TRK (runway alignment)
- EXPEDITE (bank-limited NAV)

### Vertical Modes
- ALT (altitude hold)
- ALT* (altitude capture)
- ALT CRZ (cruise altitude hold)
- CLB (managed climb — speed schedule)
- DES (managed descent — VNAV profile)
- OP CLB (open climb)
- OP DES (open descent)
- VS (vertical speed hold)
- FPA (flight path angle hold)
- GS / GS* (glideslope capture & track)
- FINAL APP / FLARE
- SRS (speed reference system — initial climb)
- TCAS (TCAS RA response)

### Autothrust Modes
- SPEED (CAS hold)
- MACH (Mach hold)
- THR CLB (climb thrust limit)
- THR MCT / THR FLX (max cont. / flex)
- THR IDLE (idle thrust)
- THR LVR (lever position)
- A.FLOOR / TOGA LK (alpha floor protection)
- RETARD (flare retard)

---

## COCKPIT DISPLAYS

### Primary Flight Display (PFD)
Must include:
- Attitude Indicator (artificial horizon, FD bars)
- Speed Tape (with color bands: VMO, VFE, VLS, αprot, αmax, Green Dot, F, S, V-speeds)
- Altitude Tape (barometric, with cyan target box, metric option)
- Vertical Speed (scale + digital)
- Heading / Track display
- Flight Director (pitch/roll bars)
- FMA — 5-column A320 standard:
  - Col 1: Speed/Thrust mode
  - Col 2: Vertical mode (active + armed)
  - Col 3: Lateral mode (active + armed)
  - Col 4: Approach capability (CAT1/2/3)
  - Col 5: AP/FD/A-THR engagement status
- ILS deviation (LOC + GS)
- Radio altimeter (below 2500 ft)

### Navigation Display (ND)
Modes:
- ROSE ILS
- ROSE VOR
- ROSE NAV
- ARC
- PLAN

Overlays:
- WXR (Weather Radar)
- TERR (Terrain — EGPWS)
- TCAS (Traffic)
- VOR/NDB (Navaids)
- WPT (Waypoints)
- CSTR (Constraints)
- ARPT (Airports)
- TOC/TOD pseudo-waypoints

### MCDU — All major pages
- MCDU MENU
- INIT A / INIT B
- F-PLN (with SID/STAR/constraints display)
- RAD NAV (with live nav tuning)
- PERF (all phases: TO, CLB, CRZ, DES, APPR, GA)
- PROG (with live predictions)
- DATA
- FUEL PRED
- DIR TO
- SEC F-PLN
- DEPARTURE / ARRIVAL
- WIND (all phases)
- HOLD (new)
- OFFSET (new)
- FIX INFO (new)

### ECAM
- Upper display: Engine parameters + warnings + memo
- Lower display: 12 system pages (all state-driven, not decorative)

**System Pages:**
- ENGINE
- FUEL
- HYDRAULIC
- ELECTRICAL
- BLEED / PNEUMATIC
- PRESSURIZATION
- DOORS
- WHEELS / LANDING GEAR
- FLIGHT CONTROLS (F/CTL)
- AIR CONDITIONING (COND)
- APU
- CRUISE

---

## OVERHEAD PANEL

Create full system architecture. Every switch drives actual aircraft state. No decorative switches.

### Panels Required:
- **ADIRS**: IR1/2/3 mode selectors (OFF/NAV/ATT), ON BAT annunciators
- **Electrical**: GEN1, GEN2, APU GEN, BAT1, BAT2, EXT PWR, BUS TIE, AC ESS FEED
- **Hydraulic**: ENG1/2 pumps, ELEC PUMP BLUE/YELLOW, PTU, RAT
- **Fuel**: L/R tank pumps (×2 each), CTR TK L/R pumps, X FEED, MODE SEL
- **Pneumatic/Bleed**: ENG1/2 BLEED, APU BLEED, X BLEED, PACK 1/2, RAM AIR
- **Air Conditioning**: CKPT/FWD/AFT cabin temperature, HOT AIR
- **Pressurization**: MODE SEL, LDG ELEV, DITCHING
- **Fire Protection**: ENG1 FIRE, ENG2 FIRE, APU FIRE pushbuttons + agent discharge
- **APU**: MASTER SW, START
- **Anti-Ice**: WING, ENG1, ENG2, PROBE HEAT AUTO
- **Signs**: SEAT BELTS, NO SMOKING, EMER EXIT LT
- **Lighting**: STROBE, BEACON, NAV, LAND L/R, NOSE (T.O/TAXI/OFF)

---

## THROTTLE QUADRANT

Support:
- Throttle Levers (dual, ±120° arc)
- Reverse Thrust (ground only, via detent reversal)
- Speed Brake lever (RETRACT/½/FULL + ARMED)
- Flap lever (0/1/2/3/FULL)
- Landing Gear lever (UP/OFF/DN)
- Autobrake selector (OFF/LO/MED/MAX)
- Parking Brake

### Throttle Detents:

| Detent | TLA | N1 | A/THR Mode |
|--------|-----|----|-----------|
| IDLE | 0° | 19.5% | THR IDLE |
| CL | 25° | ~85% | THR CLB (managed) |
| MCT | 35° | ~92.5% | THR MCT |
| FLX/MCT | 35° | flex temp N1 | THR FLX |
| TOGA | 45° | ~96% | THR TOGA |
| REV IDLE | -5° | idle reverse | REV |
| REV MAX | -20° | ~75% | REV MAX |

---

## FAILURE MANAGEMENT

Create airline-grade failure engine with full cascading logic.

### Failure Types:
- Single (one failure at a time)
- Multiple (concurrent failures)
- Progressive (severity ramps over time)
- Random (probability per flight hour)
- Instructor (real-time manual injection)
- Scripted (pre-programmed in scenario)
- Conditional (triggered by flight state: alt/speed/phase)

### Systems (Failure Catalogues):
- **Engine** (flame-out, fire, oil, surge, dual, bird strike)
- **Hydraulic** (Green/Blue/Yellow low press, leaks, dual failure, RAT deployment)
- **Electrical** (GEN1/2 fail, dual GEN, battery, TR fault, emergency config)
- **IRS/ADIRS** (IR1/2/3 fail, ADR fault, ATT-only degradation)
- **Flight Controls** (ELAC dual, SEC fault, FAC fault, direct law, rudder jam)
- **Sensors** (pitot blockage single/dual, static port, AOA probe)
- **Navigation** (GPS fail, ILS fail, VOR/DME fail, FMS1/dual fail)
- **Pressurization** (excess cabin alt, rapid decompression, outflow valve, dual pack)
- **Fire** (engine fire, APU fire, cargo smoke, lavatory smoke)
- **Landing Gear** (gear unsafe, asymmetric, gravity extension)
- **Communication** (VHF1/2 fail, ACARS fail)

### Cascading Logic Requirements:
- Each failure must trigger correct secondary effects
- ECAM must automatically display relevant system page
- ECAM messages must match Airbus QRH wording
- Memory items must be flagged separately from QRH items

---

## TRAINING MODES

This platform is **not only a flight simulator**. It must implement dedicated training modes with mode-specific configurations.

### Mode Configuration Per Mode:

| # | Mode Name | Sim Active | MCDU | FCU | OHP | Failures | Grading |
|---|-----------|------------|------|-----|-----|----------|---------|
| 1 | Aircraft Familiarization | ❌ | View | View | View | ❌ | ❌ |
| 2 | Cockpit Familiarization | ❌ | View | View | View | ❌ | ❌ |
| 3 | MCDU Training | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| 4 | FMS Procedures | Partial | ✅ | ✅ | ❌ | ❌ | ✅ |
| 5 | Flight Planning | Partial | ✅ | ✅ | ❌ | ❌ | ✅ |
| 6 | Normal Procedures | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| 7 | Abnormal Procedures | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 8 | Emergency Procedures | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 9 | Systems Training | ❌ | View | View | ✅ | ✅ | ✅ |
| 10 | Instrument Procedures | ✅ | ✅ | ✅ | ❌ | Optional | ✅ |
| 11 | Type Rating Preparation | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 12 | Instructor-Led Session | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## INSTRUCTOR STATION

Implement full instructor architecture with:

### Scenario Management
- Create scenarios
- Edit scenarios
- Load / save scenarios
- Library of pre-built A320 scenarios

### Failure Injection
- Browse failure catalogue (40+ failures)
- Inject immediately
- Schedule at time/phase/altitude/speed
- Clear individual or all failures
- Progressive failure rate control

### Aircraft State Control
- Teleport to any lat/lon/alt/heading
- Set airspeed
- Set flight phase
- Freeze / unfreeze simulation
- Reset to initial conditions

### Weather Control
- Wind direction / speed / gust
- Visibility (meters/RVR)
- Ceiling (ft)
- Temperature (OAT/dewpoint)
- Runway condition (dry/wet/contaminated/icy)
- Turbulence level
- Windshear injection

### Traffic Control
- Add/remove AI traffic
- Configure TCAS threats (TA/RA)

### Performance Monitoring
- Real-time aircraft state
- Deviation alerts (alt/speed/heading)
- Active failure list
- ECAM status

### Session Recording
- Start/stop/pause recording
- 4 Hz state snapshot rate
- Full event log
- Upload to Supabase

### Debriefing
- Load session recording
- Replay at 0.25× to 8× speed
- Annotate events
- Export session report (PDF)

---

## RECORDING SYSTEM

Record:
- Full aircraft state (4 Hz snapshots)
- Pilot inputs (sidestick, rudder, throttle, brake, gear, flaps)
- FCU inputs (knob/button actions)
- MCDU inputs (keystrokes, LSK selections, scratchpad)
- Failure injections and clearances
- AP/FD mode changes (FMA changes)
- Navigation events (waypoint transitions, direct-to)
- ECAM warnings and acknowledgements
- Instructor commands (position resets, weather changes)
- Session metadata (student, instructor, scenario, aircraft)

Enable:
- Full replay (seek, speed control)
- Debrief annotation
- Automated assessment
- Export to Supabase

---

## ANALYTICS

Provide:

| Metric | Method |
|--------|--------|
| Flight Path Analysis | Cross-track error vs planned route |
| Altitude Compliance | Deviation from assigned altitude (±100 ft tolerance) |
| Speed Compliance | Deviation from managed/selected speed (±10 kt tolerance) |
| Fuel Efficiency | Actual vs predicted fuel burn per waypoint |
| Approach Stability | 1000 ft gate: speed ±10 kt, config correct, descent ≤1000 ft/min |
| Checklist Compliance | Items completed in sequence, none skipped |
| Failure Response | Time from failure onset to correct first action |
| Procedure Compliance | Actions matched against SOP sequence |
| Training Progress | Per-student score history, weak area identification |
| Student Progress | Module completion, time-on-task, trend analysis |

---

## MULTIPLAYER ARCHITECTURE

Future-ready network architecture:

### Roles:
- **Instructor** — full control of simulation, failure injection, monitoring
- **Student** — cockpit operator, follows procedures, receives grading
- **Observer** — read-only view of any display, no interaction

### Transport:
- LAN (local network — zero-latency)
- Cloud (via Supabase Realtime / WebSocket relay)
- Enterprise (organization-managed server)

### Sync Protocol:
- Aircraft state sync: 4 Hz
- Events (failures, mode changes): immediate
- Commands (instructor → student): immediate
- Heartbeat: 1 Hz

---

## SUPABASE ARCHITECTURE

Design airline-grade schema supporting:

**Organizational Layer:**
- Organizations (airlines, ATOs, universities, OEMs, training centers)
- User organization membership and roles
- Fleet aircraft (registration, tail number, engine variant)

**User Layer:**
- Users with roles (admin, instructor, student, examiner, observer, ATO admin)
- Type ratings
- Medical expiry
- Organization membership

**Content Layer:**
- Scenarios (with initial conditions, objectives, scheduled failures)
- Checklists and procedures
- Failure definitions (persistent catalogue)
- Aircraft configurations

**Training Layer:**
- Training sessions (linked to student, instructor, scenario, mode)
- Session recordings (binary file + metadata)
- Session events (full event log)
- Assessments (per-category scores, deviations, feedback)
- Certificates (module completion, type rating prep, proficiency check)
- Performance metrics (per-session analytics)

**Navigation Layer:**
- Airports, runways, navaids, waypoints, airways
- SIDs, STARs, approaches
- AIRAC cycles (with effective dates, checksums)
- All nav data linked to AIRAC cycle

**Target: 36+ tables with full RLS policies**

---

## COMPLIANCE REFERENCES

Design architecture referencing:

### ARINC Standards
- **ARINC 424** — Navigation database format
- **ARINC 429** — Avionics data bus (conceptual label mapping)
- **ARINC 653** — Partitioned OS (thread isolation analogy)
- **ARINC 661** — Cockpit display standard (widget architecture)
- **ARINC 664** — AFDX (future multi-host network reference)
- **ARINC 702A** — FMS functional standard

### FAA References
- AC 120-45A — Flight Training Device criteria
- AC 120-40B — Full Flight Simulator criteria (reference only)

### EASA References
- CS-FSTD(A) — Flight Simulation Training Device criteria
- FTD Level 4 target (primary)
- FTD Level 5 stretch goal

### Airbus References (Conceptual)
- Airbus FCOM (Flight Crew Operating Manual)
- Airbus FCTM (Flight Crew Techniques Manual)
- Airbus QRH (Quick Reference Handbook)
- AMM (Aircraft Maintenance Manual — reference only)

### Software Standards (Design Patterns Only — Not Certified)
- DO-178C (DAL D patterns: traceability, determinism, no heap in sim loop)
- DO-254 (hardware reference only)
- MISRA C++:2023 (static analysis target)
- JSF AV C++ Rules (safety-critical coding rules)

> **IMPORTANT**: This platform does NOT claim DO-178C certification.
> It is designed with **certification-readiness patterns** for traceability alignment.

---

## 20 REQUIRED DELIVERABLES

| # | Deliverable | Architecture Doc | Status |
|---|-------------|-----------------|--------|
| 1 | Complete system architecture | `02_SYSTEM_ARCHITECTURE.md` | ✅ |
| 2 | Complete Supabase schema | `09_SUPABASE_SCHEMA.md` | ✅ |
| 3 | Entity relationship diagrams | `09_SUPABASE_SCHEMA.md` (text ERD) | ⚠️ Needs visual |
| 4 | Data flow diagrams | `10_DATA_FLOW_API.md` | ✅ |
| 5 | Aircraft state model | `03_AIRCRAFT_STATE_MODEL.md` | ✅ |
| 6 | Instructor architecture | `07_TRAINING_INSTRUCTOR.md` | ✅ |
| 7 | Training architecture | `07_TRAINING_INSTRUCTOR.md` | ✅ |
| 8 | Avionics architecture | `05_AVIONICS_AUTOPILOT.md` | ✅ |
| 9 | Failure architecture | `08_FAILURE_MANAGEMENT.md` | ✅ |
| 10 | Navigation architecture | `04_FMS_NAV_ARCHITECTURE.md` | ✅ |
| 11 | API architecture | `10_DATA_FLOW_API.md` | ✅ |
| 12 | Communication architecture | `10_DATA_FLOW_API.md` (§6) | ⚠️ Needs expansion |
| 13 | Multi-user architecture | `07_TRAINING_INSTRUCTOR.md` (§5) | ✅ |
| 14 | Migration roadmap | `11_IMPLEMENTATION_ROADMAP.md` + `12` (§6) | ✅ |
| 15 | Gap analysis | `01_GAP_ANALYSIS.md` | ✅ |
| 16 | Missing modules report | Implicit in `01` — needs explicit doc | ❌ Missing |
| 17 | Priority implementation roadmap | `11_IMPLEMENTATION_ROADMAP.md` | ✅ |
| 18 | Technical debt report | `01_GAP_ANALYSIS.md` (§3) | ⚠️ Partial |
| 19 | Certification-readiness report | `12_COMPLIANCE_READINESS.md` | ✅ |
| 20 | Airline-grade product architecture | Distributed across all 12 docs | ⚠️ No single doc |

---

## COVERAGE GAP SUMMARY

Topics from this prompt **not fully addressed** in existing Architecture docs:

| Gap | Severity | Notes |
|-----|----------|-------|
| ADF (Automatic Direction Finder) | 🟡 Medium | Mentioned in avionics list but no logic/arch defined |
| MLS (Microwave Landing System) | 🟡 Medium | Listed but not architected |
| Throttle Quadrant (dedicated section) | 🟡 Medium | Detents in doc 05, no standalone throttle doc |
| Visual ERD diagrams | 🟡 Medium | Text ERD exists in doc 09; no Mermaid/visual diagram |
| Missing Modules Report (explicit) | 🟡 Medium | Implied by gap analysis, not a formal report |
| Technical Debt Report (standalone) | 🟡 Medium | §3 of doc 01, not a dedicated document |
| Airline-Grade Product Doc (single) | 🟡 Medium | Distributed across 12 docs, no single summary |
| Communication Architecture (ARINC 429) | 🟢 Low | §6 of doc 10 maps labels; needs expansion |
| API rate limits, versioning, auth tokens | 🟢 Low | REST API listed in doc 10, no implementation detail |
| ECAM advisory/caution/warning colour rules | 🟢 Low | Doc 06 mentions colours but no formal table |
| Cargo smoke / lav smoke failures | 🟢 Low | Doc 08 omits fire failures beyond engine/APU |
| Landing gear failures (asymmetric) | 🟢 Low | Not in doc 08 catalogue |

---

*This document serves as the authoritative requirements specification. All implementation work should be traceable back to sections herein.*

---

## APPENDIX A — REFERENCE KNOWLEDGE BASE (From Forensic Analysis)

> **Source**: Complete forensic analysis of Reference/ directory — June 2026
> **Full Report**: `Reference_Forensic_Report.md`

### A.1 Validated Algorithm Sources

#### Fuel Prediction (A320-family-dev — FMGC.nas)
Polynomial regression models validated against FCOM performance data:
```
trip_fuel = 6th-order polynomial(dist_nm, crz_fl) — corrected for landing weight and temperature
final_fuel = final_time_min × 2 × fuel_flow_rate(zfw)
extra_fuel = block - trip - min_dest_fob - taxi - rte_rsv
```
Implement in: `PerformanceEngine::computeTripFuel()` and `computeFuelPolicy()`

#### FMGC 7-Phase State Machine (A320-family-dev)
```
PREFLIGHT(0) → [N1≥85% & GS≥90kt] → TAKEOFF(1)
TAKEOFF(1)   → [SRS ended & airborne] → CLIMB(2)
CLIMB(2)     → [ALT CRZ captured] → CRUISE(3)
CRUISE(3)    → [dist≤200nm OR altSel↓] → DESCENT(4)
DESCENT(4)   → [decel point] → APPROACH(5)
APPROACH(5)  → [TOGA×2] → GO_AROUND(6)
GO_AROUND(6) → [alt≥accel_ft] → CLIMB(2)
```
Implement in: `FMGCController::FlightPhase` enum + `masterFMGCLoop()`

#### FADEC Detent Enumeration (A320-family-dev — fadec-common.nas)
| Detent | ID | FMA Text | A/THR Effect |
|--------|-----|---------|-------------|
| IDLE | 0 | — | Disengage soft |
| MAN | 1 | MAN | No A/THR |
| CL | 2 | THR CLB | A/THR managed |
| MAN_ABOVE_CL | 3 | MAN THR | Manual above |
| MCT/FLX | 4 | THR MCT/FLX | Flex if active |
| MAN_ABOVE_MCT | 5 | MAN THR | Manual |
| TOGA | 6 | THR TOGA | Engage A/THR |

#### Vapp Formula (validated against FCOM DSC-22-40)
```cpp
vapp = vls + max(5.0, headwindComponent);
headwindComponent = clamp(destWindComponent / 3.0, 0.0, 15.0);
gsMini = vapp; // not less than Vapp
```

#### 3-Plan Flight Plan Architecture
```
flightplans[0] = TEMPORARY plan A (editing buffer)
flightplans[1] = TEMPORARY plan B (secondary editing)
flightplans[2] = ACTIVE plan (executing)
```
TMPY flag per slot. Commit: clone slot[n] → slot[2] → activate.

### A.2 Validated Failure Catalogue (from fail.xml)

**Exact count: 47 failures** across 6 categories. All captured:

**FCTL System (12)**: `fctl/elac1`, `fctl/elac2`, `fctl/sec1`, `fctl/sec2`, `fctl/sec3`, `fctl/fac1`, `fctl/fac2`, `fctl/rtlu-1`, `fctl/rtlu-2`, `fctl/ths-jam`, `fctl/yaw-damper-1`, `fctl/yaw-damper-2`

**Pneumatic (9)**: `pneumatics/bleed-1-valve`, `pneumatics/bleed-2-valve`, `pneumatics/hp-1-valve`, `pneumatics/hp-2-valve`, `pneumatics/hot-air-valve`, `pneumatics/ram-air-valve`, `pneumatics/pack-1-valve`, `pneumatics/pack-2-valve`, `pneumatics/x-bleed-valve`

**Hydraulic (8)**: `hydraulic/blue-leak`, `hydraulic/blue-elec`, `hydraulic/green-leak`, `hydraulic/green-edp`, `hydraulic/yellow-leak`, `hydraulic/yellow-edp`, `hydraulic/yellow-elec`, `hydraulic/ptu`

**Electrical (6)**: `electrical/ac-ess-bus`, `electrical/apu`, `electrical/dc-ess-bus`, `electrical/emer-gen`, `electrical/gen-1`, `electrical/gen-2`

**Fuel (6)**: `fuel/left-tank-pump-1`, `fuel/left-tank-pump-2`, `fuel/center-tank-pump-1`, `fuel/center-tank-pump-2`, `fuel/right-tank-pump-1`, `fuel/right-tank-pump-2`

**Fire (6)**: `fire/cargo-aft-fire`, `fire/cargo-fwd-fire`, `fire/lavatory-fire`, `fire/engine-left-fire`, `fire/engine-right-fire`, `fire/apu-fire`

**Additional failures defined in electrical.nas (NOT in fail.xml UI) — add to our FailureEngine:**
`electrical/idg-1`, `electrical/idg-2`, `electrical/stat-inv`, `electrical/tr-1`, `electrical/tr-2`, `electrical/ess-tr`, `electrical/ac-1-bus`, `electrical/ac-2-bus`, `electrical/dc-1-bus`, `electrical/dc-2-bus`, `electrical/dc-bat-bus`
→ Total FailureEngine catalogue: **58 failures**

### A.3 Electrical Bus Topology (from electrical.nas)

```
AC Sources: IDG1, IDG2, APU GEN, EXT PWR, EMER GEN, Static INV
AC Buses:   AC1, AC2, AC ESS, AC ESS SHED
DC Sources: TR1, TR2, ESS TR, BAT1, BAT2
DC Buses:   DC1, DC2, DC BAT, DC ESS, DC ESS SHED, DC HOT 1, DC HOT 2
Relays:     GLC1, GLC2, APU GLC, EXT EPC, AC BUS TIE 1/2, DC BAT TIE, ESS TR CONTACTOR
```
Key logic: FMGC1 powered from AC1 → AP1 disconnects if AC1 fails. FMGC2 from AC2.

### A.4 Hydraulic Braking Cascade (from hydraulics.nas)

```
Mode 1 (Normal):    Green ≥2500 psi → Normal BSCU braking
Mode 2 (Alternate): Green <2500 → Yellow ≥2500 + NWS + DC power → Alt braking with antiskid
                    Yellow ≥2500 + NO NWS → 1000 psi fixed (no antiskid)
Mode 0 (Emergency): Yellow <2500 → Accumulator (starts at 3000 psi, depletes 200 psi/application)
```
PTU: activates when |Green - Yellow| > threshold and EDP demand exists.

### A.5 Key Reference Library

| Need | Best Reference | Location |
|------|---------------|---------|
| FCOM procedures | Airbus FCOM Feb 2024 | FMS-Work/FMS Docs/FCOM_21 Feb 2024.pdf |
| Normal checklists | A320 normal procedures | FMS-Work/FMS Docs/a320-normal-procedures.pdf |
| Abnormal procedures | A320 abnormal notes | FMS-Work/FMS Docs/a320-abnormal-notes.pdf |
| ICAO approach procedures | ICAO Doc 8168 Vol I | FMS-Work/FMS Docs/ICAO-Doc-8168-Volume-I.pdf |
| FTD certification criteria | FAA AC 120-40B | FMS-Work/FMS Docs/120-40B1.pdf |
| FMGC/MCDU algorithms | A320-family-dev Nasal | Reference/A320-family-dev/Nasal/ |
| ARINC 424 parsing | ARINC424Parser | Reference/FMS-Work/.../FMS_pending/ |
| Flight dynamics | JSBSim | Reference/FMS-Work/.../FMS_pending/jsbsim-master/ |
| Performance tables | OpenAP | Reference/FMS-Work/.../FMS_pending/openap-master/ |
| Qt instruments | QFlightinstruments | Reference/FMS-Work/.../FMS_Frontend/ |

### A.6 Technology Decision Record

**Why C++/Qt over React/TypeScript** (validated by forensic analysis):
- React FMS (A320-fms-master) violates "Aircraft First" — Zustand store in JS is the aircraft state
- 60Hz physics in a React hook is non-deterministic (GC pauses, React batching)
- No path to multi-thread isolation in single-threaded JavaScript
- Qt 6 enables: QML hot-reload, hardware rendering, 4-thread architecture, direct C++ physics
- C++20 enables: concepts, coroutines, `std::jthread` for deterministic threading

**JSBSim Integration Strategy**:
- Do NOT embed JSBSim directly (LGPL complication + 347 files)
- Extract atmospheric model (ISA equations) — clean-room implementation
- Extract aerodynamic coefficient concept — build own A320 aero tables
- Reference JSBSim FDM architecture for 6-DOF EOM structure

**OpenAP Performance Data Strategy**:
- openap-master contains A320 BADA-like drag polars and fuel burn tables (MIT license)
- Extract `openap/data/aircraft/A320.json` performance parameters
- Convert to C++ constexpr lookup tables in `A320PerformanceTables.hpp`
