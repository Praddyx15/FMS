# Project Blueprint: Airbus A320neo FMS Trainer & Pilot Training Platform

This document provides a comprehensive, architectural, and procedural breakdown of the **Airbus A320neo Flight Management System (FMS) Trainer and Advanced Pilot Training Platform**. It details the project's background, system capabilities, technological transitions, and the engineering methodologies required to align it with real-world safety-critical avionics standards.

---

## 1. Executive Summary & Project Purpose

The **Airbus A320neo FMS Trainer & Advanced Pilot Training Platform** is a high-fidelity desktop and web-based simulation environment. It acts as a training bridge for commercial pilots, Approved Training Organizations (ATOs), and airline training departments to practice:
* **MCDU (Multipurpose Control and Display Unit)** data entry, route initialization, and performance calculations.
* **Flight Control Unit (FCU)** target management (managed vs. selected modes).
* **Autopilot & Flight Mode Annunciator (FMA)** states during abnormal or normal procedures.
* **Instructor-Led Training** through administrative portals, telemetry dashboards, syllabus generators, and real-time failure injection systems.

Historically, flight training is split between low-fidelity static systems and multi-million dollar Full Flight Simulators (FFS). This project fills the gap by providing a low-cost, high-fidelity, procedurally accurate training platform that replicates the core system interfaces of the A320 flight deck.

---

## 2. Platform Architecture & Capabilities

The platform is structured into two core areas:

### A. The Core Simulation: A320neo FMS Trainer
This simulates the physical instruments and computers inside the cockpit:
* **MCDU (Core FMS Interface):** Deep simulation of pages including **INIT A/B** (flight plan initialization, fuel estimation, weight/balance), **F-PLN** (flight plan routing, waypoints, constraints), **PERF** (takeoff performance speeds $V_1$, $V_R$, $V_2$, cruise, climb, and descent management), **PROG** (progress tracking, GPS accuracy), and **RAD NAV** (radio navigation tuning).
* **Primary Flight Display (PFD):** Displays real-time airspeed tapes, altitude tapes, vertical speed, slip/skid, horizon indicator, and the Flight Mode Annunciator (FMA) columns showing active/armed autopilot modes.
* **Navigation Display (ND):** Visualizes routes, aircraft heading, VOR/ADF needles, weather overlays (WXR), terrain maps (TERR), and traffic advisory alerts (TCAS) in ARC, ROSE, and PLAN views.
* **Flight Control Unit (FCU):** Autopilot panel allowing pilots to select or manage airspeed, heading, altitude, and vertical speed.
* **Overhead & Pedestal Panels:** Interactive engine throttles, landing gear control, fuel valves, hydraulic pumps, and electrical generators.

### B. The Administration: Advanced Pilot Training Platform
This manages the curriculum, records trainee performance, and reviews sessions:
* **Multi-Role Authentication:** Specific dashboards for Trainees, Instructors, Examiners, ATO Administrators, and System Administrators.
* **Intelligent Document Processor:** Utilizes OCR (Tesseract) to scan training manuals and PDFs, auto-extracting training curricula, normal procedures, and abnormal checklists.
* **Syllabus Generator:** Translates parsed documents into training modules, lesson guides, and specific pilot competencies.
* **Knowledge Graph:** A force-directed relational layout that visualizes how flight rules, safety regulations, and checklist items are connected.
* **Telemetry & Analytics:** Captures flight performance data (altitude deviations, speed tolerances, path deviations) to grade the trainee's performance.

---

## 3. Technology Stack & Transition

The project is undergoing a transition from a web-development stack to a high-performance C++/Qt6 desktop architecture to match industry avionics profiles.

```
                    ┌──────────────────────────────────────────────┐
                    │               ORIGINAL STACK                 │
                    │   React • TypeScript • Zustand • Tailwind    │
                    └──────────────────────┬───────────────────────┘
                                           │
                                           ▼ Transitioning to:
                    ┌──────────────────────────────────────────────┐
                    │            PRODUCTION/AVIONICS               │
                    │           C++20 • Qt6 • QML • CMake          │
                    └──────────────────────────────────────────────┘
```

### The Web Reference Stack
* **Frontend:** React, TypeScript, Tailwind CSS, Shadcn/UI.
* **State Management:** Zustand (handling global instrument sync).
* **Data Visualization:** D3.js (knowledge graph visualization).
* **Backend:** Node.js, Express, PostgreSQL, Drizzle ORM (handling user profiles, courses, and session storage).
* **Simulation Loop:** Asynchronous JavaScript hooks (`usePhysicsSim`, `useTelemetrySim`) running via `requestAnimationFrame` at 60Hz.

