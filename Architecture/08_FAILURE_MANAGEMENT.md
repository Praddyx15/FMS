# 08 — Failure Management Architecture

## 1. Failure Engine Design

```cpp
class FailureEngine {
    struct FailureDefinition {
        QString id;                // unique identifier
        QString displayName;       // human-readable
        FailureCategory category;
        FailureSeverity severity;
        QStringList ecamMessages;  // ECAM warnings triggered
        QStringList affectedSystems;
        QStringList requiredActions; // expected pilot response (for grading)
        bool isMemoryItem;        // must be done from memory
    };

    struct ActiveFailure {
        QString failureId;
        double activationTime;
        FailureProgression progression;
        double progressionRate;   // for progressive failures
        double currentSeverity;   // 0.0 (onset) to 1.0 (full)
        TriggerType triggerType;
        bool acknowledged;        // pilot has seen ECAM
    };

    enum class FailureProgression {
        IMMEDIATE,     // full effect instantly
        PROGRESSIVE,   // ramps over time
        INTERMITTENT,  // comes and goes
        LATENT         // no immediate effect, cascades later
    };

    enum class TriggerType {
        MANUAL,        // instructor-triggered
        SCHEDULED,     // time-based
        CONDITIONAL,   // phase/altitude/speed-triggered
        RANDOM         // probability-based
    };
};
```

## 2. Failure Catalogue (A320-Specific)

### 2.1 Engine Failures

| ID | Name | ECAM | Effects |
|----|------|------|---------|
| `ENG1_FLAME_OUT` | ENG 1 Flame Out | `ENG 1 FAIL` | N1→0, thrust=0, gen1 off |
| `ENG2_FLAME_OUT` | ENG 2 Flame Out | `ENG 2 FAIL` | N1→0, thrust=0, gen2 off |
| `ENG1_FIRE` | ENG 1 Fire | `ENG 1 FIRE` | Fire loop trigger, memory item |
| `ENG2_FIRE` | ENG 2 Fire | `ENG 2 FIRE` | Fire loop trigger, memory item |
| `ENG1_OIL_LOW` | ENG 1 Low Oil | `ENG 1 OIL LO PR` | Progressive — N1 limited |
| `ENG1_SURGE` | ENG 1 Surge | `ENG 1 STALL` | Intermittent N1 fluctuation |
| `DUAL_ENG_FAIL` | Dual Engine Failure | `ENG 1+2 FAIL` | Glide, APU start attempt |

### 2.2 Hydraulic Failures

| ID | Name | ECAM | Effects |
|----|------|------|---------|
| `HYD_GREEN_LO` | Green Sys Low Press | `HYD G SYS LO PR` | Affects: NWS, gear retract, brakes |
| `HYD_BLUE_LO` | Blue Sys Low Press | `HYD B SYS LO PR` | Affects: slats, emergency gen |
| `HYD_YELLOW_LO` | Yellow Sys Low Press | `HYD Y SYS LO PR` | Affects: alt brakes, cargo doors |
| `HYD_GREEN_LEAK` | Green Sys Leak | `HYD G SYS OVHT` | Progressive pressure loss |
| `HYD_DUAL_FAIL` | Dual Hydraulic | `HYD G+B SYS LO PR` | Alternate law, gravity gear |

### 2.3 Electrical Failures

| ID | Name | ECAM | Effects |
|----|------|------|---------|
| `ELEC_GEN1_FAIL` | GEN 1 Failure | `ELEC GEN 1 FAULT` | Bus tie feeds AC1 |
| `ELEC_GEN2_FAIL` | GEN 2 Failure | `ELEC GEN 2 FAULT` | Bus tie feeds AC2 |
| `ELEC_DUAL_GEN` | Dual GEN Failure | `ELEC EMER CONFIG` | Emergency config, RAT deploys |
| `ELEC_BAT_FAIL` | Battery Failure | `ELEC BAT 1(2) FAULT` | Reduced backup |
| `ELEC_TR1_FAIL` | TR 1 Failure | `ELEC TR 1 FAULT` | DC bus 1 from TR2 |

### 2.4 Flight Control Failures

