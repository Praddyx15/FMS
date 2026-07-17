#include "GroundModel.hpp"

#include <algorithm>
#include <cmath>

void GroundModel::tick(double /*dt*/, double altitudeGeometric,
                       double hydraulicBrakingMultiplier, double rudderPedalNormalized)
{
    onGround = (altitudeGeometric <= 5.0); // WoW threshold
    if (onGround) {
        noseGearCompression = 1.0;
        mainGearCompression = 1.0;
    } else {
        noseGearCompression = 0.0;
        mainGearCompression = 0.0;
        nosewheelAngle = 0.0;
        rudderSteerAngle = 0.0;
        headingRateDegPerSec = 0.0;
    }

    // Runway friction from surface condition (Architecture doc 03 §5)
    switch (runwayCondition) {
        case WET: mu = 0.3; break;
        case ICY: mu = 0.1; break;
        default:  mu = kMuDry; break;
    }

    // Target autobrake decel rates (dry-runway calibration, m/s^2)
    if (autobrakeMode == 1) autobrakeDecel = 1.7;      // LO
    else if (autobrakeMode == 2) autobrakeDecel = 3.0; // MED
    else if (autobrakeMode == 3) autobrakeDecel = 6.0; // MAX
    else autobrakeDecel = 0.0;

    // Scale by runway friction relative to dry, then by hydraulic-channel
    // availability — a failed/degraded braking channel reduces or removes
    // stopping performance regardless of autobrake selector or surface.
    double muScale = std::clamp(mu / kMuDry, 0.0, 1.0);
    double hydScale = std::clamp(hydraulicBrakingMultiplier, 0.0, 1.0);
    effectiveAutobrakeDecel = autobrakeDecel * muScale * hydScale;

    // Nosewheel steering from rudder pedal (±6°) — mechanically available at
    // any ground speed; tiller (±75°) has no UI input source yet.
    if (onGround) {
        rudderSteerAngle = std::clamp(rudderPedalNormalized, -1.0, 1.0) * 6.0;
        headingRateDegPerSec = std::clamp(rudderSteerAngle * 0.5, -3.0, 3.0);
    }
}
