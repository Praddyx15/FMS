#pragma once

#include <QString>
#include <QList>
#include <QObject>

struct FlightPlanLeg {
    QString waypointName;
    double latitude = 0.0;
    double longitude = 0.0;
    
    // Constraints
    double altitudeConstraintFeet = 0.0;
    QString altitudeConstraintType = "NONE"; // "NONE", "AT", "ABOVE", "BELOW", "WINDOW"
    double altitudeConstraintWindowMaxFeet = 0.0;
    
    double speedConstraintKnots = 0.0;
    QString speedConstraintType = "NONE"; // "NONE", "AT", "BELOW", "ABOVE"

    bool overfly = false;
    bool discontinuity = false;
};

class FlightPlanManager : public QObject {
    Q_OBJECT
public:
    enum PlanSlot {
        ACTIVE,
        TEMPORARY_A,
        TEMPORARY_B
    };
    Q_ENUM(PlanSlot)

    static FlightPlanManager* instance();

    Q_INVOKABLE void clear(PlanSlot slot = ACTIVE);
    Q_INVOKABLE void copyPlan(PlanSlot from, PlanSlot to);
    Q_INVOKABLE void commitTemporary(PlanSlot tempSlot = TEMPORARY_A);
    
    Q_INVOKABLE void insertWaypoint(PlanSlot slot, int index, const QString &name, double lat, double lon);
    Q_INVOKABLE void removeWaypoint(PlanSlot slot, int index);
    Q_INVOKABLE void setAltitudeConstraint(PlanSlot slot, int index, double altFeet, const QString &type);
    Q_INVOKABLE void setSpeedConstraint(PlanSlot slot, int index, double speedKnots, const QString &type);
    Q_INVOKABLE void setDiscontinuity(PlanSlot slot, int index, bool hasDiscontinuity);
    Q_INVOKABLE void setOverfly(PlanSlot slot, int index, bool isOverfly);

    Q_INVOKABLE int getWaypointCount(PlanSlot slot) const;
    Q_INVOKABLE QString getWaypointName(PlanSlot slot, int index) const;
    Q_INVOKABLE double getWaypointLatitude(PlanSlot slot, int index) const;
    Q_INVOKABLE double getWaypointLongitude(PlanSlot slot, int index) const;
    Q_INVOKABLE double getWaypointAltitudeConstraint(PlanSlot slot, int index) const;
    Q_INVOKABLE QString getWaypointAltitudeConstraintType(PlanSlot slot, int index) const;
    Q_INVOKABLE double getWaypointSpeedConstraint(PlanSlot slot, int index) const;
    Q_INVOKABLE QString getWaypointSpeedConstraintType(PlanSlot slot, int index) const;
    Q_INVOKABLE bool getWaypointDiscontinuity(PlanSlot slot, int index) const;
    Q_INVOKABLE bool getWaypointOverfly(PlanSlot slot, int index) const;

    // DIR TO logic
    Q_INVOKABLE void directTo(const QString &waypointName, double lat, double lon);

    // Active leg tracking
    Q_INVOKABLE int getActiveLegIndex() const { return m_activeLegIndex; }
    Q_INVOKABLE void setActiveLegIndex(int idx) { m_activeLegIndex = idx; }

    const QList<FlightPlanLeg>& getLegs(PlanSlot slot) const;

private:
    FlightPlanManager() = default;
    ~FlightPlanManager() = default;

    QList<FlightPlanLeg> m_activePlan;
    QList<FlightPlanLeg> m_tempPlanA;
    QList<FlightPlanLeg> m_tempPlanB;

    int m_activeLegIndex = 0;
};
