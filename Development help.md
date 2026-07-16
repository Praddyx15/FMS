# Development Help — Skills & Tools per Phase

> Companion to `IMPLEMENTATION_PLAN.md` (the sole-truth plan). Source inventories:
> `c:\Users\akass\.gemini\antigravity\scratch\installed_tools_catalog.md` (Antigravity
> workspace) and the Claude Code session skill set. This file says WHICH of those to
> reach for at each phase — and which to ignore for this project.
>
> Ground rule for every tool/agent below: the engineering constraints in
> IMPLEMENTATION_PLAN §1 (Canvas/memory rules, safety-critical C++, GPL
> algorithms-only) bind ALL agents. After any agent session: `git status`, build,
> run `FmsTests.exe`, and verify claims against diffs before trusting a work log.

---

## 1. Always-on (every phase, every session)

**IDE (Antigravity/VS Code extensions)**
- `clangd` + `CMake Tools` (+ kylin variants) — C++ intelligence and builds. Keep a
  `compile_commands.json` generated per build (already gitignored).
- Qt Company suite (`qt-qml`, `qt-cpp`, `qt-ui`) + `delgan.qml-format` — QML
  authoring/formatting; catches unqualified-property and Qt5-ism errors early
  (a Qt5 `RegExpValidator` once broke app startup silently).
- `ms-vscode.powershell`, `redhat.vscode-yaml`, `tomoki1207.pdf` (read FCOM/standards
  PDFs in-IDE), `mechatroner.rainbow-csv` (inspect CIFP/table data).

**Code quality (Antigravity)**
- `clear-code` skill — apply during any refactor; matches the flat, simple structures
  required by the DO-178C-pattern rules.
- `code-review-graph` MCP + `GitNexus` — dependency/signal-slot graphing; use before
  touching FlightDataBus consumers or reviewing cascade logic.
- `CodeRabbit` extension — second-opinion review on PRs.

**Code quality (Claude Code)**
- `/code-review` after each module lands (use `ultra` for phase-completion reviews).
- `/simplify` after a phase's code is green — reuse/altitude cleanup only.
- `verify` / `run` skills — drive the built app to confirm changes behave.
- `/security-review` before any release milestone (M3, M6).

**Memory & agents**
- `claude-mem` / `agent-skills-for-context-engineering` — long-context hygiene for
  Antigravity sessions on the 19 GB Reference tree.
- `claude-task-master` / `get-shit-done` — task sequencing if a session spans phases.
- `skill-creator` — when a convention stabilizes (ECAM colour rules, FMA text,
  failure-ID naming), freeze it as a reusable skill so every later session obeys it.

## 2. Phase-by-phase map (phases from IMPLEMENTATION_PLAN §3)

### Phase 2 — Aircraft Systems (in progress)
- `excel-mcp-server` (MCP): author the electrical bus truth table (source × contactor
  × bus per Appendix A.3) and hydraulic cascade matrix as spreadsheets → generate
  table-driven gtest cases from them.
- `code-review-graph` / `GitNexus`: map SystemsManager ↔ FlightDataBus ↔ QML reads
  before wiring OverheadPanel switches — no decorative switches allowed.
- `penpot`: lay out the 12-section Overhead Panel (doc 06 §4) before QML work.
- PDF viewer + Claude `pdf` skill: extract switch/annunciator details from
  `Coding standards/Docs/Airbus-A320-Overhead-Panel.pdf` and the FCOM.

### Phase 3 — Engine & Ground Model (started)
- `excel-mcp-server` + `rainbow-csv` + Claude `xlsx` skill: calibrate LEAP-1A
  N1/EGT/FF curves against openap A320 tables (`Reference/.../openap-master`, MIT) →
  export as `A320PerformanceTables.hpp` constexpr data.
- `aider` or `OpenHands` (Antigravity agents): mechanical chores like migrating tests
  off the legacy EngineModel shim — always under §1 rules + test gate.
- `literature-search-arxiv` (optional): turbofan spool/EGT modelling references.

### Phase 4 — FMS & Navigation
- `ruflo` / `GitNexus`: index and navigate `ARINC424Parser-master` (MIT) and
  littlenavmap (GPL — read only, algorithms only) while extending the CIFP parser.
- `excel-mcp-server`: ARINC-424 record-type coverage matrix (PA/PG/PD/PE/PF/ER/D/DB
  × parsed fields × test airport) — the Phase-4 acceptance checklist as data.
- Claude `pdf` skill: pull SID/STAR test fixtures from ICAO Doc 8168 and FCOM.

### Phase 5 — Autopilot & FBW
- `code-review-graph`: review the arm→capture→engage state machine — mode-transition
  bugs are graph bugs.
- `excel-mcp-server`: FMA truth table (5 columns × mode set from doc 05 §2.1) →
  drives both QML display tests and AutopilotController unit tests.
