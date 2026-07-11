#pragma once

class GroundModel
{
public:
    bool onGround = true;
    double noseGearCompression = 1.0;
    double mainGearCompression = 1.0;

    // Runway friction (0.0 to 1.0)
    double mu = 0.8; // Dry default
    double runwayHeading = 270.0;
    double crosswindComponent = 0.0;

    // Braking
    double brakePressure = 0.0;
    int autobrakeMode = 0; // 0=OFF, 1=LO, 2=MED, 3=MAX
    double autobrakeDecel = 0.0; // target decel in m/s^2

    // Nosewheel steering
    double nosewheelAngle = 0.0; // deg (-75 to +75)
    double rudderSteerAngle = 0.0; // deg (-6 to +6)

    void tick(double dt, double altitudeGeometric) {
        onGround = (altitudeGeometric <= 5.0); // WoW threshold
        if (onGround) {
            noseGearCompression = 1.0;
            mainGearCompression = 1.0;
        } else {
            noseGearCompression = 0.0;
            mainGearCompression = 0.0;
            nosewheelAngle = 0.0;
            rudderSteerAngle = 0.0;
        }

        // Target autobrake decel rates
        if (autobrakeMode == 1) autobrakeDecel = 1.7;      // LO
        else if (autobrakeMode == 2) autobrakeDecel = 3.0; // MED
        else if (autobrakeMode == 3) autobrakeDecel = 6.0; // MAX
        else autobrakeDecel = 0.0;
    }
};
