#pragma once

#include <QObject>
#include <QString>

class FMGCController : public QObject {
    Q_OBJECT
public:
    enum FlightPhase {
        PREFLIGHT,
        TAKEOFF,
        CLIMB,
        CRUISE,
        DESCENT,
        APPROACH,
        GO_AROUND
    };
    Q_ENUM(FlightPhase)

    static FMGCController* instance();

    Q_INVOKABLE QString getPhaseString() const;
    Q_INVOKABLE FlightPhase getPhase() const { return m_phase; }
    Q_INVOKABLE void setPhase(FlightPhase phase);

    // Dynamic state evaluation triggered in the simulation loop
    void update(double dt, double altitudeFeet, double airspeedKnots, double n1, bool thrustLeversToga, bool groundSpeedAbove80);

signals:
    void phaseChanged(FlightPhase newPhase);

private:
    FMGCController() = default;
    ~FMGCController() = default;

    FlightPhase m_phase = PREFLIGHT;
};
