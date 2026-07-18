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
| Phase 2/3 session (07-16, audited same day): real pneumatics (`updatePneumatics`: bleed sources, cross-bleed AUTO/OPEN/OFF, pack-availability gating) + pressurization (`updatePressurization`: cabin alt/VSI/ΔP/outflow/ditching) with full FlightDataManager property surface; ECAM SD BLEED+PRESS pages now live; legacy `EngineModel` shim deleted + test migrated; `ThrottleQuadrantModel`+`GroundModel` added to CMake and ticked from `AirDataComputer` every frame (TLA→thrust, WoW→altitude clamp, autobrake→decel); CG-shift-from-fuel and ADIRS 7-min fast-align confirmed already present (plan corrected). Build/tests/smoke verified GREEN this session (pre-audit snapshot did not link — fixed same session) | ✅ verified 07-16 |
| Phase 3 continuation (07-16, same day, this session): closed the throttle-lever↔backend gap in both `ThrottleQuadrant.qml` and `Pedestal.qml` (the latter had a worse read/write domain-mismatch bug that made manual drag nearly unusable — fixed); implemented `ThrottleQuadrantModel::tick()` (speedbrake arm/auto-deploy/retract, A/THR detent arbitration, reverse interlock) and flap→VLS aero effect; wired `GroundModel` braking through `SystemsManager::getBrakingChannel()` with a μ (runway condition) table and rudder-pedal-driven NWS steering output; added `testThrottleQuadrantModel`+`testGroundModel` (18 suites total). Build/tests/smoke verified GREEN | ✅ verified 07-16 |

