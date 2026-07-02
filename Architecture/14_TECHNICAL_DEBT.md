# 14 — Technical Debt Report & Remediation Registry

This document serves as the official tracking register for technical debt, architectural smells, and code quality issues identified in the FMS-Trainer codebase.

---

## 1. Concurrency & Performance Debt

### TD-01: QML Canvas Repaint Churn & Render Leak
* **Description**: QML `Canvas` (used in PFD and ND screens) leaks graphics contexts under threaded rendering and causes CPU spikes if repainted at 60 Hz.
* **Current Mitigation**: Render thread set to `basic` (single-threaded) and simulated tick update frequency throttled to **12.5 Hz (80ms ticks)**.
* **Target Remediation**: Rewrite PFD and ND screens to use custom QML C++ items (inheriting `QQuickPaintedItem` or using `QSGNode` Scene Graph primitives) to avoid the QML JS engine completely.
* **Severity**: High (blocks high-fidelity rendering/smooth needle movement).
* **Target Phase**: Phase 5 (UI Refactoring).

---

## 2. Architectural & Modular Debt

### TD-02: Monolithic `AirDataComputer` Class
* **Description**: The `AirDataComputer` class spans over 500 lines of header and C++ code and violates the Single Responsibility Principle (SRP). It handles:
  1. 6-DOF Euler Equations of Motion integration.
  2. Autopilot and Autothrust mode selection and PID control loops.
  3. Engine N1/EGT thrust curves.
  4. Atmospheric models and speed safety limits.
* **Current Mitigation**: None (all logic combined inside `AirDataComputer::tick()`).
* **Target Remediation**: Decompose `AirDataComputer` into `6DOF_FlightDynamics`, `EngineModel`, `AutopilotSystem`, and `SpeedProtection` sub-modules.
* **Severity**: Critical (blocks parallel developer contribution and module-level unit testing).
* **Target Phase**: Phase 3 (C++ System Decomposition).

### TD-03: Shared State via Singletons
* **Description**: System modules (such as `AirDataComputer` and `FMSComputer`) access each other and exchange flight data through the `FlightDataManager` singleton, creating tightly-coupled circular dependencies.
* **Current Mitigation**: None.
* **Target Remediation**: Implement a central, channel-based, mutex-protected `FlightDataBus` to serve as the unified message broker for all subsystems.
* **Severity**: Medium.
* **Target Phase**: Phase 4 (Integration & Bus implementation).

---

## 3. Data & Parsing Debt

### TD-04: Mocked Navigation Database & ARINC Parser
* **Description**: `ArincParser` and `FMSComputer` are stubs that read static JSON coordinate arrays instead of importing official ARINC 424 navigation files.
* **Current Mitigation**: Static waypoint lists hardcoded in `FlightDataManager`.
* **Target Remediation**: Build a proper binary-reader/parser that imports standard ARINC 424 files (e.g. FAA CIFP database) into a local SQLite navigation cache.
* **Severity**: High (blocks realistic FMC procedure selection and route predictions).
* **Target Phase**: Phase 6 (Navigation Database).

---

## 4. Code Quality & Security Debt

### TD-05: Local Path Leakage
* **Description**: Several files containing QML loaders and local paths hardcode local user folder names (`c:/Users/akass/...`) or hardcoded path structures.
* **Current Mitigation**: None.
* **Target Remediation**: Replace all absolute paths with Qt Resource files (`qrc:/`) or standard runtime lookups relative to `QCoreApplication::applicationDirPath()`.
* **Severity**: Low (blocks portable build distribution).
* **Target Phase**: Phase 1 (Initial Cleanups).

---

## 5. Verification & Test Debt

### TD-06: Zero Unit Test Coverage
* **Description**: The project includes `tests/main.cpp` but lacks actual assertions or test cases validating the 6-DOF integrator, autopilot laws, or flight plan calculations.
* **Current Mitigation**: None (verification is purely manual via QML UI execution).
* **Target Remediation**: Integrate Catch2/GoogleTest and write tests confirming state vector outputs under constant force configurations.
* **Severity**: High.
* **Target Phase**: Phase 2 (Test Harness Setup).
