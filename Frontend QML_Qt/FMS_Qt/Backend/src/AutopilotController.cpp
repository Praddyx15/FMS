#include "AutopilotController.hpp"

#include <cmath>

bool AutopilotController::update(double dt, const Inputs &in)
{
    // ── Flight phase auto-transition (Phase 4 replaces with FMGC 7-phase) ────
    const QString prevPhase = flightPhase;
    if (in.altitude < 500 && in.groundSpeed < 40) {
        flightPhase = "ground";
    } else if (in.altitude < 1500 && in.vsi > 100) {
        flightPhase = "takeoff";
    } else if (in.vsi > 200 && in.altitude < selectedAltitude - 500) {
        flightPhase = "climb";
    } else if (in.vsi < -200) {
        flightPhase = "descent";
    } else if (std::abs(in.altitude - selectedAltitude) < 500 && std::abs(in.vsi) < 100) {
        flightPhase = "cruise";
    } else if (in.altitude < 5000 && in.vsi <= 0) {
        flightPhase = "approach";
    }
    const bool phaseChanged = (prevPhase != flightPhase);

    // ── Lateral mode strings ─────────────────────────────────────────────────
    if (apEngaged()) {
        if (headingMode == "MANAGED") {
            lateralMode      = "NAV";
            armedLateralMode = "";
        } else {
            lateralMode      = "HDG";
            armedLateralMode = "NAV";
        }
    } else {
        lateralMode      = fdActive ? "HDG" : "OFF";
        armedLateralMode = "";
    }

    // ── Vertical mode strings + ALT capture ──────────────────────────────────
    const double altError = selectedAltitude - in.altitude;
    const bool nearAlt = std::abs(altError) < 300.0;

    if (apEngaged()) {
        if (nearAlt) {
            verticalMode      = "ALT";
            armedVerticalMode = "";
        } else if (altitudeMode == "SELECTED") {
            verticalMode      = "VS";
            armedVerticalMode = "ALT*";   // armed, will capture
        } else {
            verticalMode      = "OP CLB";
            armedVerticalMode = "ALT";
        }
    } else {
        verticalMode      = fdActive ? "FPA" : "OFF";
        armedVerticalMode = "";
    }

    // ── A/THR mode ───────────────────────────────────────────────────────────
    if (athrActive) {
        autoThrustMode = (speedMode == "MANAGED") ? "SPEED" : "MACH";
    } else {
        autoThrustMode = "OFF";
    }

    // ── Approach / ILS simulation ────────────────────────────────────────────
    const bool inApproach = (flightPhase == "approach" && in.altitude < 5000);
    if (inApproach) {
        approachMode = "LOC";
        ilsArmed     = true;
        m_ilsSimTime += dt;
        // Damped sine-wave deviations (decay toward 0 as approach stabilises)
        const double decay = std::exp(-m_ilsSimTime * 0.08);
        ilsLocDeviation = std::sin(m_ilsSimTime * 0.4) * 1.8 * decay; // ±2 dot scale
        ilsGsDeviation  = std::sin(m_ilsSimTime * 0.3 + 1.0) * 1.5 * decay;
    } else {
        approachMode    = "";
        ilsArmed        = false;
        m_ilsSimTime    = 0.0;
        ilsLocDeviation = 0.0;
        ilsGsDeviation  = 0.0;
    }

    // ── Flight Director targets ──────────────────────────────────────────────
    if (apEngaged() || fdActive) {
        targetRoll = 0.0;
        if (flightPhase == "climb") {
            targetPitch = 10.0 + (in.vsi < 1000 ? 3.0 : 0.0);
        } else if (flightPhase == "descent" || flightPhase == "approach") {
            targetPitch = -3.0;
        } else {
            targetPitch = 2.5; // cruise
        }
    }

    return phaseChanged;
}
