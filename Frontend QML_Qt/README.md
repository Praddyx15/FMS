# Airbus A320neo FMS Trainer

[![Vite](https://img.shields.io/badge/vite-%23646CFF.svg?style=flat&logo=vite&logoColor=white)](https://vitejs.dev/)
[![React](https://img.shields.io/badge/react-%2320232a.svg?style=flat&logo=react&logoColor=%2361DAFB)](https://reactjs.org/)
[![TypeScript](https://img.shields.io/badge/typescript-%23007ACC.svg?style=flat&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![TailwindCSS](https://img.shields.io/badge/tailwindcss-%2338B2AC.svg?style=flat&logo=tailwind-css&logoColor=white)](https://tailwindcss.com/)
[![Zustand](https://img.shields.io/badge/zustand-%23000000.svg?style=flat&logo=zustand&logoColor=white)](https://github.com/pmndrs/zustand)
[![Electron](https://img.shields.io/badge/electron-%232B2E3A.svg?style=flat&logo=electron&logoColor=white)](https://www.electronjs.org/)

A professional, high-fidelity Airbus A320neo Flight Management System (FMS) trainer. Designed for pilots and aviation enthusiasts to practice MCDU programming, autopilot management, and flight deck procedures in a desktop-compatible web environment.

## 🚀 Platform Features & Technical Advancements

This platform represents a high-fidelity bridge between web technology and aerospace simulation, featuring professional-grade systems and deterministic logic.

### 🖥️ Cockpit Display Fidelity
- **PFD (Primary Flight Display)**: Precision rendering of IAS and Altitude with managed/selected target bugs. Features a full 5-column **FMA (Flight Mode Annunciator)** and dynamic V-speed bugs (`V1`, `VR`, `V2`).
- **ND (Navigation Display)**: Comprehensive tactical visualization supporting **ROSE NAV/VOR/LS**, **ARC**, and **PLAN** modes. Includes interactive overlays for **Weather (WXR)**, **Terrain (TERR)**, **Traffic (TCAS)**, and Waypoint constraints.
- **MCDU (Multipurpose Control and Display Unit)**: Deep simulation of the FMS core with functional **INIT A/B**, **F-PLN**, **PERF**, **PROG**, **RAD NAV**, and **DATA** pages. Handles full scratchpad interaction and LSK validation.
- **FCU (Flight Control Unit)**: Precision management of SPD, HDG, and ALT with push/pull logic for Managed vs. Selected guidance modes.
- **Overhead & Pedestal**: Operational simulation of hydraulic, electric, and fuel systems, along with high-fidelity throttle quadrant interaction.

### 🕹️ Simulation & Instructor Systems
- **Advanced Failure Injection**: Instructor-led simulation of complex malfunctions including **Engine Fires**, **Pitot/Static Blockages**, and **Dual FMS Failures**.
- **Pedagogy & Coaching**:
  - **AI Flight Coach**: Intelligent classroom assistant providing real-time procedural tips and cockpit guidance.
  - **Exam Center**: Automated proficiency testing with timed assessments and procedural grading.
  - **Training Scenarios**: Rapid-loading flight states for practicing Takeoffs, Stabilized Approaches, and Emergency procedures.
- **Analytics Dashboard**: Post-flight telemetry visualizer for altitude deviation, fuel efficiency, and approach precision.

### 🛠️ Technical Advancements
- **Deterministic Simulation Core**: Integration of a custom **C++ AirDataComputer (ADC)** for high-accuracy atmospheric and performance modeling based on ISA standards.
- **60Hz Telemetry Pipeline**: Zero-latency UI updates driven by a robust telemetry hook architecture.
- **Global State Consistency**: Powered by **Zustand**, ensuring atomic state transitions and synchronization across all cockpit displays.
- **Professional Architecture**: A modular, domain-driven design built with React, Vite, and Electron, supporting both web and native desktop deployment.
- **Split-View Mode**: Optimized multi-monitor or single-screen layout for concurrent monitoring of instruments and control surfaces.

## 📂 Project Structure

- `src/components`: Domain-specific UI components (displays, instruments, overhead).
- `src/state`: Centralized Zustand stores for flight data and layout management.
- `src/hooks`: Simulation engine hooks (`usePhysicsSim`, `useTelemetrySim`).
- `src/services`: Database and WebSocket integrations.
- `Docs/`: Comprehensive technical documentation.

## 🛠️ Getting Started

### Prerequisites
- Node.js (v18+)
- npm or bun

### Installation
1. Clone the repository.
2. Install dependencies:
   ```bash
   npm install
   ```
3. Start the development server:
   ```bash
   npm run dev
   ```

### Running as Desktop App
To launch the Electron wrapper:
```bash
npm run electron:dev
```

## 📸 UI Snapshots Gallery

### 🖥️ Dashboard & View Selection
| Main Dashboard | View Selection Menu | Features Overview | Trainer Interface |
| :---: | :---: | :---: | :---: |
| ![Dashboard](Images/dashboard.png) | ![Dropdown Menu](Images/view_dropdown.png) | ![Features](Images/features.png) | ![Interface](Images/trainer_interface.png) |

### 🕹️ Cockpit Operational Views
| Primary Flight Display | Navigation (Plan) | Navigation (Rose) | FCU Detail |
| :---: | :---: | :---: | :---: |
| ![PFD](Images/pfd_display.png) | ![ND Plan](Images/nd_plan.png) | ![ND Rose](Images/nd_rose_nav.png) | ![FCU](Images/fcu_closeup.png) |

| MCDU F-PLN | MCDU Detail | Overhead Panel | Pedestal & Throttle |
| :---: | :---: | :---: | :---: |
| ![MCDU FPLN](Images/mcdu_fpln.png) | ![MCDU Detail](Images/mcdu_focus.png) | ![Overhead](Images/overhead_view.png) | ![Pedestal](Images/pedestal_view.png) |

### 📟 Multifunction Control (MCDU Pages)
| Progress (PROG) | Radio Nav (RAD NAV) | Performance (PERF) | Initialization (INIT) | Data (DATA) |
| :---: | :---: | :---: | :---: | :---: |
| ![PROG](Images/mcdu_prog.png) | ![RAD NAV](Images/mcdu_radnav.png) | ![PERF](Images/mcdu_perf.png) | ![INIT](Images/mcdu_init.png) | ![DATA](Images/mcdu_data.png) |

### 🎓 Training & Monitoring
| Instructor Panel | Failure Injection | Training Scenarios | Scenarios Detail |
| :---: | :---: | :---: | :---: |
| ![Instructor](Images/instructor_panel.png) | ![Failures](Images/instructor_failures.png) | ![Training](Images/training_scenarios.png) | ![Scenarios](Images/scenarios_tab.png) |

| Exam Center | Exam Interaction | Basic Instruments | Split View Mode |
| :---: | :---: | :---: | :---: |
| ![Exam Center](Images/exam_center.png) | ![Exam Mode](Images/exam_mode.png) | ![Basic Inst](Images/basic_instruments.png) | ![Split View](Images/split_view.png) |

| Analytics Dashboard | AI Flight Coach | Systems Display | Overlay Detail |
| :---: | :---: | :---: | :---: |
| ![Analytics](Images/analytics_tab.png) | ![AI Coach](Images/ai_coach.png) | ![Systems](Images/engine_systems.png) | ![Overlay](Images/dropdown_overlay.png) |

## 🏗️ System Architecture

The FMS Trainer is built as a highly modularized React application, designed to handle real-time flight simulation telemetry and complex FMS logic.

```mermaid
graph TD
    User([User])
    UI[UI Display Engine - React]
    State[Global State - Zustand]
    Physics[Physics/Logic Hooks]
    DB[(Supabase/Local Storage)]
    Electron[Electron Shell]

    User <-->|Interaction| UI
    UI <-->|Updates| State
    State <-->|State Pull/Push| Physics
    Physics -->|Telemetry Updates| State
    State <-->|Persistance| DB
    Electron --- UI
```

### 1. UI Display Engine (React)
- **Displays**: PFD (Primary Flight Display), ND (Navigation Display), MCDU (Multipurpose Control and Display Unit).
- **Controls**: FCU (Flight Control Unit), Pedestal, Overhead.
- **Components**: Atomic UI components (shadcn/ui) and domain-specific instruments.

### 2. State Management (Zustand)
- **Centralized Store**: `useFMSStore` serves as the single source of truth for all flight data, controls, and system states.
- **Determinism**: State transitions are handled through predefined actions to ensure deterministic behavior across the simulator.

### 3. Simulation Core (Hooks & Logic)
- **usePhysicsSim**: Real-time calculation of aircraft attitude, speed, and altitude based on thrust, drag, and weight.
- **useTelemetrySim**: Simulates sensor data and system status updates.
- **Autopilot System**: Complex logic layer that translates FCU/MCDU targets into flight commands.

---

## 📊 Data Schema

### 1. Global State (Zustand)
The `useFMSStore` manages several key data domains:

| Variable | Type | Description |
| :--- | :--- | :--- |
| `departure/destination` | `string` | ICAO codes for flight planning |
| `cruiseAltitude` | `number` | Planned altitude in feet |
| `pitch/roll/heading` | `number` | Real-time aircraft attitude |
| `ias/mach/altitude` | `number` | Performance metrics |
| `ap1Active/ap2Active` | `boolean` | Autopilot engagement status |
| `waypoints` | `Waypoint[]` | Array of path coordinates |

### 2. Persistence (Supabase)
- **`flight_sessions`**: Records mission IDs, user scores, and compressed telemetry logs.
- **`user_profiles`**: Tracks certification levels and training progress.

---

## 🔄 Data Flow Schematic

### 1. Simulation Telemetry (60Hz)
Telemetry data is updated at high frequency (60Hz) via the simulation hooks.

```mermaid
sequenceDiagram
    participant P as Physics Hook (60Hz)
    participant S as Zustand Store
    participant D as Displays (PFD/ND)
    participant R as Record Service

    P->>S: Update ias, alt, pitch, roll
    S->>D: Trigger Re-render (atomic select)
    S->>R: Add Snapshot (1Hz)
    R->>S: Push to replayBuffer
```

### 2. User Input & FMS Logic
MCDU logic involves scratchpad validation and line-select-key (LSK) actions:
1. **Input**: User types on the MCDU; input is echoed to the `scratchpad` state.
2. **Action**: `handleLSK` triggers validation against the target field (e.g., ICAO format).
3. **Execution**: Valid inputs commit to state, which updates autopilot targets; invalid inputs trigger a `scratchpadError`.

## ⚖️ License
This project is for training and educational purposes only. Not for use in actual flight operations.
