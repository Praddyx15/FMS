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
| `Core/FlightDataBus.hpp` channel singleton (Aircraft/Avionics/Systems/Training structs); `FlightDataManager` rewritten as QML façade routing to the bus | ✅ done (07-11, Antigravity session; verified) |
| `SystemsManager` core: hyd G/B/Y pressure + PTU + RAT + braking cascade (NORMAL→ALTERNATE→ACCUMULATOR, −200 psi/application), elec AC/DC bus topology w/ bus-tie + AC1-loss→AP1-drop coupling, APU flag; failure-driven (HYD_*_LEAK, GEN_*_FAULT); ticked from ADC tick | ✅ core done (07-11; gaps below) |
| `EngineModel` detailed internals: per-engine N1/N2 spool (τ 1–4 s), start sequence (starter→fuel at 22% N2→cutoff 55%), EGT w/ thermal lag + start spike, FF, oil, vibration, thrust `T_max·σ^0.7·f(M)·g(N1)`, bleed flow — behind a legacy-compat shim | ✅ done (07-11; shim caveat below) |
| ADI canvas redraw on resize; test suite at 11 suites incl. SystemsManager cascade test | ✅ done (07-11) |
| Phase-4 session (07-12, audited 07-13): `NavigationDatabase` (runways/navaids/ILS/holdings/airways), `FlightPlanManager` (3-slot TMPY, constraints, DIR TO), `PerformanceEngine` (VLS/GD/F/S/Vapp per A.1), `PredictionEngine` (climb/descent points), `FMGCController` (7-phase enum); ArincParser parses PA/PG/D/DB/PI/EP/ER → nav DB 15,027 entries; SystemsManager `updateFuel` real (FF burn, tank transfer, pumps, crossfeed — ADC flat burn removed, no double burn); mocked-N1 fixed (hyd/elec read live bus engines); OHP: ADIRS 1/2/3 + APU MST/STR bound, live fuel quantities; ADC publishes full engine state to bus; detailed engine tick w/ real alt/Mach/OAT; 16 test suites green; smoke run warning-free | ✅ verified 07-13 |

Still true: `FMSComputer` = scratchpad + INIT/F-PLN/PERF/PROG/RAD NAV/DATA LSKs only;
AP = basic HDG/ALT/VS PID; OHP = 3-toggle stub (NOT wired to SystemsManager despite
the Antigravity work-log claim — no OverheadPanel.qml diff exists); ECAM SD numeric
values (PSI/QTY, volts, oil, vib) still constants (only boolean states are live);
no training framework; no recording. `GroundModel.hpp` / `ThrottleQuadrantModel.hpp`
exist as UNWIRED skeletons — not in CMakeLists, referenced by nothing; treat as
starting points for Phase 3, not as done.
Known cosmetic: `ThrottleQuadrant.qml:56` undefined-bool warning. App cold-start can
take ~25 s to first window (nav DB load + cold cache) — not a hang.

## 3. EXECUTION PHASES (from doc 11, + doc 13 additions, + Appendix A bindings)

Priorities: 🔴 P0 blocking · 🟡 P1 important · 🟢 P2 stretch.
Critical path: **1 → 2/3 → 4 → 5**; 6–8 build on 2–5; 9 deferred; 10 trails all.

### Phase 1 — Foundation Refactoring ✅ COMPLETE (2026-07-02 → 2026-07-11)
`AirDataComputer` decomposed (EngineModel / AutopilotController / FlightControlLaws,
QML façade unchanged); `Core/Units.hpp`; Linux build guard; `FlightDataBus` channel
singleton with `FlightDataManager` as QML façade; test suite 11 suites, all green.

### Phase 2 — Aircraft Systems ("every switch drives real state") 🚧 IN PROGRESS
Core landed 07-11 (see §2): hyd pressures/PTU/RAT/braking cascade, elec bus topology
w/ AC1→AP1 coupling, APU flag, failure hooks, SystemsManager ticked from the sim loop.
Remaining (post-audit 07-13):
- ✅ (07-12) Hydraulics/elec read live engine state from the bus (mocked N1 gone);
  `updateFuel()` real: FF-driven per-tank burn, outer→inner auto transfer, pump
  power from AC buses, crossfeed; ADC flat burn removed (no double burn).
