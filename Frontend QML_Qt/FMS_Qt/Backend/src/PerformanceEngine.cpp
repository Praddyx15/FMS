#include "PerformanceEngine.hpp"
#include <QtGlobal>
#include <qmath.h>

PerformanceEngine* PerformanceEngine::instance()
{
    static PerformanceEngine inst;
    return &inst;
}

void PerformanceEngine::calculateTakeoffSpeeds(double grossWeightKg, int flapIndex, double oatCelsius,
                                                double &v1, double &vr, double &v2)
{
    // A320 takeoff V-speed approximations
    double baseSpeed = 110.0;
    
    // Weight effect: 1.5 knots per 1000 kg over 60,000 kg
    double weightFactor = (grossWeightKg - 60000.0) / 1000.0 * 1.5;
    
    // Flap effect: higher flap index decreases takeoff speed requirement
    double flapFactor = -2.0 * flapIndex;
    
    // Temperature effect: higher temperatures require slightly higher speeds
    double tempFactor = oatCelsius > 15.0 ? (oatCelsius - 15.0) * 0.2 : 0.0;

    v1 = baseSpeed + weightFactor + flapFactor + tempFactor;
    vr = v1 + 4.0;
    v2 = vr + 5.0;

    // Safety clamps
    v1 = qBound(100.0, v1, 160.0);
    vr = qBound(105.0, vr, 165.0);
    v2 = qBound(110.0, v2, 170.0);
}

double PerformanceEngine::getVLS(double grossWeightKg, int flapIndex) const
{
    // Lowest Selectable Speed: varies from 1.13 VS to 1.23 VS
    // Baseline at 64,000 kg in config Full: 120 kt
    double vs0 = 96.0; // Stall speed at clean config/64 tons
    double weightFactor = qSqrt(grossWeightKg / 64000.0);
    double flapFactor = 1.0;
    
    switch (flapIndex) {
        case 0: flapFactor = 1.30; break; // Clean VLS
        case 1: flapFactor = 1.22; break; // Flaps 1
        case 2: flapFactor = 1.18; break; // Flaps 2
        case 3: flapFactor = 1.15; break; // Flaps 3
        default: flapFactor = 1.12; break; // Flaps Full
    }

    return vs0 * weightFactor * flapFactor;
}

double PerformanceEngine::getGreenDot(double grossWeightKg) const
{
    // Green Dot: Best lift-to-drag ratio speed in clean configuration
    // Approx: 2 * Weight (tons) + 85
    double weightTons = grossWeightKg / 1000.0;
    return 2.0 * weightTons + 85.0;
}

double PerformanceEngine::getFSpeed(double grossWeightKg) const
{
    // F-speed: Minimum speed to retract flaps in config 2 or 3
    // Approx: 1.5 * Weight (tons) + 95
    double weightTons = grossWeightKg / 1000.0;
    return 1.5 * weightTons + 95.0;
}

double PerformanceEngine::getSSpeed(double grossWeightKg) const
{
    // S-speed: Minimum speed to retract slats in config 1
    // Approx: 1.8 * Weight (tons) + 90
    double weightTons = grossWeightKg / 1000.0;
    return 1.8 * weightTons + 90.0;
}

double PerformanceEngine::getVapp(double grossWeightKg, int flapIndex, double headwindKnots) const
{
    double vls = getVLS(grossWeightKg, flapIndex);
    // Vapp = VLS + Max(5, Min(15, headwind/3))
    double windCorrection = headwindKnots / 3.0;
    windCorrection = qBound(5.0, windCorrection, 15.0);
    return vls + windCorrection;
}

double PerformanceEngine::estimateFuelBurnRateKgPerHour(double grossWeightKg, const QString &phase) const
{
    // Simple BADA-calibrated polynomials for A320 CFM56 engines
    double weightFactor = grossWeightKg / 60000.0;
    QString upPhase = phase.trimmed().toUpper();

    if (upPhase == "TAKEOFF") {
        return 10000.0 * weightFactor; // High thrust setting
    } else if (upPhase == "CLIMB") {
        return 5000.0 * weightFactor;
    } else if (upPhase == "CRUISE") {
        return 2400.0 * weightFactor; // Standard A320 cruise burn (~2.4 tons/hr)
    } else if (upPhase == "DESCENT") {
        return 800.0 * weightFactor;  // Idle descent burn
    } else if (upPhase == "APPROACH") {
        return 1200.0 * weightFactor;
    }
    
    return 2400.0 * weightFactor;
}