| ID | Name | ECAM | Effects |
|----|------|------|---------|
| `FCTL_ELAC1_FAIL` | ELAC 1 Failure | `F/CTL ELAC 1 FAULT` | ELAC 2 takes over |
| `FCTL_ELAC_DUAL` | Dual ELAC Failure | `F/CTL ALTN LAW` | Alternate law |
| `FCTL_SEC1_FAIL` | SEC 1 Failure | `F/CTL SEC 1 FAULT` | Reduced spoiler |
| `FCTL_FAC1_FAIL` | FAC 1 Failure | `F/CTL FAC 1 FAULT` | No yaw damper 1 |
| `FCTL_DIRECT_LAW` | Direct Law | `F/CTL DIRECT LAW` | No protections |
| `FCTL_RUDDER_JAM` | Rudder Jam | `F/CTL RUD TRV LIM` | Limited rudder travel |

### 2.5 Sensor / ADIRS Failures

| ID | Name | ECAM | Effects |
|----|------|------|---------|
| `ADIRS_IR1_FAIL` | IR 1 Failure | `NAV IR 1 FAULT` | Switch to IR2/3 |
| `ADIRS_ADR1_FAIL` | ADR 1 Failure | `NAV ADR 1 FAULT` | Unreliable airspeed PFD1 |
| `ADIRS_DUAL_IR` | Dual IR Failure | `NAV IR 1+2 FAULT` | ATT only from IR3 |
| `PITOT_BLOCK_L` | L Pitot Blockage | `NAV ADR 1 FAULT` | IAS frozen/erratic on PFD1 |
| `PITOT_BLOCK_DUAL` | Dual Pitot Block | `NAV ADR DISAGREE` | Unreliable airspeed procedure |
| `STATIC_BLOCK` | Static Port Block | — | Altitude frozen |

### 2.6 Navigation Failures

| ID | Name | Effects |
|----|------|---------|
| `NAV_GPS_FAIL` | GPS Failure | Position degrades to IRS+DME |
| `NAV_ILS_FAIL` | ILS Receiver Fail | No LOC/GS on approach |
| `NAV_VOR1_FAIL` | VOR 1 Failure | No VOR 1 display |
| `NAV_DME_FAIL` | DME Failure | No DME distance |
| `NAV_FMS_FAIL` | FMS 1 Failure | Switch to FMS 2 |
| `NAV_DUAL_FMS` | Dual FMS Failure | Selected NAV only |

### 2.7 Pressurization Failures

| ID | Name | ECAM | Effects |
|----|------|------|---------|
| `PRESS_EXCESS_CAB_ALT` | Excess Cabin Alt | `CAB PR EXCESS CAB ALT` | Memory item — emergency descent |
| `PRESS_OUTFLOW_FAIL` | Outflow Valve Fail | `CAB PR OUTFLOW VLV` | Manual pressurization |
| `PRESS_DUAL_PACK` | Dual Pack Failure | `AIR PACK 1+2 FAULT` | Descend below FL100 |
| `PRESS_RAPID_DEPRESS` | Rapid Depressurization | `CAB PR EXCESS CAB ALT` | Emergency descent, O2 masks |

---

## 3. Failure Cascading Logic

```
Example: ENG 1 FLAME OUT cascades:
  → ENG 1 N1 → 0
  → ENG 1 thrust → 0
  → GEN 1 → OFF (if no APU)
  → HYD Green (ENG 1 pump) → pressure decay (10s to 0)
  → If no ELEC PUMP: Green sys → LO PR
  → Pack 1 → OFF (if engine bleed was source)
  → Asymmetric thrust → yaw tendency
  → ECAM: "ENG 1 FAIL" → auto-display ENG page
```

```cpp
void FailureEngine::onFailureActivated(const QString& failureId) {
    // Cascade rules
    if (failureId == "ENG1_FLAME_OUT") {
        setEngineState(1, EngineState::SHUTDOWN);
        if (!isAPURunning()) {
            scheduleDelayed("ELEC_GEN1_FAIL", 0.5);  // 0.5s delay
        }
        scheduleDelayed("HYD_GREEN_ENG_PUMP_OFF", 1.0);
        triggerECAM("ENG 1 FAIL", ECAMLevel::WARNING);
    }
}
```

## 4. Failure Injection Modes

| Mode | Description |
|------|-------------|
| **Single** | One failure at a time |
| **Multiple** | Several concurrent failures |
| **Progressive** | Severity increases over time |
| **Random** | Configurable probability per flight hour |
| **Instructor** | Manual real-time injection |
| **Scripted** | Pre-programmed in scenario |
| **Conditional** | Triggered by flight state (alt, speed, phase) |
