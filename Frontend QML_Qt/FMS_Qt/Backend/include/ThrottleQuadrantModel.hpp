#pragma once

#include <QString>

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

    // Get snap detent for a given TLA
    Detent getDetent(double tla) const {
        if (tla <= -5.0) return REVERSE;
        if (tla < 12.5) return IDLE;
        if (tla < 30.0) return CL;
        if (tla < 40.0) return MCT_FLX;
        return TOGA;
    }

    // Convert TLA (-20 to 45 deg) to normalized thrust command (0.0 to 1.0)
    double getNormalizedThrust(double tla) const {
        if (tla < 0.0) return 0.0; // Reverse handled separately
        return tla / 45.0;         // Linear mapping for simplicity
    }

    void tick(double dt) {
        // Handle autobrake or speedbrake arm conditions here
    }
};
