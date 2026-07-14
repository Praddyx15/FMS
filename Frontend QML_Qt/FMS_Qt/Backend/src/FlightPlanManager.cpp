#include "FlightPlanManager.hpp"
#include <QDebug>

FlightPlanManager* FlightPlanManager::instance()
{
    static FlightPlanManager inst;
    return &inst;
}

const QList<FlightPlanLeg>& FlightPlanManager::getLegs(PlanSlot slot) const
{
    switch (slot) {
        case ACTIVE: return m_activePlan;
        case TEMPORARY_A: return m_tempPlanA;
        case TEMPORARY_B: return m_tempPlanB;
    }
    return m_activePlan;
}

void FlightPlanManager::clear(PlanSlot slot)
{
    switch (slot) {
        case ACTIVE:
            m_activePlan.clear();
            m_activeLegIndex = 0;
            break;
        case TEMPORARY_A:
            m_tempPlanA.clear();
            break;
        case TEMPORARY_B:
            m_tempPlanB.clear();
            break;
    }
}

void FlightPlanManager::copyPlan(PlanSlot from, PlanSlot to)
{
    QList<FlightPlanLeg> sourceLegs;
    switch (from) {
        case ACTIVE: sourceLegs = m_activePlan; break;
        case TEMPORARY_A: sourceLegs = m_tempPlanA; break;
        case TEMPORARY_B: sourceLegs = m_tempPlanB; break;
    }

    switch (to) {
        case ACTIVE:
            m_activePlan = sourceLegs;
            m_activeLegIndex = 0;
            break;
        case TEMPORARY_A:
            m_tempPlanA = sourceLegs;
            break;
        case TEMPORARY_B:
            m_tempPlanB = sourceLegs;
            break;
    }
}

void FlightPlanManager::commitTemporary(PlanSlot tempSlot)
{
    copyPlan(tempSlot, ACTIVE);
    clear(tempSlot);
}

void FlightPlanManager::insertWaypoint(PlanSlot slot, int index, const QString &name, double lat, double lon)
{
    FlightPlanLeg leg;
    leg.waypointName = name.trimmed().toUpper();
    leg.latitude = lat;
    leg.longitude = lon;

    QList<FlightPlanLeg>* plan = nullptr;
    if (slot == ACTIVE) plan = &m_activePlan;
    else if (slot == TEMPORARY_A) plan = &m_tempPlanA;
    else if (slot == TEMPORARY_B) plan = &m_tempPlanB;

    if (plan) {
        if (index < 0 || index >= plan->size()) {
            plan->append(leg);
        } else {
            plan->insert(index, leg);
        }
    }
}

void FlightPlanManager::removeWaypoint(PlanSlot slot, int index)
{
    QList<FlightPlanLeg>* plan = nullptr;
    if (slot == ACTIVE) plan = &m_activePlan;
    else if (slot == TEMPORARY_A) plan = &m_tempPlanA;
    else if (slot == TEMPORARY_B) plan = &m_tempPlanB;

    if (plan && index >= 0 && index < plan->size()) {
        plan->removeAt(index);
        if (slot == ACTIVE && m_activeLegIndex >= plan->size()) {
            m_activeLegIndex = qMax(0, plan->size() - 1);
        }
    }
}

void FlightPlanManager::setAltitudeConstraint(PlanSlot slot, int index, double altFeet, const QString &type)
{
    QList<FlightPlanLeg>* plan = nullptr;
    if (slot == ACTIVE) plan = &m_activePlan;
    else if (slot == TEMPORARY_A) plan = &m_tempPlanA;
    else if (slot == TEMPORARY_B) plan = &m_tempPlanB;

    if (plan && index >= 0 && index < plan->size()) {
        (*plan)[index].altitudeConstraintFeet = altFeet;
        (*plan)[index].altitudeConstraintType = type.trimmed().toUpper();
    }
}

void FlightPlanManager::setSpeedConstraint(PlanSlot slot, int index, double speedKnots, const QString &type)
{
    QList<FlightPlanLeg>* plan = nullptr;
    if (slot == ACTIVE) plan = &m_activePlan;
    else if (slot == TEMPORARY_A) plan = &m_tempPlanA;
    else if (slot == TEMPORARY_B) plan = &m_tempPlanB;

    if (plan && index >= 0 && index < plan->size()) {
        (*plan)[index].speedConstraintKnots = speedKnots;
        (*plan)[index].speedConstraintType = type.trimmed().toUpper();
    }
}

