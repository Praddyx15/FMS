#include "EngineModel.hpp"
#include <cmath>
#include <algorithm>

void EngineModel::tick(double dt, double altFt, double mach, double oatKelvin, bool fire1, bool fire2)
{
    // Update both engines independently
    tickEngine(dt, altFt, mach, oatKelvin, fire1, thrustLeverAngle1, started1, fuelValveOpen1, starterActive1,
               n1Left, n2Left, egtLeft, ffLeft, oilPressureLeft, oilTempLeft, vibN1Left, vibN2Left, thrustN1, bleedFlow1);

    tickEngine(dt, altFt, mach, oatKelvin, fire2, thrustLeverAngle2, started2, fuelValveOpen2, starterActive2,
               n1Right, n2Right, egtRight, ffRight, oilPressureRight, oilTempRight, vibN1Right, vibN2Right, thrustN2, bleedFlow2);

    thrust1 = n1Left;
    thrust2 = n1Right;
}

void EngineModel::tickEngine(double dt, double altFt, double mach, double oatKelvin, bool fire,
                             double tla, bool &started, bool &fuelValve, bool &starter,
                             double &n1, double &n2, double &egt, double &ff,
                             double &oilP, double &oilT, double &vib1, double &vib2,
                             double &thrustN, double &bleedFlow)
{
    if (fire) {
        // Fire logic: decay everything, cut starters and fuel
        starter = false;
        fuelValve = false;
        started = false;
        n1 = std::max(0.0, n1 - dt * 10.0); // Spool down
        n2 = std::max(0.0, n2 - dt * 15.0);
        egt = std::max(oatKelvin - 273.15, egt - dt * 25.0);
        ff = 0.0;
        oilP = std::max(0.0, oilP - dt * 20.0);
        oilT = std::max(oatKelvin - 273.15, oilT - dt * 5.0);
        vib1 = std::max(0.0, vib1 + dt * 2.0); // Fire might cause vibrations
        vib2 = std::max(0.0, vib2 + dt * 2.0);
        thrustN = 0.0;
        bleedFlow = 0.0;
        return;
    }

    // Start sequence / motoring logic
    if (starter && !started) {
        // Spool core N2 up using starter motor up to motoring speed ~30%
        n2 += (30.0 - n2) * dt * 0.15;
        // Low windmilling N1
        n1 += (5.0 - n1) * dt * 0.1;
    }

    // Ignition checklist: fuel valve open, starter has spun N2 past 22%
    if (fuelValve && n2 >= 22.0 && !started) {
        started = true;
    }

    double n1Target = 0.0;
    double n2Target = 0.0;

    if (started) {
        // Self-sustaining combustion
        n1Target = kN1Idle + (100.0 - kN1Idle) * tla;
        n2Target = kN2Idle + (100.0 - kN2Idle) * tla;
        
        // Starter cut-off once above 55% N2
        if (n2 >= 55.0) {
            starter = false;
        }
    } else if (!starter) {
        // Sub-idle / windmilling decel
        n1Target = 5.0 * mach; // Small windmilling
        n2Target = 8.0 * mach;
    }

    // Spool time constant selection
    double tauN1 = 2.0;
    if (n1Target > n1) {
        tauN1 = (n1 < 30.0) ? 4.0 : 1.0; // Slow spool from idle, fast once spooled
    } else {
        tauN1 = 2.0; // Decel
    }

    n1 += (n1Target - n1) * dt / tauN1;
    n2 += (n2Target - n2) * dt / 1.5;

    n1 = std::clamp(n1, 0.0, 105.0);
    n2 = std::clamp(n2, 0.0, 105.0);

    // EGT calculation
    double egtTarget = oatKelvin - 273.15 + n1 * 6.0;
    // Add start ignition EGT spike
    if (started && n2 < 55.0) {
        double startSpike = 350.0 * std::sin((n2 - 22.0) / (55.0 - 22.0) * 3.14159265);
        egtTarget += std::max(0.0, startSpike);
    }
    egt += (egtTarget - egt) * dt / 3.0; // Thermal lag
    egt = std::clamp(egt, -50.0, 1200.0);

    // Fuel Flow (FF) kg/hr
    if (started) {
        ff = n1 * 15.0 * (1.0 - 0.000015 * altFt);
        ff = std::max(300.0, ff); // Minimum fuel flow when running
    } else {
        ff = 0.0;
    }

    // Oil pressure, temp, vibrations
    oilP += ((n2 * 1.2) - oilP) * dt * 0.5;
    double targetOilT = (oatKelvin - 273.15) + (85.0 - (oatKelvin - 273.15)) * (n2 / 100.0);
    oilT += (targetOilT - oilT) * dt * 0.1;
    
    vib1 = (n1 / 100.0) * 0.6 + 0.1;
    vib2 = (n2 / 100.0) * 0.8 + 0.1;

    // Thrust calculation (Newtons)
    // T = T_max_SL * sigma * f(Mach) * g(N1)
    // sigma = (rho / rho_0)^0.7
    // Standard density at sea level rho_0 = 1.225
    double T_kelvin = oatKelvin - 0.0019812 * altFt;
    if (T_kelvin < 216.65) T_kelvin = 216.65;
    double p_ratio = std::pow(1.0 - 0.0000068756 * altFt, 5.25588);
    if (altFt > 36089.0) {
        p_ratio = 0.22336 * std::exp(-(altFt - 36089.0) / 20806.0);
    }
    double sigma = p_ratio * (288.15 / T_kelvin);
    double sigma_effect = std::pow(std::max(0.0, sigma), 0.7);
    double mach_effect = 1.0 - 0.3 * mach * mach;
    double n1_pct = n1 / 100.0;
    double n1_effect = n1_pct * n1_pct;

    thrustN = kMaxThrustSL * sigma_effect * mach_effect * n1_effect;
    if (!started) {
        thrustN = 0.0;
    }

    // Bleed flow kg/s
    bleedFlow = (n2 / 100.0) * 2.0;
}
