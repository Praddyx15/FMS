# 06 — Cockpit Displays & UI Architecture

## 1. Primary Flight Display (PFD)

### Required Elements

```
┌─────────────────────────────────────────────────────┐
│  FMA (5 columns)                                     │
│  [THR CLB] [CLB ] [NAV ] [CAT 3 DUAL] [AP1+2 A/THR]│
│           [     ] [LOC ] [           ] [            ]│
├────────┬────────────────────────────┬───────────────┤
│ SPEED  │     ATTITUDE INDICATOR     │  ALTITUDE     │
│ TAPE   │                            │  TAPE         │
│        │         ─── ──── ───       │               │
│  ─250  │        /              \    │  32100─       │
│  ─240  │  ───  │   ◇    ◇      │   │  32000─  ←FL │
│  ─230  │       │  (aircraft)   │    │  31900─       │
│  ─220  │        \              /    │  31800─       │
│        │         ─── ──── ───       │               │
│        │     FD bars: + / ×         │               │
│  VLS   │                            │  ALT target   │
│  αprot │     ILS LOC: ◇───◇───◇    │  (cyan)       │
│  αmax  │                            │               │
├────────┤    HEADING / TRACK         ├───────────────┤
│ SPD    │  ← 280 ─ 290 ─ 300 → ▽    │  VS ±0       │
│ TREND  │                            │  VS scale     │
├────────┴────────────────────────────┴───────────────┤
│  ILS: 110.30/09L    DME: 12.5                       │
└─────────────────────────────────────────────────────┘
```

### FMA 5-Column Layout (A320 Standard)

| Column | Position | Content |
|--------|----------|---------|
| 1 (left) | Speed/thrust | `THR CLB`, `SPEED`, `MACH`, `THR IDLE`, `A.FLOOR` |
| 2 | Vertical | Active: `CLB`, `DES`, `ALT`, `VS`, `GS` / Armed: `ALT` |
| 3 | Lateral | Active: `NAV`, `HDG`, `LOC` / Armed: `NAV`, `LOC` |
| 4 | Approach | `CAT 1`, `CAT 2`, `CAT 3 SINGLE`, `CAT 3 DUAL` |
| 5 (right) | Engagement | `AP1`, `AP2`, `1FD2`, `1FD-`, `A/THR` |

**Color coding**: Green = engaged, Blue (cyan) = armed, White = selected target, Amber = caution

### Speed Tape Color Bands

| Band | Color | Meaning |
|------|-------|---------|
| VFE (next config) | Amber | Maximum for flap config |
| VMO/MMO | Red/black | Never exceed |
| VLS | Amber | Lowest selectable |
| α-prot | Orange | Alpha protection speed |
| α-max | Red | Maximum alpha (stall) |
| Green dot | Green ◇ | Best L/D clean |
| F speed | Green ◇ | Flap retract speed |
| S speed | Green ◇ | Slat retract speed |
| V1/VR/V2 | Cyan markers | Takeoff V-speeds |

### Current Gaps
- FMA is basic, not 5-column standard
- Speed tape has V-speed bugs but incomplete color bands
- Altitude tape missing cyan target box
- No metric altitude toggle
- No radio altitude indication
- ILS readout incomplete

---

## 2. Navigation Display (ND)

### 5 Modes (All Implemented ✅)

| Mode | Description | Status |
|------|-------------|--------|
| ROSE ILS | 360° compass, ILS deviation bars | ✅ |
| ROSE VOR | 360° compass, VOR/DME bearing | ✅ |
| ROSE NAV | 360° compass, flight plan overlay | ✅ |
| ARC | Forward-looking 120° arc | ✅ |
| PLAN | North-up, aircraft moves on plan | ✅ |

### ND Overlay Requirements