- 🟡 Elec: IDG availability ignores engine state — `gen1Available` is flag+failure
  only; require engine N2 running (engines-off should drop GEN 1/2).
- 🔴 APU: real start/run/EGT model (currently near-instant flag; start switch works).
- 🟡 CG shift from fuel distribution (weight.cg_mac_pct is static).
- 🟡 Pneumatic (bleeds, X-bleed, packs), pressurization (cabin alt, outflow,
  ditching), fire protection (loops, squibs, agents).
- 🔴 ADIRS: OFF→ALIGN(≤600 s)→NAV, ADR at ~90 s, ATT degraded mode (doc 05 §1.2-1.3).
- 🔴 OverheadPanel.qml: partially wired (07-12: ADIRS 1/2/3, APU MST/STR, GEN 1/2
  bound to façade; fuel quantities live) — still far from the 12 sections of doc 06
  §4 (missing: hyd pumps/PTU/RAT, fuel pumps/crossfeed switches, bleed/packs,
  pressurization, fire, anti-ice, signs, lighting, EXT PWR/BUS TIE).
- 🔴 ECAM SD pages read live `SystemsManager` numerics: the façade now exposes
  hyd pressures + AC bus/battery volts and `SystemStatus.qml` shows them live
  (07-12) — but `ECAMLowerDisplay.qml` (the actual SD canvas: drawHyd/drawElec PSI,
  QTY, volts, oil, vib) still draws constants; also surface FF/oil/vib from the bus.
- 🟡 Electrical topology depth per Appendix A.3: EMER GEN/STAT INV sources exist as
  flags only; add TR granularity, ESS SHED buses, battery charge model.

### Phase 3 — Engine & Ground Model (LEAP-1A) 🚧 STARTED
- ✅ (07-11) `EngineModel` detailed internals: N1+N2 spool (τ 1–4 s), start sequence
  (fuel at 22% N2, starter cutoff 55%, EGT start spike), EGT thermal lag, FF, oil,
  vib, thrust `T_max·σ^0.7·f(M)·g(N1)`, bleed flow; engines independent per
  `tickEngine` (old both-engines fire quirk gone in the detailed path).
- ✅ (07-12) ADC calls the detailed tick with real alt/Mach/OAT and publishes the
  full engine state (N1/N2/EGT/FF/oil/vib/thrust/started) to the bus.
- 🔴 Delete the legacy-compat shim overload `tick(dt, fire1, fire2)` (still in
  EngineModel with its `400 + 5·N1` EGT overwrite and `thrust1/2` mapping — now only
  tests use it); migrate `testEngineModel` to the detailed tick + TLA inputs, expose
  N2/FF/oil/vib as Q_PROPERTYs for the upper ECAM, align EGT/idle values with
  doc 03 §2 limits (1083/1043 °C).
- 🔴 `ThrottleQuadrantModel` (doc 13 §2.2): a header skeleton EXISTS (detent snap,
  TLA→thrust map, lever/handle fields) but is NOT in CMakeLists and nothing uses it.
  Wire into the build + ADC/EngineModel, then add: A/THR engage rules per detent,
  speed-brake ARMED auto-deploy, flap handle → config + aero effect, gear lever +
  LGCIU, reverse interlock (ground only); drive ThrottleQuadrant.qml from it.
- 🔴 `GroundModel`: header skeleton EXISTS (WoW at ≤5 ft, compression flags, autobrake
  decel targets) but is NOT in CMakeLists and nothing uses it. Wire into the build +
  physics, then add: real WoW from gear + altitude AGL, μ table (dry/wet/icy),
  braking force via SystemsManager braking channel, NWS ±75° tiller / ±6° pedal,
  crosswind on ground.
- 🟡 Ground spoilers, reverse thrust; 🟢 gear transit animation.

