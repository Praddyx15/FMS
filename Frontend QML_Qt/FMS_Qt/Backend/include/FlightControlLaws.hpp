#pragma once

/**
 * FlightControlLaws — attitude behaviour and manual-input limits (Phase 1
 * decomposition of the AirDataComputer monolith; IMPLEMENTATION_PLAN §3).
 *
 * Phase 1 preserves legacy behaviour (turbulence drift when AP off, smooth
 * return to trim when AP on, hard clamps on manual input). Phase 5 grows this
 * into the Normal/Alternate/Direct law implementation (C* pitch, roll-rate
 * demand, protections — doc 05 §3).
 */
class FlightControlLaws
{
public:
    // Legacy manual-attitude limits (Normal Law protections arrive in Phase 5)
    static constexpr double kPitchLimitDeg = 20.0;
    static constexpr double kRollLimitDeg  = 30.0;
    static constexpr double kTrimPitchDeg  = 2.5;

    /**
     * Advance pitch/roll by dt: turbulence drift when the AP is off,
     * smooth capture of the trim attitude when the AP is engaged.
     */
    static void updateAttitude(double dt, double turbPitch, double turbRoll,
                               bool apEngaged, double &pitch, double &roll);

    /** Clamp and apply a manual (yoke/sidestick) attitude demand. */
    static void applyManual(double pitchCmd, double rollCmd,
                            double &pitch, double &roll);
};
