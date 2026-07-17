#pragma once

#include <QString>

/**
 * ThrottleQuadrantModel — throttle levers, flap/speedbrake handles, gear,
 * autobrake selector, parking brake (Phase 3, IMPLEMENTATION_PLAN §3).
 *
 * Plain C++ (no QObject) so detent/arbitration logic is unit-testable in
 * isolation. AirDataComputer owns one instance and ticks it every frame.
 */
class ThrottleQuadrantModel
{
public:
    enum Detent {
        REVERSE,
        IDLE,
        CL,
        MCT_FLX,
        TOGA
    };

    double tla1 = 0.0; // throttle lever angle: -20.0 to 45.0 degrees
    double tla2 = 0.0;

    bool speedbrakeArmed = false;
    double speedbrakeLever = 0.0; // 0.0 (retracted) to 1.0 (fully extended)
    int flapHandleIndex = 0;       // 0=0, 1=1, 2=2, 3=3, 4=FULL
    bool gearDown = true;
    int autobrakeSelector = 0;    // 0=OFF, 1=LO, 2=MED, 3=MAX
    bool parkingBrake = true;

    // Outputs computed by tick() — read by AirDataComputer/QML, not written
    bool athrManualOverrideActive = false; // A/THR requested but a lever is above CL
    bool reverseInterlockTripped = false;  // lever in REVERSE zone while airborne

    // Get snap detent for a given TLA
    Detent getDetent(double tla) const {
        if (tla <= -5.0) return REVERSE;
        if (tla < 12.5) return IDLE;
        if (tla < 30.0) return CL;
        if (tla < 40.0) return MCT_FLX;
        return TOGA;
    }

    // Convert TLA (-20 to 45 deg) to normalized thrust command (0.0 to 1.0).
    // Reverse-zone TLA always yields zero forward thrust — EngineModel has no
    // reverse-thrust physics yet (Phase 3 remaining item).
    double getNormalizedThrust(double tla) const {
        if (tla < 0.0) return 0.0;
        return tla / 45.0;
    }

    /**
     * Advance by dt: speedbrake auto-deploy/retract on ground-state transition,
     * A/THR detent arbitration, and the reverse-thrust ground interlock.
     * athrRequested mirrors AutopilotController::athrActive for this tick.
     */
    void tick(double dt, bool onGround, bool athrRequested);

private:
    bool m_prevOnGround = false;
};