- `penpot` + `awesome-design-md`: pixel spec for the 5-column FMA before QML.

### Phase 6 — Training Framework
- `skill-creator`: turn FCOM normal/abnormal procedures into structured, data-driven
  checklist definitions (one authoring pass, reused by Modes 3/6/7/8).
- `obsidian-skills`: draft/organize scenario scripts and SOP content before they are
  frozen into JSON.
- Claude `docx`/`pptx` skills: instructor-facing training content and briefing decks.
- `OmniVoice` / `VoxCPM` (stretch): offline callouts/ATC voice — keep local-only.

### Phase 7 — Failure Engine
- `excel-mcp-server`: THE tool here — maintain the ~73-failure catalogue (Appendix
  A.2 + doc 13 additions) as a spreadsheet: ID, category, ECAM text (QRH wording),
  cascade targets, memory-item flag → generate the C++ data table from it.
- `code-review-graph`: verify cascade chains (ENG1 → GEN1 → HYD G → Pack 1) touch
  the right SystemsManager paths and nothing else.

### Phase 8 — Instructor Station & Analytics
- `penpot` + `frontend-design` / `theme-factory` skills: instructor dashboard and
  debrief UI design (guidance transfers to QML even though the skills are web-first).
- Claude `xlsx` skill: session-report exports; `canvas-design` skill for the PDF
  report layout.
- `remotion` / `hyperframes`: produce training/demo videos of scenarios (marketing
  and instructor onboarding).

### Phase 9 — Multi-User & Enterprise (DEFERRED — do not start; local-first)
Park these until Phase 9 is unblocked: `nango` (API integrations), `infisical`
(secrets), `coolify` + `nginx` (hosting), `n8n`/`n8n-mcp` (instructor notification
workflows), `cal.com` (simulator-slot booking), `posthog`/`plausible-analytics`
(usage analytics), `Ghost` (product/docs site).

### Phase 10 — Display Fidelity
- `penpot`: pixel-accurate PFD/ECAM reference layouts vs FCOM imagery.
- `awesome-design-md` + `canvas-design`: colour/typography discipline for the
  cockpit palette (Theme.qml stays the single source).
- `remotion`: before/after display-fidelity comparison clips.
- Qt `qt-ui` extension for QQuickPaintedItem migration work at 30 Hz.

### Compliance & docs (continuous; doc 12)
- `scientific-writing` skill: traceability/compliance write-ups in DO-178C-pattern
  language.
- Claude `docx` skill: formal deliverables (test reports, requirement matrices).
- `github.vscode-github-actions`: CI on `Praddyx15/FMS` once a Linux build exists
  (Phase 1 guard is in; wire `FmsTests.exe --selftest` as the gate).

## 3. Catalogued but NOT for this project

To keep sessions focused, do not reach for these here: the entire Financial section
(`TradingAgents`, `FinceptTerminal`, `Vibe-Trading`, `AutoHedge`, `alpha-vantage`,
`quant-analyst`, `price-psychology-strategist` — unless pricing the product someday),
bio databases (`uniprot`, `chembl`, `pdb`), `claude-seo`, `MoneyPrinterTurbo`,
`agentic-inbox`, `browser-use`, `voxelsim`, `algorithmic-art`, `LibreChat`,
`Open-Generative-AI`. The multi-agent frameworks (`crewAI`, `langgraph`, `massgen`,
`hermes-agent`, `goose`, `flowsint`, `superpowers`) are usable but redundant while
Antigravity + Claude Code are the two working agents — don't add a third orchestrator.

## 4. Agent session protocol (Antigravity ↔ Claude Code)

1. Start: `git status` — detect the other agent's uncommitted work.
2. Read `IMPLEMENTATION_PLAN.md` §1–§3 before coding; it is the sole truth
   (work logs are not — verify claims against diffs).
3. **Commit as soon as a change is build-clean and test-green — not only at the
   end of a multi-hour/multi-session arc.** (2026-07-16: ~600 lines of verified
   working code sat uncommitted across two sessions — real progress that a crash
   or bad edit could have destroyed.) Each commit: build + `FmsTests.exe` green +
   warning-free smoke run (`QT_FORCE_STDERR_LOGGING=1`), update plan statuses,
   commit with the phase reference, push to `Praddyx15/FMS`.
4. Never leave a property/method DECLARED without a definition across a session
   boundary — an undefined-reference link error is invisible until someone builds,
   and blocks everyone else's work in the meantime (happened 07-16 with the
   pneumatics Q_PROPERTY surface).

## 5. Prompt-writing discipline

Keep prompts to future agents surgical: name the exact files to read/touch, cite
the plan section, and state the acceptance gate (build+tests+smoke) up front,
rather than open-ended "improve the systems" asks — this keeps sessions scoped
and their diffs easy to audit against the plan.
