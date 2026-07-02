# 12 — Compliance & Certification Readiness

## 1. Compliance Reference Matrix

| Standard | Relevance | Current Status | Target |
|----------|-----------|---------------|--------|
| **ARINC 424** | Navigation database format | ✅ CIFP parser exists | Extend for full record types |
| **ARINC 429** | Avionics data bus protocol | Conceptual mapping only | Label-based DataBus traceability |
| **ARINC 653** | Partitioned OS for avionics | N/A (desktop app) | Thread isolation mimics partitioning |
| **ARINC 661** | Cockpit display standard | N/A (QML-based) | Widget-based display architecture |
| **ARINC 664** | AFDX data network | N/A (single host) | Future multi-host networking |
| **ARINC 702A** | FMS functional standard | Partial | Full route/perf/prediction architecture |
| **DO-178C** | Software certification | Design patterns only | Coding standards adherence |
| **DO-254** | Hardware certification | N/A | Reference docs in `Coding standards/` |
| **DO-330** | Tool qualification | N/A | Test framework qualification |
| **MISRA C++:2023** | Safe C++ coding | Referenced in docs | Apply via static analysis |
| **JSF AV C++** | Fighter jet C++ rules | PDF in `Coding standards/` | Apply critical rules |
| **FAA AC 120-45A** | Flight training device criteria | Reference | Design for FSTD Level 4-5 concepts |
| **EASA CS-FSTD(A)** | Flight simulation training device | Reference | Design for FTD Level 1-2 concepts |
| **Airbus FCOM** | Flight crew operating manual | Conceptual reference | All procedures traceable to FCOM |
| **Airbus FCTM** | Flight crew techniques manual | Conceptual reference | Training scenarios match FCTM |
| **Airbus QRH** | Quick reference handbook | Conceptual reference | Emergency procedures from QRH |

> [!IMPORTANT]
> This platform does NOT claim DO-178C certification. It is designed with **certification-readiness**
> patterns so that methodology, traceability, and code quality align with certified system expectations.

---

## 2. DO-178C Alignment (Design Patterns Only)

### 2.1 Objectives Applied

| DO-178C Objective | Our Implementation |
|-------------------|--------------------|
| Requirements traceability | Each module maps to architecture document section |
| Design traceability | C++ class → architecture block → requirement |
| Source code standards | MISRA/JSF subset enforced |
| Code review | All backend changes peer-reviewed |
| Unit testing | Catch2/GoogleTest framework (target 80% coverage) |
| Integration testing | Scenario-based test harnesses |
| Configuration management | Git with tagged releases |
| No dynamic allocation in runtime | Pre-allocated containers in sim loop |
| Deterministic execution | Fixed-interval timer (80ms), no exceptions |
| Boundary protection | All inputs clamped, division guards, NaN checks |

### 2.2 Safety-Critical Coding Rules Applied

```cpp
// Rule: No dynamic allocation in simulation loop
// ✅ Correct:
std::array<Waypoint, 256> m_waypointBuffer;  // pre-allocated
int m_waypointCount = 0;

// ❌ Violation:
std::vector<Waypoint> waypoints;
waypoints.push_back(wpt);  // heap allocation in sim loop

// Rule: Division-by-zero protection
double safeDiv(double num, double den) {
    if (std::abs(den) < 1e-7)
        den = std::copysign(1e-7, den);
    return num / den;
}

// Rule: NaN/Inf guard
double safeSqrt(double x) {
    return std::sqrt(std::max(0.0, x));
}

// Rule: Physical clamps
altitude = std::clamp(altitude, 0.0, 41000.0);
ias = std::clamp(ias, 0.0, 450.0);
pitch = std::clamp(pitch, -30.0, 30.0);
roll = std::clamp(roll, -67.0, 67.0);
```

---

## 3. Existing Coding Standards Reference

Files in `Coding standards/` directory:

| Document | Content | Relevance |
|----------|---------|-----------|
| `DO-178C_WhitePaper_v3.0.pdf` | Software certification overview | Architecture patterns |
| `Do-178C.pdf` | Standard reference | Process guidance |
| `JSF-AV-rules.pdf` | Joint Strike Fighter C++ rules | Safe C++ coding rules |
| `SafetyCriticalC++.pdf` | Safety-critical C++ guidelines | Memory/exception rules |
| `do-254-explained-wp.pdf` | Hardware certification | FPGA/hardware reference |
| `mil-std-1553-programmers-guide.pdf` | MIL-STD-1553 data bus | Avionics bus concepts |
| `NASA-CR-2017-219371.pdf` | NASA flight software reference | Verification patterns |
| `TC-17-67.pdf` | Transport Canada guidance | Regulatory framework |
| `DCGA-SOP-GNSS-Spoofing-1.pdf` | GNSS spoofing procedures | Navigation safety |
| `DGCA-Circular-on-GNSS-Spoofing.pdf` | GNSS circular | Navigation reference |
| `3167132.3167268.pdf` | Academic paper | Research reference |

---

## 4. Certification-Readiness Checklist

### Architecture Level

- [x] Modular architecture with clear interfaces
- [x] Data bus pattern (single source of truth)
- [x] Thread safety (mutex-protected data)
- [ ] Formal requirements specification
- [ ] Requirements-to-code traceability matrix
- [ ] Formal interface control documents (ICDs)
- [ ] Hazard analysis

### Code Level

- [x] No exceptions in sim loop (`-fno-exceptions` mentioned)
- [x] Boundary validation on all physics computations
- [x] Physical parameter clamping
- [ ] Zero dynamic allocation audit (partially done)
- [ ] MISRA C++ static analysis pass
- [ ] Full unit test coverage (>80%)
- [ ] Formal code review records

### Training Device Level (FAA AC 120-45A / EASA CS-FSTD)

- [x] Representative cockpit displays (PFD, ND, MCDU, ECAM)
- [x] FCU with push/pull managed/selected logic
- [ ] Full overhead panel functionality
- [ ] Ground handling (taxi, takeoff, landing)
- [ ] Complete autopilot mode set
- [ ] Performance computation (V-speeds, fuel)
- [ ] Navigation database with AIRAC cycle
- [ ] Instructor operating station (functional)
- [ ] Recording and replay capability
- [ ] Visual display system (out-the-window) — not in scope

### Data Integrity

- [x] ARINC 424 navigation data parser
- [x] Supabase with RLS policies
- [ ] AIRAC cycle versioning
- [ ] Data checksum validation
- [ ] Audit trail for all data modifications

---

## 5. Training Device Classification Target

| Level | Standard | Description | Our Target |
|-------|----------|-------------|------------|
| FTD Level 4 | AC 120-45A | Representative controls, displays, systems | ✅ Primary target |
| FTD Level 5 | AC 120-45A | + Aerodynamic programming, ground handling | ✅ Stretch goal |
| FFS Level A | AC 120-40B | Full flight simulator (motion, visual) | ❌ Out of scope |
| FSTD Level 1 | CS-FSTD(A) | EASA flight training device | ✅ Design reference |

> [!NOTE]
> The platform is designed to meet FTD Level 4-5 conceptual requirements for:
> - Representative cockpit instruments and controls
> - Aerodynamic model with flight envelope
> - Systems simulation with failure states
> - Navigation with database
> - Instructor operating capabilities
>
> Physical motion, visual systems, and formal qualification testing are out of scope
> for a desktop training platform.

---

## 6. Migration Path from Current → Airline-Grade

```
Current State (v1.0):
  ✅ Working 6-DOF simulation
  ✅ Functional MCDU (31 pages)
  ✅ PFD/ND/ECAM displays
  ✅ Basic AP (HDG, ALT, VS)
  ✅ ARINC 424 parser
  ✅ Supabase schema (26 tables)
  ❌ Monolithic AirDataComputer
  ❌ No ground model
  ❌ No systems simulation
  ❌ No training framework
  ❌ No recording/replay

Target State (v2.0):
  ✅ Modular architecture (8+ C++ libraries)
  ✅ Complete AP/FD/A-THR mode set
  ✅ LEAP-1A engine model
  ✅ Ground model (taxi through landing)
  ✅ Full systems simulation
  ✅ 12 training modes
  ✅ Instructor station with full control
  ✅ Recording/replay/assessment
  ✅ Failure engine with 40+ failures
  ✅ Multi-tenant Supabase (36 tables)
  ✅ Multi-user ready

Migration Strategy:
  Phase 1-3: Refactor + aircraft core (weeks 1-12)
  Phase 4-5: FMS + autopilot (weeks 10-18)
  Phase 6-8: Training + failures + instructor (weeks 16-24)
  Phase 9-10: Multi-user + polish (weeks 22-30)
```
