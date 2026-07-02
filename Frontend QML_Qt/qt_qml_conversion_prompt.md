# 💡 Project Initiation Prompt: Qt/QML High-Fidelity FMS Trainer

**Objective:** Replicate and advance the existing Airbus A320neo FMS Trainer by migrating from React to a high-performance **Qt/QML (Frontend)** and **C++ (Backend)** architecture. This project will serve as a professional-grade pilot training tool with deterministic physics and smooth, high-frequency UI rendering.

---

## 🏗️ Core Architecture Instructions
1.  **Language Stack**: Use **C++17/20** for the simulation backend and **QML (Qt Quick)** for the high-fidelity UI.
2.  **Build System**: Use **CMake** to manage the project, ensuring a clean separation between the `Backend` (C++ libraries) and `Frontend` (QML resources).
3.  **Integration Pattern**: Use the **QObject-based Bridge pattern**. Expose C++ simulation data to QML via `Q_PROPERTY` and handle user interactions via `Q_INVOKABLE` methods or Signals/Slots.
4.  **Strict Rule**: All development must occur in a **new project directory**. The existing `fms-trainer-main` directory is for **reference only** and must not be modified.

---

## 🗂️ Reference Materials
- **Technical Specification**: Refer to the root [README.md](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/README.md) for the "as deep as possible" explanation of system architecture, data schema, and logic flow.
- **Visual Source of Truth**: Use the 29 high-fidelity screenshots in [Images/](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/) to guide your QML styling and layout.

---

## 🖼️ Image-to-Feature Mapping Guide
Use the following directory of images to build your QML components:

### 1. Primary Flight Display (PFD)
- **Reference**: [pfd_display.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/pfd_display.png), [fcu_closeup.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/fcu_closeup.png)
- **Instructions**: Build the horizon, altitude/speed tapes, and FMA (Flight Mode Annunciator). Ensure the tapes use smooth animations (60Hz+) to match the telemetry flow described in the README.

### 2. Navigation Display (ND)
- **Reference**: [nd_plan.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/nd_plan.png), [nd_rose_nav.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/nd_rose_nav.png), [engine_systems.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/engine_systems.png)
- **Instructions**: Implement a multi-mode map view. Support switching between **ROSE**, **ARC**, and **PLAN** modes. Use QML Canvas or Shape elements for high-performance rendering of the flight plan and overlays (WXR/TERR).

### 3. FMS / MCDU
- **Reference**: [mcdu_fpln.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/mcdu_fpln.png), [mcdu_init.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/mcdu_init.png), [mcdu_perf.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/mcdu_perf.png), [mcdu_prog.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/mcdu_prog.png), [mcdu_radnav.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/mcdu_radnav.png), [mcdu_data.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/mcdu_data.png), [mcdu_focus.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/mcdu_focus.png)
- **Instructions**: Replicate the deterministic logic for all 6 priority pages. Implement the scratchpad as a C++ string buffer exposed to QML, with LSK (Line Select Key) validation logic handled in C++.

### 4. Cockpit Environment
- **Reference**: [overhead_view.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/overhead_view.png), [pedestal_view.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/pedestal_view.png), [split_view.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/split_view.png), [view_dropdown.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/view_dropdown.png)
- **Instructions**: Design the layout to support a "Split View" mode where multiple panels (e.g., Pedestal + PFD) are visible concurrently.

### 5. Training & Instructor Systems
- **Reference**: [instructor_panel.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/instructor_panel.png), [instructor_failures.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/instructor_failures.png), [training_scenarios.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/training_scenarios.png), [exam_center.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/exam_center.png), [analytics_tab.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/analytics_tab.png), [ai_coach.png](file:///c:/Users/ADMIN/Desktop/Frontend%20QML_Qt/Images/ai_coach.png)
- **Instructions**: Build a modern "Instructor Station" in QML. Use C++ to manage the **Failure Injection** engine, allowing the instructor to trigger malfunctions that propagate through the simulation state.

---

## 🚀 Implementation Roadmap
1.  **Phase 1: Project Foundation**: Setup CMake and basic QML windowing. Initialize the C++ [AirDataComputer](file:///c:/Users/ADMIN/Desktop/FMS/fms_backend/include/systems/AirDataComputer.hpp#35-36) (reference: `fms_backend` implementation).
2.  **Phase 2: Primary Graphics**: Implement the PFD Attitude Indicator and Speed/Altitude tapes in QML.
3.  **Phase 3: FMS Core**: Build the MCDU framework and connect it to the C++ Flight Plan manager.
4.  **Phase 4: ND & Systems**: Implement Navigation modes and the Systems Overlay (Engine/Electric).
5.  **Phase 5: Instructor & Exam**: Finalize the failure suite and the Proficiency Exam logic.