Still true: `FMSComputer` = scratchpad + INIT/F-PLN/PERF/PROG/RAD NAV/DATA LSKs only;
AP = basic HDG/ALT/VS PID; OHP = still only 3 of 12 doc-06 sections (unchanged since
07-12 — the 07-16 pneumatic/pressurization backend has no OHP UI yet); ECAM SD
numerics now partially live (elec/hyd/bleed/press) but eng oil/vib and fuel-flow
still constants; no training framework; no recording. `GroundModel`/
`ThrottleQuadrantModel` are wired into the build, the tick loop, AND both cockpit
UIs (ThrottleQuadrant.qml, Pedestal.qml) as of the 07-16 continuation — the
throttle-lever gap from §5 discrepancy 7 is closed; `RudderPedals.qml` has the
same class of gap now (backend NWS consumer exists, UI doesn't feed it).
App cold-start can take ~25 s to first window (nav DB load + cold cache) — not a hang.

## 2A. RECOMMENDED NEXT 3 SESSIONS (evidence-based, 2026-07-17 planning pass)

Produced from a fresh three-agent codebase audit (not the prior plan text) —
see the individual phase entries in §3 for full file:line evidence. Each
session is scoped to be independently startable in a new context: read this
block + the cited phase bullets, no other setup needed. Every session ends
with the standard gate from §1.4 (build clean, all tests pass, warning-free
smoke run) before commit+push.

**Session A — Display/UI wiring cleanup** (small, safe, zero backend risk;
everything needed already exists and is proven live elsewhere in the app):
1. `RudderPedals.qml` → `adc.rudderPedal` (Phase 3 bullet; copy the
   `Pedestal.qml`/`ThrottleQuadrant.qml` pattern).
2. `ECAM.qml` upper E/WD: replace hardcoded N2/FF/oil/vib/fuel/electrical/
   pneumatic literals with the live `adc`/`FlightDataManager` properties
   (Phase 10 bullet — full list of exact hardcoded values there).
3. `OverheadPanel.qml`: add the 4 backend-ready sections — BLEED, PACKS,
   PRESSURIZATION (ditching), ANTI-ICE (Phase 2 bullet).
Rationale: these three are the same bug class (real backend, unwired UI) found
and fixed for the throttle lever on 07-16/07-17 — closing them now prevents
the "looks done, isn't" trap from compounding further, and each is provably
low-risk because the data already flows correctly elsewhere in the same app.

**Session B — Failure-system unification** (correctness fix, do BEFORE any
failure-catalogue expansion): see Phase 7 §"CRITICAL DEFECT FOUND". Unify the
three disconnected failure-ID lists around one canonical scheme, repoint
`InstructorEngine`'s 16-ID catalogue, and prove it with an integration test
(inject → `SystemsManager::tick()` → real bus-state change), not another
isolated unit test. This is a correctness bug in an already-shipped-looking
feature (the Instructor Station UI calls real methods and looks functional),
not new-feature work — treat it as higher priority than catalogue growth.

**Session C — Phase 4 FMS integration** (the largest remaining strategic gap,
reconfirmed unchanged on 07-17): wire the five engines to `FMSComputer`/MCDU
per the existing Phase 4 plan below. Register `NavigationDatabase` to QML
first (currently the only one of the five not exposed at all). This is a
multi-session effort in its own right — Session C is the START of it, not a
single sitting.

Do NOT start Phase 5 (Autopilot/FBW modes), Phase 6 (Training Framework), or
Phase 8 (Instructor scenarios beyond the Session B fix) before Session C —
they all depend on Phase 4's real flight-plan/performance data to be
meaningful rather than cosmetic.

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
- ✅ (07-13) Elec IDG requires engine N2 > 50% (engines-off drops GEN 1/2); APU has
  a real spool model (N ramp ~10 s, EGT peak 650→settle 400 °C, shutdown decay);
  ADIRS OFF→ALIGN→NAV with ATT degradation implemented in `updateADIRS`.
- ✅ (07-16, audited/committed) Pneumatics + pressurization are REAL, not stubs:
  `SystemsManager::updatePneumatics` — eng1/eng2/APU bleed sources, cross-bleed
  OFF/AUTO/OPEN logic (AUTO opens on APU-bleed-only or asymmetric supply), pack
  availability gated on manifold pressure >15; `updatePressurization` — cabin
  altitude target `= clamp(planeAlt·0.2, 0, 8000)` with climb/descent rate limits,
  cabin VSI, ΔP from ISA pressure delta, outflow valve position, ditching override
  (closes valve, freezes cabin alt). Full FlightDataManager Q_PROPERTY surface
  (engBleed1/2, apuBleed, crossBleedMode, pack1On/2On, cabinAltitude/Vsi/DeltaP,
  outflowValvePos, ditchingOverride, bleedPressure1/2) — getters AND setters both
  implemented (the 07-16 pre-audit snapshot had declarations only and did not
  link; fixed same session). ECAM SD BLEED and PRESS pages now read these live
  (was previously only ELEC/HYD).
- ✅ (07-16, audited) CG shift from fuel distribution was ALREADY implemented
  (`SystemsManager::updateFuel`, `cg_mac_pct` shifts with tank quantities) —
  previously mis-tracked as open in this plan; correcting the record.
- ✅ (07-16, audited) ADIRS fast-align: alignment time is 420 s (7 min), not the
  600 s full-align — matches doc 05 §1.3's "known position" fast-align case.
- 🟢 ADIRS remaining refinement: no distinct ADR-data-at-90s intermediate stage;
  ATT mode still keys off GNSS loss rather than alignment loss specifically —
  cosmetic vs current behavior, low priority.
- FIXED (07-16, this session): ECAM `drawBleed()` referenced
  `FlightDataManager.eng1Active`/`eng2Active`, which never existed — silently
  always read `undefined` (falsy), so the ENG1/ENG2 bleed-source indicators always
  showed OFF regardless of actual engine state. Corrected to `root.adc.n1Left/
  n1Right > 15.0`, verified build+tests+smoke clean. (ECAMLowerDisplay.qml:143,169)
- 🟡 Pneumatic/pressurization remaining: fire protection (loops, squibs, agents)
  still absent; no anti-ice bleed draw modeled.
- 🔴 OverheadPanel.qml: CONFIRMED still 3 of 12 doc-06 §4 sections (HYD flags —
  genuinely toggle-writable via the generic `FlightDataManager[modelData.prop]
  = !...` pattern, not cosmetic; ELEC/APU; NAV/ADIRS as plain booleans, not the
  doc's OFF/STBY/NAV tri-state) + a read-only fuel readout. Audited 07-17,
  split by what's actually needed:
  - 🔴 BACKEND-READY, UI-ONLY (do first — no new C++ needed): BLEED
    (`engBleed1/2`, `apuBleed`, `crossBleedMode` all have setters), PACKS
    (`pack1On/2On`), PRESSURIZATION (`ditchingOverride`; MODE SEL/LDG ELEV can
    stay display-only against `cabinAltitude` etc.), ANTI-ICE (`wingAntiIce`,
    `eng1AntiIce`, `eng2AntiIce` — confirmed to exist but unwired anywhere).
  - 🔴 NEEDS NEW BACKEND WORK FIRST: FIRE Protection (no properties exist at
    all), SIGNS, LIGHTING, per-pump HYD (G/B/Y eng+elec, PTU AUTO/OFF, RAT) and
    FUEL (6 pumps + X-FEED + MODE SEL) switches, EXT PWR + BUS TIE.
  No decorative switches (Target_work hard rule).
- 🔴 ADIRS mode/countdown NOT exposed to QML anywhere: `adirsMode[]` and
  `adirsAlignTime[]` exist on the bus but no façade property, no OHP annunciator,
  no IrsInitPage.qml display of alignment remaining time.
- 🔴 ECAM SD numerics: drawElec (AC/battery volts) and drawHyd (G/B/Y PSI) are live
  (07-12/07-16); drawBleed/drawPress now live (07-16, see above). Still constants:
  drawEng oil/vib (AirDataComputer already exposes oilPressureLeft/Right,
  oilTempLeft/Right, vibN1/N2Left/Right as Q_PROPERTYs since 07-16 — just not read
  by the canvas yet), FUEL page flow rates.
- 🟡 Electrical topology depth per Appendix A.3: EMER GEN/STAT INV sources exist as
  flags only; add TR granularity, ESS SHED buses, battery charge model.

### Phase 3 — Engine & Ground Model (LEAP-1A) 🚧 STARTED
- ✅ (07-11) `EngineModel` detailed internals: N1+N2 spool (τ 1–4 s), start sequence
  (fuel at 22% N2, starter cutoff 55%, EGT start spike), EGT thermal lag, FF, oil,
  vib, thrust `T_max·σ^0.7·f(M)·g(N1)`, bleed flow; engines independent per
  `tickEngine` (old both-engines fire quirk gone in the detailed path).
- ✅ (07-12) ADC calls the detailed tick with real alt/Mach/OAT and publishes the
  full engine state (N1/N2/EGT/FF/oil/vib/thrust/started) to the bus.
- ✅ (07-16, audited) Legacy-compat shim `EngineModel::tick(dt, fire1, fire2)` is
  DELETED (the `400 + 5·N1` EGT overwrite and `thrust1/2`-as-input mapping are
  gone); `testEngineModel` migrated to `thrustLeverAngle1/2` + detailed-tick
  inputs and passes. `thrust1/thrust2` fields still exist but are now pure OUTPUT
  mirrors (`thrust1 = n1Left` set at the end of `tick()`) — harmless, could be
  renamed/removed later but not blocking.
- ✅ (07-16, audited) `ThrottleQuadrantModel` and `GroundModel` are now in
  `Backend/CMakeLists.txt` and owned/ticked by `AirDataComputer` every frame
  (`m_throttle.tick(dt)`, `m_ground.tick(dt, m_altitude)`); `thrustLeverAngle1/2`
  on `EngineModel` are driven from `m_throttle.getNormalizedThrust(tla1/2)` (real
  engine response to TLA); `m_ground.onGround` now clamps altitude to 0 and zeroes
  negative VSI at touchdown (real physics change, not cosmetic); autobrake
  selector is wired ADC↔GroundModel; new Q_PROPERTYs exposed: `tla1/tla2`,
  `speedbrakeLever`, `flapHandleIndex`, `gearDown`, `autobrakeSelector`,
  `parkingBrake`, `onGround`, plus the upper-ECAM engine detail set (`n2Left/
  Right`, `ffLeft/Right`, `oilPressureLeft/Right`, `oilTempLeft/Right`,
  `vibN1/N2Left/Right`). EGT/N1-idle constants NOT yet aligned to doc 03 §2
  (1083/1043 °C limits) — still open, low priority.
- ✅ (07-16 continuation, this session) **Cockpit throttle lever gap CLOSED.**
  `ThrottleQuadrant.qml` levers/flaps/speedbrake now write `adc.tla1/tla2`
  (0–100% slider mapped linearly to 0–45° TLA, top=TOGA),
  `adc.flapHandleIndex`, `adc.speedbrakeLever`; added the missing
  `speedbrakeArmed` Q_PROPERTY (existed on `ThrottleQuadrantModel` but was never
  exposed — nothing could ever arm the speedbrake) plus an ARM toggle button.
  Also fixed a second, worse bug found while wiring `Pedestal.qml`: its throttle
  slider live-bound `value:` to `adc.engine1Thrust`, whose GETTER returns
  simulated N1 (0–105ish, changing every 80 ms tick) while its WRITE path set
  TLA (clamped -20..45) — a read/write domain mismatch that made manual drag
  nearly non-functional (the live binding snapped the handle back every physics
  tick). Fixed by binding the slider to a local backing value written only via
  `Component.onCompleted` (from `adc.tla1/2`) and the slider's own
  `onValueChanged` — same safe one-way pattern used in `ThrottleQuadrant.qml`.
  `Pedestal.qml`'s speedbrake slider and parking-brake toggle (previously fully
  local/inert) now write `adc.speedbrakeLever`/`adc.parkingBrake` the same way.
- ✅ (07-16 continuation) `ThrottleQuadrantModel::tick()` implemented: speedbrake
  ARMED auto-deploy on touchdown (WoW rising edge → lever=1.0) and auto-retract
  on go-around (falling edge → lever=0.0); A/THR detent arbitration
  (`athrManualOverrideActive` — true when A/THR requested but a lever sits above
  CL); reverse-thrust ground interlock (`reverseInterlockTripped` when in the
  REVERSE zone while airborne). Flap handle now has a real aero effect: VLS
  scales by a per-config factor (1.00/0.95/0.85/0.78/0.68) in
  `updateSpeedProtection` — was previously a hardcoded `flapFactor = 1.0` no-op.
- ✅ (07-16 continuation) `GroundModel` braking now consults
  `SystemsManager::getBrakingChannel()` via a multiplier AirDataComputer bridges
  in each tick (NORMAL=1.0, ALTERNATE=0.7 no-antiskid, ACCUMULATOR=0.4,
  NONE=0.0 — hydraulic failures now measurably degrade or remove stopping
  performance); accumulator drains −200 psi per braking-application rising edge
  (Appendix A.4), not continuously. Added a real μ table (`runwayCondition`
  DRY/WET/ICY = 0.5/0.3/0.1 per Architecture doc 03 §5, exposed as
  `adc.runwayCondition`) that scales `effectiveAutobrakeDecel` alongside the
  hydraulic multiplier; LO/MED/MAX now genuinely differ in stopping performance
  (previously a flat `dt*0.2` decay regardless of mode). Added nosewheel
  steering from rudder-pedal input (±6°, `adc.rudderPedal` already existed but
  had no consumer) producing a real heading-rate effect while taxiing — dormant
  until `RudderPedals.qml` is wired (still 🟡 open, tracked below), but correct
  and tested at the model level.
- ✅ (07-16 continuation) Two new gtest suites: `testThrottleQuadrantModel`
  (detent boundaries, normalized-thrust reverse-zone clamp, speedbrake
  arm/deploy/retract, A/THR override arbitration, reverse interlock) and
  `testGroundModel` (WoW threshold, mu table, effective-decel scaling under
  hydraulic-channel and surface-condition combinations, NWS steering output) —
  suite count now 18, all green; full build clean; warning-free smoke run.
- 🔴 (audited 07-17, elevated priority) `RudderPedals.qml` CONFIRMED zero backend
  binding — `property var adc` declared but the string `adc.` never appears
  again in the file; `leftPedal`/`rightPedal` are pure local state. Fix is a
  direct copy of the already-proven `Pedestal.qml`/`ThrottleQuadrant.qml`
  pattern (write `adc.rudderPedal` from the pedal's `onMoved`, no
  `Component.onCompleted` init needed since pedals self-center to 0). Small,
  safe, zero backend risk — activates the already-correct, already-tested
  `GroundModel` NWS steering that is currently 100% dead weight. Also still
  open: tiller-based ±75° ground steering has no UI at all; crosswind
  drift-on-ground not modeled; no gear lever UI exists anywhere (`gearDown`
  defaults true, unconsumed by physics); reverse-thrust PHYSICS (negative
  thrust in `EngineModel`) not implemented — the interlock flag is correct and
  tested but nothing produces reverse thrust yet even on the ground.
- 🟡 EGT/N1-idle constants still not aligned to doc 03 §2 (1083/1043 °C limits).
- 🟡 Ground spoilers (aero drag from `speedbrakeLever`), reverse thrust physics;
  🟢 gear transit animation.

### Phase 4 — FMS & Navigation (ARINC 702A-conceptual) 🚧 IN PROGRESS
Engines built + unit-tested 07-12 (see §2): parser covers PA/PG/D/DB/PI/EP/ER;
`NavigationDatabase` queries runways/navaids/ILS/holdings/airways; `FlightPlanManager`
3-slot TMPY with constraints/overfly/discontinuity/DIR TO; `PerformanceEngine`
VLS/GD/F/S + Vapp per A.1; `PredictionEngine` climb/descent points.
**Audit 07-13, RECONFIRMED 07-17 (unchanged — verified fresh, not assumed):
all five engines are DARK CODE.** `FMGCController` has zero references outside
its own file/tests/registration; `FMSComputer.cpp` references none of the five
(PROG/RAD NAV LSK handlers are literal stubs, e.g. `// Future: set VOR/ILS
frequencies`); all 7 checked MCDU pages bind only `fmsComputer`/`adc`/
`FlightDataManager`; `updatePhysics()` LNAV still reads `FlightDataManager::
waypoints()`, zero `FlightPlanManager` references. New nuance found 07-17:
**`NavigationDatabase` isn't even QML-registered in `main.cpp`** (unlike the
other four, which ARE `qmlRegisterSingletonType`'d) — it's reachable only
internally from `ArincParser`, making it the darkest of the five. Also
confirmed: `AutopilotController.cpp`'s ad-hoc phase heuristic carries the
self-documenting comment `// Phase 4 replaces with FMGC 7-phase` — i.e. the
prior session already flagged its own retirement condition; it hasn't been met.
Remaining, priority order:
- 🔴 INTEGRATION (the Phase-4 gate): wire MCDU pages to the engines —
  INIT/F-PLN edits → `FlightPlanManager` TMPY flow (yellow TMPY rules), PERF →
  `PerformanceEngine`, PROG/FUEL PRED → `PredictionEngine`, RAD NAV →
  `NavigationDatabase` (register it to QML first); drive LNAV sequencing from
  `FlightPlanManager` legs (replacing the FlightDataManager waypoint path in
  `updatePhysics`).
- 🔴 Wire `FMGCController` into the sim loop (never ticked today) AND fix its
  transitions to Appendix A.1: use the unused `n1` param (PREFLIGHT→TAKEOFF on
  N1≥85% & GS≥90 kt), cruise capture instead of hardcoded 28,000 ft, dist≤200 nm
  OR altSel↓ for DESCENT, decel point for APPROACH, accel alt for GA→CLIMB; then
  retire the duplicate phase heuristics in `AutopilotController::update`.
- 🟡 Test coverage for these five is isolation-only (construct-and-call directly
  via `::instance()`) — no test exercises the real `FMSComputer`/`AirDataComputer`
  integration path. Add integration tests alongside the wiring work, not after.
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

### Phase 7 — Failure Engine 🔴 CRITICAL DEFECT FOUND (07-17) — fix before extending
**The instructor-facing failure system is functionally broken for most of its
own catalogue, in a way that looks correct from the UI.** Three separate,
disconnected failure-ID lists exist:
1. `InstructorEngine::s_catalogue` (`InstructorEngine.cpp:6-23`) — 16 IDs, e.g.
   `HYDRAULIC_GREEN_FAILURE`, `GEN1_FAILURE`, `TCAS_FAILURE`. `injectFailure`/
   `clearFailure` just add/remove from this list — no cascade call.
2. `AirDataComputer::m_activeFailures`, populated via `Main.qml`'s
   `InstructorEngine.failureInjected → adc.applyFailure(id, active)` wiring —
   but `AirDataComputer` only ever CONSUMES 3 of the 16 IDs
   (`ENGINE_FIRE_1/2`, `PITOT_BLOCKAGE`). The other 13 land here and do nothing.
3. `FlightDataBus::training().activeFailures` (`Core/FlightDataBus.hpp:217-229`)
   — a THIRD, differently-named list (`HYD_GREEN_LEAK`, `GEN_1_FAULT` style).
   `SystemsManager.cpp` (lines 135-137, 187-188) DOES contain real, correct
   cascade logic reading from this list (pressure decay, bus loss) — but
   **nothing in production code ever writes to it**; the only writer anywhere
   in the codebase is `tests/main.cpp:295`, which pushes directly for a unit
   test. The IDs don't even match list 1's naming scheme.
Net effect: injecting `HYDRAULIC_GREEN_FAILURE`/`GEN1_FAILURE`/etc. from the
Instructor Station UI today has **zero physical effect** on the aircraft —
only engine fire and pitot blockage (3/16 IDs) do anything. This is worse than
"no cascade logic exists" (which is what the plan previously implied) — the
cascade logic is real and correct, it's simply unreachable from the UI.
- 🔴 **FIX FIRST (before any catalogue expansion):** unify around ONE ID list.
  Recommended: adopt the `FlightDataBus::training().activeFailures` naming
  scheme (since `SystemsManager`'s real cascade logic already keys off it) as
  canonical; repoint `InstructorEngine::s_catalogue` IDs to match it; change
  the `Main.qml` wiring (or add a new path) so `injectFailure`/`clearFailure`
  write into the bus list, not (only) `AirDataComputer::m_activeFailures`.
  Gate: an INTEGRATION test (not unit-in-isolation) proving
  `instructor.injectFailure("HYD_GREEN_LEAK")` → `SystemsManager::tick()` →
  `bus->systems().hyd.greenPressure` actually decays. Repeat for at least one
  ID per current cascade branch in `SystemsManager.cpp`.
- 🔴 `FailureEngine` (replaces InstructorEngine's flat list): progressions
  IMMEDIATE/PROGRESSIVE/INTERMITTENT/LATENT; triggers MANUAL/SCHEDULED/CONDITIONAL/
  RANDOM; cascades computed through `SystemsManager` (ENG1 flameout → GEN1 → Hyd G
  decay → Pack 1 → yaw, doc 08 §3).
- 🔴 Catalogue: currently 16 real IDs exist (see above) vs the **58 IDs of
  Appendix A.2** (47 fail.xml + 11 electrical.nas) PLUS doc-13 §2.1 additions:
  gear (door unsafe, asymmetric, gravity ext, LGCIU1, NWS, retract fail), fire
  (FWD/AFT cargo, lav, avionics), comms (VHF1/2, ACARS, SELCAL, HF1) →
  **~73 total target**, stored as data. Expand only AFTER the unification fix
  above — adding more IDs to a disconnected system compounds the defect.
- 🔴 FWC/ECAM integration: QRH-worded caution/warning lines, master caution/warning,
  SD auto page-call, memo/status, memory-item flag. (Note: `ECAM.qml` currently
  has NO master-caution/master-warning display and NO message list at all —
  confirmed by repo-wide grep, zero hits for `masterCaution|masterWarning|
  ecamMessage`; the "memo line" is a static `"ALL SYSTEMS NORMAL"` string on a
  10 s timer, driven by nothing. This needs building, not just wiring.)
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
- 🔴 (audited 07-17) `ECAM.qml` (upper E/WD) — real component, PARTIALLY wired,
  and a pure-plumbing fix (zero backend risk, everything it needs already
  exists and is proven live elsewhere in the app): N1/EGT are live
  (`adc.n1Left/n1Right`, `egtLeft/egtRight`); N2/FF/oilP/oilT/vib are hardcoded
  literals (e.g. `n2: 94.5`, `ff: 1240`, `oilP: 38`) despite `adc.n2Left/Right`,
  `ffLeft/Right`, `oilPressureLeft/Right`, `vibN1/N2Left/Right` existing as
  live Q_PROPERTYs since 07-16; FUEL block is hardcoded ("5420 KG") despite
  `FlightDataManager.fuelLOuter` etc. being live in `OverheadPanel.qml` in this
  same app; ELECTRICAL/PNEUMATIC status rows are hardcoded "ON"/"AUTO" despite
  `gen1Active/gen2Active`/`engBleed1/2`/`apuBleed` already existing and already
  used correctly in `OverheadPanel.qml`. Only HYDRAULIC reads live state. See
  Phase 7 for the master-caution/warning + message-list gap (needs new logic,
  not just wiring).
- 🟡 Cyan alt target, metric alt, radio altimeter <2500 ft (needs Ph3 AGL), ND CSTR +
  ARPT overlays, TOC/TOD pseudo-waypoints, ILS readout.
- 🟡 (found 07-17) `EFISControl.qml` WXR gain/tilt +/- buttons and an NDB-overlay
  toggle reference `wxrGain`/`wxrTilt`/`ndbOverlay` — none of these exist on
  `FlightDataManager` (confirmed zero matches). Unlike most gaps in this plan,
  this is backend-absent, not silently-broken: needs new Q_PROPERTYs + a
  parametric WXR model tie-in before the UI can be wired. Low priority (radar
  tilt/gain is a minor fidelity detail, not a core training function).
- 🟢 Canvas → QQuickPaintedItem 30 Hz migration (per §1.1).

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
5. **Antigravity work-log accuracy** (2026-07-11 → 07-16): mixed record. 07-11/07-13
   sessions overstated completion (wiring claimed with no diffs; one audit "run"
   produced zero deliverables). The 07-16 pneumatics/pressurization/Phase-3 session
   was SUBSTANTIVE and mostly accurate — real models, shim correctly deleted, tests
   migrated — but shipped a non-linking build (declarations without .cpp bodies)
   and one silent QML bug (`FlightDataManager.eng1Active` never existed; fixed
   this session). Continue to verify every claim against diffs + a green build
   before trusting a status; this plan's §2/§3, backed by that verification, is
   the truth.
6. **Uncommitted-work risk is now the top process issue.** As of 2026-07-16, ~600
   lines of verified, tested, working code (Phase 2 pneumatics/pressurization +
   Phase 3 shim deletion/TQ/Ground integration) sat uncommitted across two sessions
   — a crash, revert, or conflicting edit would have destroyed real progress.
   Standing rule going forward: commit + push as soon as a change is build-clean
   and test-green, not at the end of a multi-session arc.
7. **ThrottleQuadrant.qml↔backend disconnect — RESOLVED (07-16, same-day
   continuation).** Both `ThrottleQuadrant.qml` and `Pedestal.qml` now write
   `tla1/tla2`, `flapHandleIndex`, `speedbrakeLever` (+ the newly-exposed
   `speedbrakeArmed`, `parkingBrake`). A second, more serious bug was found and
   fixed while closing this: `Pedestal.qml`'s throttle slider live-bound its
   `value:` to `adc.engine1Thrust`, whose getter returns simulated N1 (changing
   every physics tick) while its write path set TLA — a read/write domain
   mismatch that made manual dragging nearly non-functional. See Phase 3 for
   the full fix record and remaining gaps (RudderPedals.qml has the equivalent
   gap now; reverse-thrust physics still unimplemented).
8. **Live UI verification limits**: this session could not drive the running
   `FmsTrainer.exe` via computer-use (the custom exe has no Start-Menu/installed-
   app registration, which the available automation tooling requires for its
   allowlist). Verification instead relied on: 18/18 passing unit tests that
   exercise the exact new logic, a warning-free smoke run with
   `QT_FORCE_STDERR_LOGGING=1` (a bad `var`-typed QML property reference — like
   discrepancy 5's `eng1Active` bug — reliably surfaces here since
   `ThrottleQuadrant.qml` is always-instantiated, not behind a view-switch
   Loader), and manual trace of the data-flow chain. `Pedestal.qml`'s bindings
   are behind a Loader (view index 5) and were verified by code review only, not
   a live warning-free run — flag for a follow-up session with GUI access to
   confirm interactively.
9. **Failure-ID canonical naming scheme** (found 07-17, see Phase 7): three
   disconnected ID lists exist today (`InstructorEngine`'s catalogue-style
   `HYDRAULIC_GREEN_FAILURE`; `FlightDataBus`'s cascade-driving `HYD_GREEN_LEAK`
   style; Appendix A.2's fail.xml-derived IDs for the eventual 58/73-item
   catalogue, a third convention again). This plan recommends adopting the
   `FlightDataBus` scheme as canonical since `SystemsManager`'s real cascade
   logic already keys off it — but confirm against Appendix A.2 before Session
   B locks it in, since the eventual full catalogue must match doc 08/Appendix
   A.2 IDs for QRH-wording traceability. Whichever is chosen, do it ONCE:
   changing ID strings after the catalogue grows to 58+ entries is expensive.

## 6. KEY REFERENCE POINTERS (full index: Reference_Forensic_Report.md Part 11)

FMGC phases/fuel polynomials: `Reference/A320-family-dev/Nasal/FMGC/FMGC.nas` (GPL —
algorithms only) · failure tree: `.../AircraftConfig/fail.xml` · elec/hyd/FADEC:
`.../Nasal/Systems/` · ARINC 424: `Reference/.../FMS_pending/ARINC424Parser-master`
(MIT) · perf tables: `.../openap-master` (MIT) · FCOM/procedures/ICAO 8168 PDFs:
`Reference/FMS-Work/FMS Docs/` · coding standards PDFs: `Coding standards/`.
