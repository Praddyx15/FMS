# IMPLEMENTATION PLAN — A320neo / CFM LEAP-1A FMS Trainer (SOLE TRUTH)

> **This is the single authoritative implementation plan.** Requirements authority:
> `Target_work.md`. Design authority: `Architecture/` docs 00–15. Reference index:
> `Reference_Forensic_Report.md`. All other plan/progress documents have been merged
> into this file and removed.
>
> **Maintenance protocol**: when a phase completes, mark it ✅ in §3, delete its task
> detail (keep the one-line summary + completion date), and remove any scratch/progress
> files it produced. Keep the workspace clean — this file is the only living tracker.
>
> **Design authority (never invert)**: Aircraft First → Systems Second → Training
> Third → UI Fourth. **Local-first**: no Supabase/cloud/network until Phase 9.

Consolidates (2026-07-02 sweep of all 26 project docs): `Target_work.md` (requirements,
Appendix A validated algorithms) · `Architecture/11_IMPLEMENTATION_ROADMAP.md` (10-phase
plan) · `Architecture/13_MISSING_MODULES_REPORT.md` (coverage additions) ·
`Reference_Forensic_Report.md` (algorithm sources & licensing) · PROGRESS.md (React→Qt
port record — done; engineering constraints preserved in §1) · walkthrough.md /
current_status_review.md (status snapshots — superseded by §2) · June-11 plan +
IMPLEMENTATION_PLAN_PHASE2.md (merged here).

---

## 1. ENGINEERING CONSTRAINTS (permanent — apply to all phases)

### 1.1 QML rendering / memory (hard-won; violating these re-introduces multi-GB leaks)
- `qputenv("QSG_RENDER_LOOP", "basic")` stays first in `main()`. QtQuick Canvas leaks
  native backing buffers under the threaded render loop.
- **Never** host canvas-bearing panels in `ScrollView` — use `Flickable` + `WheelHandler`.
- In Canvas `onPaint`: no `ctx.setLineDash()` (draw manual segments), no `ctx.reset()`
  (use `clearRect`) — both leak at high frequency.
- Repaint rates stay throttled: sim tick 80 ms (12.5 Hz); ND canvas 10 Hz.
- **No periodic `gc()` timers** — forcing collections blocks V4's major sweep and turns
  the bounded sawtooth (~1.6 GB spike → ~310 MB steady) into an unbounded climb.
