#pragma once

/**
 * GroundModel — weight-on-wheels, braking, and nosewheel steering
 * (Phase 3, IMPLEMENTATION_PLAN §3).
 *
 * Plain C++ (no QObject) so WoW/braking/steering logic is unit-testable in
 * isolation. AirDataComputer owns one instance and ticks it every frame,
 * bridging in the hydraulic braking-channel multiplier from SystemsManager
 * (GroundModel itself stays decoupled from SystemsManager).
 */
class GroundModel
{
public:
    enum RunwayCondition { DRY = 0, WET = 1, ICY = 2 };

    bool onGround = true;
    double noseGearCompression = 1.0;
    double mainGearCompression = 1.0;

    // Runway friction (0.0 to 1.0) — recomputed from runwayCondition each tick
    double mu = 0.5; // Dry default (Architecture doc 03 §5 surface table)
    int runwayCondition = DRY;
    double runwayHeading = 270.0;
    double crosswindComponent = 0.0;

    // Braking
    double brakePressure = 0.0;
    int autobrakeMode = 0; // 0=OFF, 1=LO, 2=MED, 3=MAX
    double autobrakeDecel = 0.0;         // dry-runway target decel, m/s^2 (pre-scaling)
    double effectiveAutobrakeDecel = 0.0; // after mu + hydraulic-channel scaling — use this for physics

    // Nosewheel steering
    double nosewheelAngle = 0.0;    // deg (-75 to +75, tiller — no UI source yet)
    double rudderSteerAngle = 0.0;  // deg (-6 to +6, driven by rudder pedal input)
    double headingRateDegPerSec = 0.0; // steering effect output for AirDataComputer to apply

    /**
     * Advance by dt. hydraulicBrakingMultiplier: 1.0 = normal (Green/Yellow
     * available), reduced for ALTERNATE/ACCUMULATOR channels, 0.0 = no
     * hydraulic braking available at all (SystemsManager::getBrakingChannel).
     * rudderPedalNormalized: -1..+1, mirrors AirDataComputer's rudderPedal input.
     */
    void tick(double dt, double altitudeGeometric,
              double hydraulicBrakingMultiplier, double rudderPedalNormalized);

private:
    static constexpr double kMuDry = 0.5; // Architecture doc 03 §5: concrete/asphalt dry
};
