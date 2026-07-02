# FMS Trainer Development Utilities & Workspace Ecosystem (Aviation Grade)

This document catalogs the developer environment tools, cloned open-source repositories, runtimes, package managers, custom agent skills, and IDE extensions configured on this system. It details how they are utilized for building, integrating, and maintaining the **Airbus A320neo Flight Management System (FMS) Trainer** using **C++17/20, Qt6, and QML** under safety-critical aviation standards.

---

## 1. Safety-Critical Runtimes & Languages

Aviation-grade software demands deterministic behavior, strict memory bounds, and robust compilation. The following runtimes and toolchains on this system form the backbone of the FMS simulation core:

### C++17/20 & MSVC / GCC / Clang
*   **Purpose:** The core simulation engine is written in C++ for maximum execution speed, low-level memory management, and deterministic performance.
*   **Standards Integration:**
    *   Adhering to safety-critical rules (e.g., **MISRA C++:2023** and **JSF AV C++** rules).
    *   **Zero dynamic memory allocation** during the active simulation loop to prevent memory fragmentation and heap exhaustion.
    *   Use of `std::array` instead of `std::vector` and avoiding raw pointers in favor of safe modern C++ smart pointers or stack allocation.
*   **Use Cases for FMS Trainer:**
    *   **Air Data Computer (ADC)** and flight dynamics equations.
    *   Autopilot state machines and MCDU calculation loops.

### Qt6 & QML (Quick/QuickControls2/Charts)
*   **Purpose:** Cross-platform GUI framework supplying high-performance GPU-accelerated rendering.
*   **Use Cases for FMS Trainer:**
    *   **QML (Qt Modeling Language):** Declaring cockpit display layouts (PFD, ND, MCDU). Supports smooth 60 FPS rendering on target hardware.
    *   **Qt Quick Controls 2:** Providing standard widgets adapted into aviation controls (buttons, dials).
    *   **Qt Charts:** Rendering real-time training telemetry plots (altitude profile, speed profile).
    *   **C++ & QML Integration:** Exposing the C++ simulation core to QML using `Q_PROPERTY`, `Q_INVOKABLE`, and custom `QObject`-derived models.

---

## 2. Cloned Open-Source Repositories (`dev_tools/`)

The cloned repositories located in `dev_tools/` serve as architectural references, local helper systems, and agentic workflows to build, test, and document the FMS:

### A. Code Intelligence & Graph Analysis
*   **GitNexus (`dev_tools/GitNexus`):** Parses the C++ and QML codebase using Tree-sitter. It builds local code dependency graphs to enable Graph RAG, helping developer agents quickly understand complex class hierarchies and signal/slot bindings between C++ and QML.
*   **ruflo (`dev_tools/ruflo`):** High-speed file utility to index and scan project assets, translation files (`.ts` / `.qm`), and QML resource files.
*   **awesome-mcp-servers (`dev_tools/awesome-mcp-servers`):** Provides a library of tool interfaces for database access, code searching, and documentation lookup directly inside the agent workspace.

### B. Autonomous Agentic Workflows & Multi-Agent Teams
*   **goose / aider / OpenHands / crewAI / langgraph / hermes-agent / claude-task-master / flowsint / agent-skills / awesome-claude-code:**
    *   These frameworks are utilized for **Automated Software Verification & Validation (V&V)** matching **DO-178C Level A/B** requirements.
    *   **Automated MISRA Checking:** Running scripts to parse code files for safety-critical violations.
    *   **Regression Testing Swarms:** Running agents in parallel to perform end-to-end user scenario testing on the simulation APIs.

### C. Design, Asset Generation, & Prototyping
*   **penpot (`dev_tools/penpot`):** Open-source design tool (Figma alternative) used to design the visual layout of MCDU panels, button matrices, and color palettes before translating them into QML anchors.
*   **remotion / MoneyPrinterTurbo / hyperframes / Open-Generative-AI:**
    *   Creating instructional training videos, UI walkthroughs, and cockpit display animations.
    *   Generating visual references for complex flight deck states and emergency procedures.
*   **voxelsim / VoxCPM:** Used for physical mockup design and prototyping spatial controls.