### The C++/Qt6 Avionics Stack
* **Language Standard:** C++20 (provides strong compile-time checks, deterministic memory allocation, and performance optimization).
* **UI Engine:** **QML (Qt Modeling Language)** for rendering 60Hz cockpit displays (PFD, ND, MCDU) with hardware acceleration.
* **Build System:** CMake (multi-platform building, managing dependencies, and matching compiler safety switches).
* **State Management:** Thread-safe C++ controller classes utilizing Qt’s meta-object framework (`Q_PROPERTY`, signals, and slots) to synchronize states between backend engines and QML views.

---

## 4. Sub-System Mechanics

### A. Air Data Computer (ADC)
In the C++ architecture, the `AirDataComputer` class calculates raw flight physics based on International Standard Atmosphere (ISA) models:
* Computes dynamic pressure, true airspeed (TAS), calibrated airspeed (CAS), Mach number, pressure altitude, and density altitude.
* Validates inputs to protect against sensor blockages (simulating static or pitot tube failures).

### B. FMS Computer & Navigation Engine
The `FMSComputer` manages navigational flight plans:
* Parses flight paths into waypoint arrays, calculating distances, courses, and estimated time of arrival (ETA).
* Evaluates vertical and lateral waypoint constraints (e.g., speed and altitude limits).

### C. Flight Data Manager
Acts as the central cockpit communications bus:
* Manages global variables (pitch, roll, yaw, altitude, speeds, and autopilot targets).
* Ensures thread-safe data access so calculations run in the background without freezing the UI thread.

### D. Instructor Engine
Injects failures and monitors the simulation state:
* Controls scenarios like Pitot blockages, engine flameouts, or FMS dual-system lockups.
* Automatically records altitude drift, runway offset, and speed profile violations to generate student reports.

---

## 5. Safety-Critical Design (DO-178C Compliance)

To transition this platform into a representative avionics tool, software development follows **DO-178C (Software Considerations in Airborne Systems and Equipment Certification)** guidelines:

* **Safe C++ Guidelines:**
  * **Zero Dynamic Allocation:** Avoid allocating memory dynamically (`new`, `std::unique_ptr`, `std::vector::push_back`) after the initialization phase to prevent memory leaks and unpredictable latency.
  * **Strict Type Safety:** Use explicit physical types (e.g., using units like feet, knots, and degrees) to avoid mixing up units during calculation.
  * **No Exceptions:** Compile with exceptions disabled (`-fno-exceptions`) to ensure deterministic execution paths.
* **Boundary Validation:**
  * Every input parameter undergoes value-checking to prevent division-by-zero, negative square roots, or NaN (Not-a-Number) values.
* **Deterministic Timing:**
  * Core simulation code runs on fixed-interval loops to ensure consistent execution timing.
* **Traceability:**
  * Code comments and unit tests map back directly to Functional Requirements Specifications (FRS), ensuring compliance during code reviews.

---

## 6. Project Directory Structure

```
C:\Users\akass\Desktop\FMS-Trainer\
│
│
├── Frontend QML_Qt\                # Active C++/Qt6 Project
│   └── FMS_Qt\
│       ├── CMakeLists.txt          # Root CMake build configuration
│       ├── main.cpp                # App entry point (initializes QML and C++ components)
│       │
│       ├── Backend\                # C++ simulation controllers
│       │   ├── CMakeLists.txt
│       │   ├── include\            # Header files (.hpp)
│       │   │   ├── AirDataComputer.hpp
│       │   │   ├── FMSComputer.hpp
│       │   │   ├── FlightDataManager.hpp
│       │   │   └── InstructorEngine.hpp
│       │   └── src\                # Implementation files (.cpp)
│       │       ├── AirDataComputer.cpp
│       │       ├── FMSComputer.cpp
│       │       ├── FlightDataManager.cpp
│       │       └── InstructorEngine.cpp
│       │
│       └── Frontend\               # QML files for UI rendering
│           ├── CMakeLists.txt
│           ├── Main.qml            # Main QML interface window
│           └── qml\                # Sub-system displays
│               ├── cockpit\
│               ├── displays\       # PFD and ND instrument panels
│               ├── mcdu\           # MCDU display pages
│               └── instructor\     # Instructor setup controls
│
└── Reference\                      # Read-Only Reference Folder
    ├── fms-trainer-main\           # React/TypeScript Desktop simulator
    ├── Advanced-Pilot-Training\    # Next.js Full Stack Training application
    └── FMS-Work\                   # Legacy development logs, media files, and documentation
```
