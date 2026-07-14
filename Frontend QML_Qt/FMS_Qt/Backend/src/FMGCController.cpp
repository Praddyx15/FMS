#include "FMGCController.hpp"
#include <QDebug>

FMGCController* FMGCController::instance()
{
    static FMGCController inst;
    return &inst;
}

QString FMGCController::getPhaseString() const
{
    switch (m_phase) {
        case PREFLIGHT: return "PREFLIGHT";
        case TAKEOFF: return "TAKEOFF";
        case CLIMB: return "CLIMB";
        case CRUISE: return "CRUISE";
        case DESCENT: return "DESCENT";
        case APPROACH: return "APPROACH";
        case GO_AROUND: return "GO_AROUND";
    }
    return "PREFLIGHT";
}

void FMGCController::setPhase(FlightPhase phase)
{
    if (m_phase != phase) {
        m_phase = phase;
        emit phaseChanged(m_phase);
        qDebug() << "FMGC Phase changed to:" << getPhaseString();
    }
}

void FMGCController::update(double dt, double altitudeFeet, double airspeedKnots, double n1, bool thrustLeversToga, bool groundSpeedAbove80)
{
    Q_UNUSED(dt);

    switch (m_phase) {
        case PREFLIGHT:
            // Transitions to TAKEOFF when thrust levers advanced to TOGA/FLX on ground
            if (thrustLeversToga && groundSpeedAbove80 && altitudeFeet < 1000.0) {
                setPhase(TAKEOFF);
            }
            break;
        case TAKEOFF:
            // Transitions to CLIMB once airborne and speed increases or altitude passes thrust reduction alt (typically 1500ft)
            if (altitudeFeet >= 1500.0) {
                setPhase(CLIMB);
            }
            break;
        case CLIMB:
            // Transitions to CRUISE when cruise altitude is captured (approx. matching vertical ALT mode)
            // Let's check if altitude is stabilized (usually matched with a set cruise alt in flight plan, say above 20000 ft or close to selected Alt)
            if (altitudeFeet > 10000.0 && airspeedKnots > 280.0) {
                // Simplified threshold for cruise transition if we are flat or reached target
                // We'll let the flight control/autopilot altitude trigger cruise capture, or we can check altitude
                if (altitudeFeet >= 28000.0) {
                    setPhase(CRUISE);
                }
            }
            break;
        case CRUISE:
            // Transition to DESCENT when descending altitude manually or passing TOD
            if (altitudeFeet < 24000.0) {
                setPhase(DESCENT);
            }
            break;
        case DESCENT:
            // Transition to APPROACH below decel point or when below 5000 ft and slowing
            if (altitudeFeet < 5000.0 && airspeedKnots < 200.0) {
                setPhase(APPROACH);
            }
            break;
        case APPROACH:
            // Transition to GO_AROUND if thrust levers advanced to TOGA in approach phase
            if (thrustLeversToga && airspeedKnots > 100.0) {
                setPhase(GO_AROUND);
            }
            break;
        case GO_AROUND:
            // Go around transitions back to climb once climbing safely
            if (altitudeFeet > 3000.0) {
                setPhase(CLIMB);
            }
            break;
    }
}