| Overlay | Button | Current | Gap |
|---------|--------|---------|-----|
| WXR (Weather) | WXR | ✅ mock blobs | Need parametric weather model |
| TERR (Terrain) | TERR | ✅ stipple dots | Need real elevation data |
| TCAS (Traffic) | TCAS | ✅ symbols | Need TA/RA resolution logic |
| VOR/NDB (Navaids) | VOR | ✅ | — |
| WPT (Waypoints) | WPT | ✅ | — |
| CSTR (Constraints) | CSTR | ❌ | **Need constraint display** |
| ARPT (Airports) | ARPT | ❌ | **Need airport display** |

### ND Symbols (A320 Standard)

```
Flight Plan waypoint:  ◇ (green diamond)
Active waypoint:       ◇ (white diamond, filled)
Off-route fix:         ★ (magenta star)
VOR:                   ⎔ (hexagon, green)
NDB:                   ▲ (triangle, green)
Airport:               ✈ (or ○, magenta)
TOC:                   ↑ (white arrow up)
TOD:                   ↓ (white arrow down)
Speed change:          ─── (speed constraint marker)
Altitude constraint:   = (constraint marker)
Range rings:           dashed white arcs
Heading bug:           cyan triangle
Track line:            green dashed
```

---

## 3. ECAM (Electronic Centralized Aircraft Monitor)

### Upper ECAM (Engine/Warning Display)

```
┌─────────────────────────────────────────┐
│           ENGINE PARAMETERS              │
│                                          │
│    N1%        EGT°C        N1%          │
│   ┌──┐      ┌──┐        ┌──┐          │
│   │87│      │680│        │87│          │
│   └──┘      └──┘        └──┘          │
│   ENG 1                    ENG 2        │
│                                          │
│   FF: 1250 kg/hr      FF: 1250 kg/hr   │
│                                          │
│   FUEL: 12000 kg                        │
│   FLAPS: 0    SLATS: 0                 │
│                                          │
│   ─── MEMO / WARNING MESSAGES ───       │
│   T.O INHIBIT                           │
│   GND SPOILERS ARMED                    │
├─────────────────────────────────────────┤
│           ECAM WARNINGS                  │
│   (caution/warning messages here)        │
└─────────────────────────────────────────┘
```

### Lower ECAM System Pages

| Page | Button | Current | Status |
|------|--------|---------|--------|
| ENGINE | ENG | ✅ | Display only — needs state-driven data |
| BLEED | BLEED | ✅ | Display only |
| PRESSURIZATION | PRESS | ✅ | Display only |
| ELECTRICAL | ELEC | ✅ | Display only |
| HYDRAULIC | HYD | ✅ | Display only |
| FUEL | FUEL | ✅ | Display only |
| APU | APU | ✅ | Display only |
| AIR CONDITIONING | COND | ✅ | Display only |
| DOORS | DOOR | ✅ | Display only |
| WHEELS | WHEEL | ✅ | Display only |
| FLIGHT CONTROLS | F/CTL | ✅ | Display only |
| CRUISE | CRUISE | ✅ | Display only |

**Critical Gap**: All 12 pages render static/mock data. They must read from `SystemsManager` for hydraulic pressures, electrical bus voltages, bleed temps, etc.

---

## 4. Overhead Panel Architecture

### Required Panels (Currently 3-Toggle Stub → Full Required)

