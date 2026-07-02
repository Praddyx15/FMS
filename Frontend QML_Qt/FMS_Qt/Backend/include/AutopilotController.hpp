#pragma once

#include <QString>

/**
 * AutopilotController — AP/FD/A-THR mode logic and FCU target state (Phase 1
 * decomposition of the AirDataComputer monolith; IMPLEMENTATION_PLAN §3).
 *
 * Plain C++ (no QObject) so mode-transition logic is unit-testable in
 * isolation. AirDataComputer owns one instance, forwards Q_PROPERTY getters
 * and setters, and emits the Qt signals.
 *
 * Phase 1 preserves the legacy behaviour exactly (string-based modes, simple
 * phase heuristics, damped-sine ILS simulation). Phase 5 replaces the
 * internals with the full arm→capture→engage state machine (doc 05 §2),
 * and Phase 4 replaces the phase heuristics with the FMGC 7-phase machine.
 */
class AutopilotController
{
public:
    struct Inputs {
        double altitude;      // ft
        double groundSpeed;   // kt
        double vsi;           // ft/min
    };

    /**
     * Advance mode/phase/ILS/FD logic by dt seconds.
     * Returns true when the flight phase changed this update.
     */
    bool update(double dt, const Inputs &in);

    // ── Engagement ───────────────────────────────────────────────────────────
    bool ap1Active  = false;
    bool ap2Active  = false;
    bool athrActive = false;
    bool fdActive   = true;

    bool apEngaged() const { return ap1Active || ap2Active; }

    // ── FCU managed/selected modes ───────────────────────────────────────────
    QString speedMode    = "MANAGED";
    QString headingMode  = "MANAGED";
    QString altitudeMode = "MANAGED";

    // ── FCU selected targets ─────────────────────────────────────────────────
    double selectedSpeed    = 280.0;
    double selectedHeading  = 284.0;
    double selectedAltitude = 32000.0;
    double selectedVS       = 0.0;
    double selectedMach     = 0.78;

    // ── Mode annunciations (FMA) ─────────────────────────────────────────────
    QString lateralMode        = "HDG";
    QString verticalMode       = "ALT";
    QString armedLateralMode;
    QString armedVerticalMode;
    QString approachMode;
    QString autoThrustMode     = "OFF";

    // ── Flight Director targets ──────────────────────────────────────────────
    double targetPitch = 2.5;
    double targetRoll  = 0.0;

    // ── ILS ──────────────────────────────────────────────────────────────────
    bool   ilsArmed        = false;
    double ilsLocDeviation = 0.0;
    double ilsGsDeviation  = 0.0;

    // ── Flight phase ─────────────────────────────────────────────────────────
    QString flightPhase = "cruise";
    QString flightMode  = "crz";

    bool normalLawActive = true;

private:
    double m_ilsSimTime = 0.0;
};
