#pragma once

/**
 * EngineModel — CFM LEAP-1A engine pair (Phase 1 decomposition of the
 * AirDataComputer monolith; IMPLEMENTATION_PLAN §3 Phase 1 / Phase 3).
 *
 * Plain C++ (no QObject) so it is unit-testable in isolation. AirDataComputer
 * owns one instance and forwards its Q_PROPERTY getters to this state.
 *
 * Phase 1 preserves the legacy behaviour exactly (first-order N1 lag, linear
 * EGT map). Phase 3 replaces the internals with the N1/N2 spool dynamics, EGT
 * lookup with thermal lag, fuel flow, and start sequence per Architecture doc
 * 03 §4 — behind this same interface.
 */
class EngineModel
{
public:
    // Thrust command per engine (legacy 0..~50 scale; ~thrust % of one engine)
    double thrust1 = 30.0;
    double thrust2 = 30.0;

    // Engine state (published to QML via AirDataComputer)
    double n1Left   = 67.0;   // % N1
    double n1Right  = 67.0;
    double egtLeft  = 750.0;  // °C
    double egtRight = 750.0;

    /**
     * Advance the engine model by dt seconds.
     * fire1/fire2: engine-fire failure active — thrust decays, spool-up inhibited.
     */
    void tick(double dt, bool fire1, bool fire2);

private:
    // Legacy tuning constants (Phase 3 replaces with LEAP-1A data tables)
    static constexpr double kN1PerThrust     = 2.1;   // N1 target per thrust unit
    static constexpr double kN1LagPerSec     = 1.0;   // first-order lag gain /s
    static constexpr double kN1Max           = 105.0; // % clamp
    static constexpr double kEgtBase         = 400.0; // °C at N1=0
    static constexpr double kEgtPerN1        = 5.0;   // °C per % N1
    static constexpr double kFireDecayPerSec = 5.0;   // thrust units lost /s in fire
};