```
┌─────────────────────────────────────────────────────┐
│                  OVERHEAD PANEL                      │
│                                                      │
│  ┌─ ADIRS ──────────────────────────────────────┐   │
│  │  IR1 [OFF/STBY/NAV]  IR2 [OFF/STBY/NAV]     │   │
│  │  IR3 [OFF/STBY/NAV]  ON BAT light           │   │
│  └──────────────────────────────────────────────┘   │
│  ┌─ ELECTRICAL ─────────────────────────────────┐   │
│  │  GEN1 [ON] GEN2 [ON]  APU GEN [ON/OFF]      │   │
│  │  BAT1 [ON] BAT2 [ON]  EXT PWR [ON/OFF]      │   │
│  │  BUS TIE [AUTO]       AC ESS FEED [NORM/ALTN]│   │
│  └──────────────────────────────────────────────┘   │
│  ┌─ HYDRAULIC ──────────────────────────────────┐   │
│  │  ENG1 PUMP [ON]  ENG2 PUMP [ON]              │   │
│  │  ELEC PUMP BLUE [ON]  ELEC PUMP YELLOW [ON]  │   │
│  │  PTU [AUTO]       RAT [STOW/EXTEND]          │   │
│  └──────────────────────────────────────────────┘   │
│  ┌─ FUEL ───────────────────────────────────────┐   │
│  │  L TK PUMP 1 [ON]  R TK PUMP 1 [ON]         │   │
│  │  L TK PUMP 2 [ON]  R TK PUMP 2 [ON]         │   │
│  │  CTR TK L [ON]  CTR TK R [ON]                │   │
│  │  X FEED [OPEN/CLOSED]  MODE SEL [AUTO/MAN]   │   │
│  └──────────────────────────────────────────────┘   │
│  ┌─ PNEUMATIC / BLEED ─────────────────────────┐   │
│  │  ENG1 BLEED [ON]  ENG2 BLEED [ON]           │   │
│  │  APU BLEED [ON/OFF]  X BLEED [SHUT/OPEN/AUTO]│   │
│  │  PACK 1 [ON]  PACK 2 [ON]                    │   │
│  └──────────────────────────────────────────────┘   │
│  ┌─ AIR CONDITIONING ──────────────────────────┐   │
│  │  CKPT TEMP [24°C]  FWD CABIN [24°C]         │   │
│  │  AFT CABIN [24°C]  HOT AIR [ON]             │   │
│  └──────────────────────────────────────────────┘   │
│  ┌─ PRESSURIZATION ────────────────────────────┐   │
│  │  MODE SEL [AUTO]  LDG ELEV [AUTO/xxxx]      │   │
│  │  DITCHING [OFF]                               │   │
│  └──────────────────────────────────────────────┘   │
│  ┌─ FIRE PROTECTION ──────────────────────────┐   │
│  │  ENG1 FIRE [pb]  APU FIRE [pb]  ENG2 FIRE  │   │
│  │  ENG1 AGENT 1/2  APU AGENT  ENG2 AGENT 1/2 │   │
│  └──────────────────────────────────────────────┘   │
│  ┌─ APU ────────────────────────────────────────┐   │
│  │  MASTER SW [ON/OFF]  START [ON/OFF]          │   │
│  └──────────────────────────────────────────────┘   │
│  ┌─ ANTI-ICE ──────────────────────────────────┐   │
│  │  WING [ON/OFF]  ENG1 [ON/OFF]  ENG2 [ON/OFF]│   │
│  │  PROBE HEAT [AUTO]                            │   │
│  └──────────────────────────────────────────────┘   │
│  ┌─ SIGNS ─────────────────────────────────────┐   │
│  │  SEAT BELTS [ON/OFF]  NO SMOKING [ON/AUTO]   │   │
│  │  EMER EXIT LT [ON/OFF/ARM]                    │   │
│  └──────────────────────────────────────────────┘   │
│  ┌─ LIGHTING ──────────────────────────────────┐   │
│  │  STROBE [ON/AUTO/OFF]  BEACON [ON/OFF]       │   │
│  │  NAV [1/2/OFF]  LAND L/R [ON/OFF/RETRACT]   │   │
│  │  NOSE [T.O/TAXI/OFF]                          │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

**Every switch must drive actual aircraft state** — no decorative switches.

---

## 5. UI Architecture Principles

1. **QML reads Q_PROPERTY only** — never computes flight data
2. **Canvas displays throttled** — PFD 12.5 Hz, ND 10 Hz (memory bounded)
3. **Theme singleton** — all colors via `Theme.qml` (cockpit-grade palette)
4. **Loader-based views** — only active view in memory (MainLayout pattern)
5. **Flickable+WheelHandler** — no ScrollView (memory leak risk)
6. **Future migration path** — Canvas → QQuickPaintedItem → Scene Graph for 30+ Hz