- Steady-state memory ~310 MB is normal; judge leaks only with the window foregrounded
  (occluded windows don't repaint and give flat false readings).
- A leaked multi-GB process holds the `FmsFrontend.dll` lock for minutes → build fails
  "Permission denied". Kill + poll for write access before building.
- 30+ Hz fidelity requires Canvas → `QQuickPaintedItem`/QSGNode migration (Phase 10) —
  keep `QSG_RENDER_LOOP=basic` regardless.

### 1.2 QML architecture
- `QApplication` (not `QGuiApplication`) — Qt Charts segfaults otherwise;
  `QQuickStyle::setStyle("Basic")` required for control customization.
- `MainLayout.qml` uses a `Loader` (never eager `StackLayout` of all views).
- Never bind `Layout.preferredWidth/Height` to `parent.width/height` when the parent is
  itself a Layout (recursive rearrange → GUI freeze); bind to the outer non-layout root.
- UI never computes aircraft state — QML reads Q_PROPERTY and sends commands only.
- Backend types live in imperative module `FmsBackend`; pure-QML module is `FmsTrainer`
  (same URI for both breaks qmldir resolution).
- Qt6 only — no Qt5 types (`RegExpValidator` broke app startup silently, fixed 07-02).

### 1.3 Safety-critical C++ (DO-178C-pattern; see doc 12 §2)
- No heap allocation in the sim loop (pre-allocated `std::array` + count).
- `safeDiv` (|den| ≥ 1e-7), `safeSqrt` (clamp ≥ 0), NaN/Inf guards on physics outputs.
- Physical clamps: alt [0, 41000] ft, IAS [0, 450] kt, pitch ±30°, roll ±67°.
- Fixed-interval ticks; new backend code uses type-safe units (`Core/Units.hpp`, Phase 1).
- License rules (forensic report Part 8): A320-family-dev & littlenavmap are GPL —
  **algorithms only, no code copy**. MIT/Apache OK to adapt: ARINC424Parser, openap,
  BasicFMC, hopsan. JSBSim/QFlightinstruments: LGPL, dynamic link only.

### 1.4 Build & verify
- Project root: `Frontend QML_Qt/FMS_Qt`; build: `cmake --build build`;
  outputs `build/FmsTrainer.exe`, `build/FmsTests.exe`. QML compiles into
  `FmsFrontend.dll` (exe size unchanged by QML-only edits).
- Console logging from the GUI exe: `QT_FORCE_STDERR_LOGGING=1` +
  `QT_ASSUME_STDERR_HAS_CONSOLE=1`, redirect stderr.
- Every phase ends with: gtest suite green, warning-free QML smoke run, and the
  scripted EDDF→LFPG reference flight compared (PROG / FUEL PRED deltas).
- Traceability: commits cite the `Target_work.md` section implemented.

## 2. VERIFIED BASELINE (2026-07-02 code audit — do not redo)

| Item | Status |
|---|---|
| C++20 (`CMakeLists.txt:5`), `kTmax = 132000` | ✅ done |
| Legacy `c:/Users/akass/` paths removed; nav DB resolves repo-relative (`FMS_ARINC_DB` overrides) | ✅ done 07-02 |
| GoogleTest wired (`FmsTests.exe`, ISA/parser tests exist) | ✅ extend, don't create |
| ARINC 424 CIFP parse — real, 4,383 fixes (waypoints/airports only) | ✅ (records beyond fixes: Phase 4) |
| App launches clean; Qt6 `RegExpValidator` regression fixed | ✅ done 07-02 |
| React→Qt port: Theme, ECAM 12 SD pages, 31 MCDU pages + panel, FCU, ND 5 modes + overlays, 6 analog instruments, PFD/tapes, split view | ✅ done (June) |
| June handover: ADI square/bezel, ECAM SD live bindings, MCDU key layout, split-view scaling | ✅ done |

Still true: `FMSComputer` = scratchpad + INIT/F-PLN/PERF/PROG/RAD NAV/DATA LSKs only;
AP = basic HDG/ALT/VS PID; engine = 1st-order N1, linear EGT; OHP = 3-toggle stub;
ECAM values partly constant; no ground model; no training framework; no recording.
Known cosmetic: `ThrottleQuadrant.qml:56` undefined-bool warning.

## 3. EXECUTION PHASES (from doc 11, + doc 13 additions, + Appendix A bindings)

Priorities: 🔴 P0 blocking · 🟡 P1 important · 🟢 P2 stretch.
Critical path: **1 → 2/3 → 4 → 5**; 6–8 build on 2–5; 9 deferred; 10 trails all.

### Phase 1 — Foundation Refactoring 🚧 IN PROGRESS (mostly done 2026-07-02)
- ✅ Decomposed `AirDataComputer` → `EngineModel`, `AutopilotController`,
  `FlightControlLaws` (physics/speed-protection stay in the façade until Ph2/4);
  QML property surface unchanged; behavior-preserving (07-02).
- ✅ `Core/Units.hpp` type-safe units + literals; use in all new code (07-02).
- ✅ Linux build path (windeployqt already `WIN32`-guarded) (07-02).
- ✅ Test suite extended to 10 suites incl. EngineModel/AutopilotController/
  FlightControlLaws/Units; ARINC test path fixed to repo-relative (07-02).
- 🔴 REMAINING: restructure `FlightDataManager` → channel-shaped `FlightDataBus`
  (AircraftState / AvionicsState / SystemsState / TrainingState — doc 02 §4),
  preserving the `FmsBackend` singleton registration for QML. Do this together
  with the Phase 2 `SystemsManager` design — the systems channel defines the split.
- Note (found during decomposition): legacy quirk preserved — an engine fire on
  ONE engine inhibits the normal spool update for BOTH engines. Fix in Phase 3
  when engines become independent.

### Phase 2 — Aircraft Systems ("every switch drives real state")
- 🔴 `SystemsManager`: hydraulics (G/B/Y pressure, pumps, PTU on |ΔP|, braking cascade
  per Appendix A.4: Normal ≥2500 psi → Alternate+antiskid → Accumulator 3000 psi
  −200/application); electrical (Appendix A.3 topology: IDG1/2, APU GEN, EXT, EMER,
  STAT INV; AC1/2/ESS/SHED, TR1/2/ESS, BAT1/2, DC buses, contactors — FMGC1 on AC1 ⇒
  AP1 drops with AC1); fuel (5 tanks, 6 pumps, crossfeed, burn from FF).
- 🟡 Pneumatic (bleeds, X-bleed, packs), pressurization (cabin alt, outflow, ditching),
  fire protection (loops, squibs, agents).
- 🔴 ADIRS: OFF→ALIGN(≤600 s)→NAV, ADR at ~90 s, ATT degraded mode (doc 05 §1.2-1.3).
- 🔴 OverheadPanel.qml: all 12 sections (doc 06 §4) wired switch-by-switch — no
  decorative switches.
- 🔴 ECAM SD pages read `SystemsManager` (replace remaining constants: oil, vib,
  PSI/QTY, PTU, bus voltages).

### Phase 3 — Engine & Ground Model (LEAP-1A)
- 🔴 `EngineModel`: N1+N2 spool dynamics (τ 1–4 s), EGT lookup w/ thermal lag, FF,
  oil, vibration; start sequence (fuel at ~22% N2, EGT peak); thrust
  `T_max·σ(alt)·f(Mach)·g(N1)`; constants per doc 03 §2 (TOGA 132 kN, MCT 118 kN,
  N1 idle 19.5%, EGT limits 1083/1043 °C — see §5.1 discrepancy).
- 🔴 `ThrottleQuadrantModel` (doc 13 §2.2): detents per Appendix A.1 (IDLE 0°/CL 25°/
  MCT-FLX 35°/TOGA 45°/REV −5..−20°), A/THR engage rules, speed-brake lever + ARMED
  auto-deploy, flap handle → config, gear lever + LGCIU, autobrake selector, parking
  brake, reverse interlock (ground only).
- 🔴 `GroundModel`: WoW, gear compression, μ table (dry/wet/icy), braking + autobrake
  decel targeting, NWS ±75° tiller / ±6° pedal, crosswind on ground.
- 🟡 Ground spoilers, reverse thrust; 🟢 gear transit animation.

### Phase 4 — FMS & Navigation (ARINC 702A-conceptual)
- 🔴 Extend `ArincParser`/`NavigationDatabase`: runways (PG), navaids (D/DB), ILS (PI),
  SID/STAR/approach legs (PD/PE/PF — IF/TF/CF/DF first), airways (ER), holdings;
  per-airport keyed maps; QML accessors (`runwaysFor`, `sidsFor`, `starsFor`,
  `airwayBetween`, `nearestVors`). Reference: ARINC424Parser-master (MIT).
- 🔴 `FlightPlanManager`: 3-plan slots {TMPY-A, TMPY-B, ACTIVE} per Appendix A.1;
  leg model with A/B/C alt + speed constraints, overfly, discontinuities; SID/STAR/
  approach splice; DIR TO; SEC F-PLN ops (copy/activate).
- 🔴 FMGC 7-phase state machine per Appendix A.1 (PREFLIGHT→…→GO_AROUND on TOGA×2),
  replacing ad-hoc phase strings.
- 🔴 `PerformanceEngine`: V1/VR/V2 (TOW/config/runway/wind/OAT), FLEX, VLS/Green Dot/
  F/S from weight, **Vapp = VLS + clamp(headwind/3, 5, 15)** (Appendix A.1); CI →
  ECON speeds; trip-fuel polynomials (Appendix A.1) calibrated against openap A320
  tables (MIT) → `A320PerformanceTables.hpp` constexpr.
- 🔴 TOC/TOD; 🟡 `PredictionEngine` ETA/DTG/EFOB per waypoint @1 Hz; airway route entry.
- 🟢 AIRAC dual-cycle management; HOLD / OFFSET / FIX INFO pages.

### Phase 5 — Autopilot & FBW
- 🔴 Lateral: HDG/TRK, NAV (XTK + turn anticipation + leg sequencing), LOC, RWY,
  GA TRK; 🔴 Vertical: ALT/ALT*/ALT CRZ/ALT CST, CLB/DES (VNAV profile), OP CLB/DES,
  VS/FPA, GS/GS*, FINAL/FLARE, SRS; 🟡 EXPEDITE, TCAS mode (with Phase 7/13 TCAS).
- 🔴 A/THR: SPEED/MACH, THR CLB/MCT/IDLE, THR LVR, A.FLOOR/TOGA LK, RETARD.
- 🔴 Arm→capture→engage transitions (doc 05 §2.2); FMA 5-column w/ armed modes + colors.
- 🟡 Normal Law (C*, protections), alpha floor; 🟢 Alternate/Direct law degradation.

### Phase 6 — Training Framework
- 🔴 `TrainingModeFramework`: 12-mode matrix exactly per doc 07 §1.2-1.3 (per-mode
  sim/MCDU/FCU/OHP/failures/grading flags, hints, freeze-on-error).
- 🔴 Mode 3 (guided MCDU exercises + step validation), Mode 6 (SOP checklist +
  auto-grading — replaces CockpitSplitView stub), Mode 12 (instructor-led).
- 🟡 Modes 7/8 (failure+QRH), Mode 10 (instrument procedures).
- 🟡 `RecordingEngine`: 4 Hz snapshots + full event log (doc 07 §3.2) to local files;
  `AssessmentEngine` tolerances: alt ±100 ft, spd ±10 kt, hdg ±5°, XTK 2.5 NM,
  LOC/GS ±0.5 dot, TD VSI ≤600 fpm, 1000-ft stabilized gate.
- 🟢 Replay 0.25–8×; Modes 1/2/11.

### Phase 7 — Failure Engine
- 🔴 `FailureEngine` (replaces InstructorEngine's flat list): progressions
  IMMEDIATE/PROGRESSIVE/INTERMITTENT/LATENT; triggers MANUAL/SCHEDULED/CONDITIONAL/
  RANDOM; cascades computed through `SystemsManager` (ENG1 flameout → GEN1 → Hyd G
  decay → Pack 1 → yaw, doc 08 §3).
- 🔴 Catalogue: the **58 IDs of Appendix A.2** (47 fail.xml + 11 electrical.nas) PLUS
  doc-13 §2.1 additions: gear (door unsafe, asymmetric, gravity ext, LGCIU1, NWS,
  retract fail), fire (FWD/AFT cargo, lav, avionics), comms (VHF1/2, ACARS, SELCAL,
  HF1) → **~73 total**, stored as data.
- 🔴 FWC/ECAM integration: QRH-worded caution/warning lines, master caution/warning,
  SD auto page-call, memo/status, memory-item flag.
- 🟢 Random per-flight-hour + conditional triggers.

### Phase 8 — Instructor Station & Analytics
- 🔴 Scenario CRUD (local JSON) + prebuilt library (cold-and-dark, ready-for-taxi,
  TOD, single-engine cruise) via `startScenario`.
- 🟡 Position teleport / freeze / reset; weather control (wind/gust, vis, ceiling,
  OAT/dewpoint, runway condition, turbulence, windshear); deviation dashboard.
- 🟡 Debrief from recordings; analytics per Target_work metric table.
- 🟢 Traffic/TCAS threats; progress trends; PDF export.

### Phase 9 — Multi-User & Enterprise (DEFERRED — design only, local-first)
No Supabase/WebSocket implementation. Keep bus message-shaped for future 4 Hz sync
(doc 07 §5, doc 10 §5); doc 09 schema stays the design reference. Revisit after Phase 8.

### Phase 10 — Display Fidelity (continuous; trails backend phases)
- 🔴 PFD 5-column FMA colors/armed (w/ Ph5); speed-tape bands VLS/αprot/αmax/VMO/VFE +
  V-bugs from live `PerformanceEngine` (w/ Ph4).
- 🟡 Cyan alt target, metric alt, radio altimeter <2500 ft (needs Ph3 AGL), ND CSTR +
  ARPT overlays, TOC/TOD pseudo-waypoints, ILS readout; ECAM upper E/WD (w/ Ph2/3/7).
- 🟢 Canvas → QQuickPaintedItem 30 Hz migration (per §1.1); fix ThrottleQuadrant warning.

### Cross-phase additions from doc 13 (schedule with the phase noted)
ADF receivers + ND pointers (Ph4/5) · GNSS position solution + RAIM/RNP + nav-mode
degradation GPS→IRS→DME-DME→VOR-DME (Ph4) · TCAS TA/RA computation (Ph7/8) · EGPWS
modes 1–6 + simplified terrain grid (Ph7/10) · FAC detail: yaw damper, rudder travel
limit, low-energy warning (Ph5) · SEC detail: 5+5 spoilers, speedbrake mix, ground
spoilers, pitch backup (Ph3/5) · MLS 🟢 (last — rare fitment).

## 4. MILESTONES

| # | Milestone | Phases | Demonstrable outcome |
|---|-----------|--------|---------------------|
| M1 | Refactored core | 1 | Same behavior, modular backend, tests green |
| M2 | Live systems | 2 | Every OHP switch + ECAM SD page state-driven |
| M3 | Full envelope | 3 | Cold-and-dark → start → taxi → takeoff → land |
| M4 | Real FMS | 4 | EDDF→LFPG w/ SID/STAR/TMPY; fuel prediction ±5% |
| M5 | Managed flight | 5 | Full AP/FD/A-THR set, correct 5-col FMA |
| M6 | Training product | 6–8 | Graded modes, ~73-failure engine w/ ECAM, instructor scenarios |

## 5. OPEN DISCREPANCIES (resolve with design authority)

1. **LEAP-1A rating**: docs standardize 132 kN TOGA (doc 03 §2) though a LEAP-1A26
   placard is ≈120.6 kN. Until re-decided, **132 kN per doc 03 is authoritative**;
   keep as data.
2. Failure count: doc 08 says "40+", Appendix A.2 says 58, doc 13 adds ~15 →
   **~73 (Appendix A.2 + doc 13) is authoritative**.
3. Doc 02 threading (4-thread) vs current single-threaded 80 ms QTimer: adopt threads
   only when profiling demands it; the channel-shaped bus (Ph1) is the prerequisite
   either way.

## 6. KEY REFERENCE POINTERS (full index: Reference_Forensic_Report.md Part 11)

FMGC phases/fuel polynomials: `Reference/A320-family-dev/Nasal/FMGC/FMGC.nas` (GPL —
algorithms only) · failure tree: `.../AircraftConfig/fail.xml` · elec/hyd/FADEC:
`.../Nasal/Systems/` · ARINC 424: `Reference/.../FMS_pending/ARINC424Parser-master`
(MIT) · perf tables: `.../openap-master` (MIT) · FCOM/procedures/ICAO 8168 PDFs:
`Reference/FMS-Work/FMS Docs/` · coding standards PDFs: `Coding standards/`.
