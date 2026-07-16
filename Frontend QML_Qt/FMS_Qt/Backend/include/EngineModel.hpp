#pragma once

#include <QString>

/**
 * EngineModel — CFM LEAP-1A engine pair (Phase 3 implementation).
 *
 * Plain C++ (no QObject) so it is unit-testable in isolation. AirDataComputer
 * owns one instance and forwards its Q_PROPERTY getters to this state.
 */
class EngineModel
{
public:
    // Inputs (commanded values)
    double thrustLeverAngle1 = 0.3; // 0.0 to 1.0
    double thrustLeverAngle2 = 0.3;
    bool started1 = true;
    bool started2 = true;
    bool fuelValveOpen1 = true;
    bool fuelValveOpen2 = true;
    bool starterActive1 = false;
    bool starterActive2 = false;

    // Public engine states (accessed by AirDataComputer facade)
    double n1Left = 67.0;   // % N1
    double n1Right = 67.0;
    double egtLeft = 750.0; // °C
    double egtRight = 750.0;

    // Additional detailed CFM LEAP-1A states
    double n2Left = 82.0;   // % N2
    double n2Right = 82.0;
    double ffLeft = 600.0;  // kg/hr
    double ffRight = 600.0;
    double oilPressureLeft = 80.0;  // psi
    double oilPressureRight = 80.0;
    double oilTempLeft = 90.0;      // °C
    double oilTempRight = 90.0;
    double vibN1Left = 0.5;   // mils
    double vibN1Right = 0.5;
    double vibN2Left = 0.6;   // mils
    double vibN2Right = 0.6;

    // Output thrust in Newtons
    double thrustN1 = 45000.0;
    double thrustN2 = 45000.0;
    double bleedFlow1 = 1.2;  // kg/s
    double bleedFlow2 = 1.2;

    // Legacy backwards compatibility variables (mapped to leverage command)
    double thrust1 = 30.0;
    double thrust2 = 30.0;

    /**
     * Detailed physical tick update.
     */
    void tick(double dt, double altFt, double mach, double oatKelvin, bool fire1, bool fire2);

private:
    void tickEngine(double dt, double altFt, double mach, double oatKelvin, bool fire,
                    double tla, bool &started, bool &fuelValve, bool &starter,
                    double &n1, double &n2, double &egt, double &ff,
                    double &oilP, double &oilT, double &vib1, double &vib2,
                    double &thrustN, double &bleedFlow);

    // CFM LEAP-1A Constants
    static constexpr double kMaxThrustSL = 132000.0; // N (132 kN per engine)
    static constexpr double kN1Idle = 19.5;
    static constexpr double kN2Idle = 55.0;
};
