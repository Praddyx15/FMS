# 15 — Airline-Grade Product Architecture Summary

This document describes the high-level product structure, target training syllabi, deployment topologies, and regulatory certification roadmap for the FMS-Trainer platform.

---

## 1. Product Overview

The FMS-Trainer is an airline-grade flight procedure and avionics training tool designed to simulate the flight dynamics, auto-flight systems, and cockpit interfaces of the Airbus A320neo (CFM LEAP-1A). It enables low-cost, high-fidelity procedures and FMC training on standard desktop hardware.

---

## 2. Target Training Syllabi & Use Cases

The trainer’s architecture directly supports the following professional aviation curricula:

### 2.1 Airbus Type Rating Preparation
* **Scope**: Normal procedures, flight patterns, MCDU inputs, and initialization sequences.
* **Trainer Modes**: Mode 1 (Cold & Dark), Mode 2 (Pre-flight MCDU Setup), Mode 3 (Engine Start & Taxi).

### 2.2 Multi-Crew Cooperation (MCC) & Jet Transition
* **Scope**: Crew coordination, autopilot mode awareness (FMA changes), and checklist execution.
* **Trainer Modes**: Mode 6 (Climb & Cruise), Mode 7 (Autopilot & Flight Director modes).

### 2.3 Abnormal & Emergency Training
* **Scope**: System malfunctions, ECAM warning management, and failure troubleshooting.
* **Trainer Modes**: Mode 11 (Failure and Abnormal Procedures), Mode 12 (Emergency Procedures).

### 2.4 Academic Aerospace & Engineering Education
* **Scope**: Flight dynamics analysis, control law study, and performance computations.
* **Trainer Modes**: Mode 9 (Aerodynamic Envelope and Laws), Mode 10 (Non-Precision Navigation & Approaches).

---

## 3. Product Deployment Topologies

The system is designed with a **local-first** approach to ensure reliability and low latency, with optional enterprise scale-up capabilities:

```
┌────────────────────────────────────────────────────────┐
│ Standalone Local Execution (Primary)                   │
│  - Runs completely offline on the host system          │
│  - No external database or cloud connection needed     │
│  - Stores logs and recordings locally                  │
└────────────────────────────────────────────────────────┘
                           │ (Optional network expansion)
                           ▼
┌────────────────────────────────────────────────────────┐
│ Local Area Network Classroom Topology                  │
│  - Instructor Station controls student PCs via LAN     │
│  - UDP broadcast or local TCP sockets                  │
│  - Real-time scenario control and failure injection    │
└────────────────────────────────────────────────────────┘
                           │ (Optional enterprise expansion)
                           ▼
┌────────────────────────────────────────────────────────┐
│ Enterprise Hybrid Cloud Topology                      │
│  - Syncs training records and reports to Supabase      │
│  - Tracks organization licenses and fleet configs      │
│  - Web-based admin dashboard for ATO management        │
└────────────────────────────────────────────────────────┘
```

---

## 4. Certification & Regulatory Compliance Roadmap

To qualify the platform for formal training credits, the architecture conforms to key standards:

### 4.1 Software Assurance (RTCA DO-178C / EUROCAE ED-12C)
* **Goal**: Level D software qualification for avionics simulations.
* **Implemented Controls**: Strictly typed C++20 structures, zero dynamic memory allocations after initialization to prevent heap fragmentation, and compiler-level exceptions disabled (`-fno-exceptions`).

### 4.2 Flight Simulation Training Devices (FSTD)
* **FAA FTD Level 4/5**: Meets requirements for cockpit layout, basic flight dynamics, and autopilot mode control panel responses.
* **EASA CS-FSTD FNPT II**: Supports navigation database validation, sound environment, and systems mock-ups for multi-crew cooperation.