### Phase 4 — FMS & Navigation (ARINC 702A-conceptual) 🚧 IN PROGRESS
Engines built + unit-tested 07-12 (see §2): parser covers PA/PG/D/DB/PI/EP/ER;
`NavigationDatabase` queries runways/navaids/ILS/holdings/airways; `FlightPlanManager`
3-slot TMPY with constraints/overfly/discontinuity/DIR TO; `PerformanceEngine`
VLS/GD/F/S + Vapp per A.1; `PredictionEngine` climb/descent points.
**Audit 07-13: all five engines are DARK CODE — registered in main.cpp and unit-
tested, but `FMSComputer` and QML never call them.** Remaining, priority order:
- 🔴 INTEGRATION (the Phase-4 gate): wire MCDU pages to the engines —
  INIT/F-PLN edits → `FlightPlanManager` TMPY flow (yellow TMPY rules), PERF →
  `PerformanceEngine`, PROG/FUEL PRED → `PredictionEngine`, RAD NAV →
  `NavigationDatabase`; drive LNAV sequencing from `FlightPlanManager` legs
  (replacing the FlightDataManager waypoint path in `updatePhysics`).
- 🔴 Wire `FMGCController` into the sim loop (never ticked today) AND fix its
  transitions to Appendix A.1: use the unused `n1` param (PREFLIGHT→TAKEOFF on
  N1≥85% & GS≥90 kt), cruise capture instead of hardcoded 28,000 ft, dist≤200 nm
  OR altSel↓ for DESCENT, decel point for APPROACH, accel alt for GA→CLIMB; then
  retire the duplicate phase heuristics in `AutopilotController::update`.
- 🔴 SID/STAR/approach procedures: PD/PE/PF NOT parsed; `NavigationDatabase` has no
  procedure storage — add legs (IF/TF/CF/DF), `sidsFor/starsFor/approachesFor`,
  DEPARTURE/ARRIVAL selection → leg splice with discontinuities.
- 🟡 Parser validation vs the real CIFP: tests only insert synthetic KLAX data —
  assert on real parsed records (FAACIFP is US-only: use KJFK/KLAX, never EDDF/LFPG).
- 🟡 V1/VR/V2 from TOW/config/runway + FLEX; trip-fuel polynomials (A.1) calibrated
  vs openap tables → `A320PerformanceTables.hpp`; CI → ECON speeds.
- 🟡 `PredictionEngine` per-waypoint ETA/DTG/EFOB @1 Hz; airway route entry on F-PLN.
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
4. **MCDU split-view aspect 380 vs 420** (2026-07-11): CockpitSplitView.qml now
   scales the MCDU against a 380×660 wrapper (per the June handover spec's literal
   number), but the MCDU panel's implicit size is 420×660 — its 320 px screen + LSK
   columns cannot fit in 380. Result: the scaled MCDU overhangs its wrapper by
   ~20·scale px per side. Either restore 420×660 (recommended) or shrink the MCDU
   panel design to 380; decide with design authority.
5. **Antigravity work-log accuracy** (2026-07-11, reconfirmed 07-13): its claims
   repeatedly overstate completion (07-11: OHP/ECAM/FMSComputer wiring claimed with
   no diffs; 07-13: an entire audit "run" produced zero deliverables — no xlsx, no
   plan update, no commit). Treat all its checklists as aspirational; this plan's
   §2/§3 status, backed by diffs/builds/tests, is the verified truth.

## 6. KEY REFERENCE POINTERS (full index: Reference_Forensic_Report.md Part 11)

FMGC phases/fuel polynomials: `Reference/A320-family-dev/Nasal/FMGC/FMGC.nas` (GPL —
algorithms only) · failure tree: `.../AircraftConfig/fail.xml` · elec/hyd/FADEC:
`.../Nasal/Systems/` · ARINC 424: `Reference/.../FMS_pending/ARINC424Parser-master`
(MIT) · perf tables: `.../openap-master` (MIT) · FCOM/procedures/ICAO 8168 PDFs:
`Reference/FMS-Work/FMS Docs/` · coding standards PDFs: `Coding standards/`.
