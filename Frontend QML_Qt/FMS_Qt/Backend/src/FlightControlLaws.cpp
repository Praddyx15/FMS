#include "FlightControlLaws.hpp"

#include <algorithm>

void FlightControlLaws::updateAttitude(double dt, double turbPitch, double turbRoll,
                                       bool apEngaged, double &pitch, double &roll)
{
    if (!apEngaged) {
        pitch = std::clamp(pitch + turbPitch * dt * 5.0, -kPitchLimitDeg, kPitchLimitDeg);
        roll  = std::clamp(roll  + turbRoll  * dt * 3.0, -kRollLimitDeg,  kRollLimitDeg);
    } else {
        // Smooth to trim attitude
        pitch += (kTrimPitchDeg - pitch) * dt * 2.0;
        roll  += (0.0           - roll)  * dt * 2.0;
    }
}

void FlightControlLaws::applyManual(double pitchCmd, double rollCmd,
                                    double &pitch, double &roll)
{
    pitch = std::clamp(pitchCmd, -kPitchLimitDeg, kPitchLimitDeg);
    roll  = std::clamp(rollCmd,  -kRollLimitDeg,  kRollLimitDeg);
}