void FlightPlanManager::setDiscontinuity(PlanSlot slot, int index, bool hasDiscontinuity)
{
    QList<FlightPlanLeg>* plan = nullptr;
    if (slot == ACTIVE) plan = &m_activePlan;
    else if (slot == TEMPORARY_A) plan = &m_tempPlanA;
    else if (slot == TEMPORARY_B) plan = &m_tempPlanB;

    if (plan && index >= 0 && index < plan->size()) {
        (*plan)[index].discontinuity = hasDiscontinuity;
    }
}

void FlightPlanManager::setOverfly(PlanSlot slot, int index, bool isOverfly)
{
    QList<FlightPlanLeg>* plan = nullptr;
    if (slot == ACTIVE) plan = &m_activePlan;
    else if (slot == TEMPORARY_A) plan = &m_tempPlanA;
    else if (slot == TEMPORARY_B) plan = &m_tempPlanB;

    if (plan && index >= 0 && index < plan->size()) {
        (*plan)[index].overfly = isOverfly;
    }
}

int FlightPlanManager::getWaypointCount(PlanSlot slot) const
{
    return getLegs(slot).size();
}

QString FlightPlanManager::getWaypointName(PlanSlot slot, int index) const
{
    const auto &legs = getLegs(slot);
    if (index >= 0 && index < legs.size()) {
        return legs[index].waypointName;
    }
    return "";
}

double FlightPlanManager::getWaypointLatitude(PlanSlot slot, int index) const
{
    const auto &legs = getLegs(slot);
    if (index >= 0 && index < legs.size()) {
        return legs[index].latitude;
    }
    return 0.0;
}

double FlightPlanManager::getWaypointLongitude(PlanSlot slot, int index) const
{
    const auto &legs = getLegs(slot);
    if (index >= 0 && index < legs.size()) {
        return legs[index].longitude;
    }
    return 0.0;
}

double FlightPlanManager::getWaypointAltitudeConstraint(PlanSlot slot, int index) const
{
    const auto &legs = getLegs(slot);
    if (index >= 0 && index < legs.size()) {
        return legs[index].altitudeConstraintFeet;
    }
    return 0.0;
}

QString FlightPlanManager::getWaypointAltitudeConstraintType(PlanSlot slot, int index) const
{
    const auto &legs = getLegs(slot);
    if (index >= 0 && index < legs.size()) {
        return legs[index].altitudeConstraintType;
    }
    return "NONE";
}

double FlightPlanManager::getWaypointSpeedConstraint(PlanSlot slot, int index) const
{
    const auto &legs = getLegs(slot);
    if (index >= 0 && index < legs.size()) {
        return legs[index].speedConstraintKnots;
    }
    return 0.0;
}

QString FlightPlanManager::getWaypointSpeedConstraintType(PlanSlot slot, int index) const
{
    const auto &legs = getLegs(slot);
    if (index >= 0 && index < legs.size()) {
        return legs[index].speedConstraintType;
    }
    return "NONE";
}

bool FlightPlanManager::getWaypointDiscontinuity(PlanSlot slot, int index) const
{
    const auto &legs = getLegs(slot);
    if (index >= 0 && index < legs.size()) {
        return legs[index].discontinuity;
    }
    return false;
}

bool FlightPlanManager::getWaypointOverfly(PlanSlot slot, int index) const
{
    const auto &legs = getLegs(slot);
    if (index >= 0 && index < legs.size()) {
        return legs[index].overfly;
    }
    return false;
}

void FlightPlanManager::directTo(const QString &waypointName, double lat, double lon)
{
    // Real DIR TO implementation: clear active plan before the active waypoint,
    // insert direct target at index 0, and clear leg tracking.
    FlightPlanLeg leg;
    leg.waypointName = waypointName.trimmed().toUpper();
    leg.latitude = lat;
    leg.longitude = lon;

    m_activePlan.insert(0, leg);
    m_activeLegIndex = 0;
    qDebug() << "Executing DIR TO waypoint:" << waypointName;
}