### D. Production Deployment & Telemetry Infrastructure
*   **coolify (`dev_tools/coolify`) / nginx (`dev_tools/nginx`) / infisical (`dev_tools/infisical`):**
    *   **Infisical:** Secure key vault to store development certificates, simulator maps database keys, and training APIs without committing them to git.
    *   **Nginx & Coolify:** Hosting the centralized pilot dashboard database, hosting scenario assets, and load-balancing the live telemetry data stream API.
*   **n8n / n8n-mcp:** Integrates training reports, automatically notifying instructors on Slack/Email when a pilot completes an MCDU flight plan training module.
*   **cal.com:** Used to schedule simulator sessions or instructor review slots.
*   **posthog / plausible-analytics:** Tracking pilot interaction events (e.g., button clicks on the MCDU scratchpad, time spent on INIT pages) to analyze common pilot learning bottlenecks.

---

## 3. UI Touch Slider & Gesture Reference

### Swiper (v12.2.0)
*   **Installation:** Global system package (`npm install -g swiper`).
*   **Relevance to Qt/QML Development:**
    *   While Swiper is a web-focused carousel library, it is used as a **behavioral reference** for high-fidelity touchscreen gestures.
    *   The interactive sliding, spring-back physics, drag resistance, and inertia of Swiper are translated into native QML using `Flickable`, `SwipeView`, and custom `MouseArea`/`MultiPointTouchArea` bindings to deliver a natural touch feel on MCDU touch interfaces.

---

## 4. System Utilities

### Microsoft PowerToys (v0.100.0)
*   **FancyZones:** Splits high-resolution monitors to concurrently host the QML application preview, the Qt Creator / VS Code IDE, and the simulation terminal.
*   **Always on Top (`Win + Ctrl + T`):** Pins the MCDU display window on top while modifying the C++ backend or editing QML code.
*   **Screen Ruler (`Win + Shift + M`):** Measures the dimensions of cockpit dials, display borders, and font alignments in pixels to ensure exact conformity with Airbus flight deck specs.
*   **Color Picker (`Win + Shift + C`):** Extracts precise color codes (such as Airbus cockpit gray, PFD cyan, and MCDU green) directly from pilot operating handbook (POH) PDFs.

---

## 5. IDE Extensions (VS Code / Antigravity Extensions)

To support C++ and Qt6/QML development inside the Antigravity IDE, the following editor extensions are configured under `C:\Users\akass\.antigravity\extensions`:

### C/C++ & Build Systems
*   `llvm-vs-code-extensions.vscode-clangd` & `kylinideteam.kylin-clangd`: C++ code intelligence, safe refactoring, linting, and autocomplete.
*   `ms-vscode.cmake-tools`, `twxs.cmake`, `kylinideteam.kylin-cmake-tools`, & `kylinideteam.cmake-intellisence`: CMake integration, generating compilation databases (`compile_commands.json`), and build automation.
*   `kylinideteam.cppdebug` & `kylinideteam.kylin-debug`: Local C++ debugging using GDB/LLDB.
*   `kylinideteam.qmake-tools`: Support for legacy qmake project structures if encountered in library components.

### Qt & QML Development
*   `theqtcompany.qt`, `theqtcompany.qt-core`, `theqtcompany.qt-cpp`, `theqtcompany.qt-cpp-pack`, `theqtcompany.qt-python`, `theqtcompany.qt-python-pack`, `theqtcompany.qt-qml`, `theqtcompany.qt-ui`, `theqtcompany.qt-wasm-pack`: Full suite of Qt Company tools for QML syntax highlighting, autocomplete, property checks, and project setup.
*   `kylinideteam.qt-support` & `tonka3000.qtvsctools`: Adds Qt resource file compilation (`.qrc`), translations manager, and build helpers.
*   `delgan.qml-format`: Enforces clean, standardized QML code formatting on every save, preventing layout inconsistencies.

---

## 6. Custom Agentic Skills

These customized agent rules are loaded by Antigravity to support safety-critical developer logic:
*   **clear-code (`installed_dev_skills/skills/clear-code`):** Restricts the code generator from introducing unnecessary complexity, helping maintain the pure, flat structures required for flight-deck software.
*   **skill-creator (`installed_dev_skills/skills/skill-creator`):** Automates the drafting of project-specific compliance rules (e.g. creating rules for static analysis).
*   **agent-skills-for-context-engineering:** Ensures long-context files, headers, and schemas are indexed efficiently without blowing the memory limit.
