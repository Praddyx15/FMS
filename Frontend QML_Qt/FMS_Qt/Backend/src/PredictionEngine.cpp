#include "PredictionEngine.hpp"
#include "FlightPlanManager.hpp"
#include "FlightDataManager.hpp"
#include <QtGlobal>
#include <qmath.h>

PredictionEngine* PredictionEngine::instance()
{
    static PredictionEngine inst;
    return &inst;
}

QPair<double, double> PredictionEngine::calculateClimbDescentPoints(double currentAltFeet, double cruiseAltFeet,
                                                                   double climbRateFpm, double descentRateFpm,
                                                                   double groundSpeedKnots)
{
    double climbRate = climbRateFpm > 0.0 ? climbRateFpm : 1500.0;
    double descentRate = descentRateFpm > 0.0 ? descentRateFpm : 2000.0;
    double speedKts = groundSpeedKnots > 0.0 ? groundSpeedKnots : 400.0;

    // Time to climb in minutes
    double climbTime = qMax(0.0, (cruiseAltFeet - currentAltFeet) / climbRate);
    // Distance to TOC in NM: speed (nm/min) * time (min)
    double tocDist = (speedKts / 60.0) * climbTime;

    // Time to descend in minutes
    double descentTime = qMax(0.0, (cruiseAltFeet - 1500.0) / descentRate);
    // Distance to TOD from destination in NM
    double todDist = (speedKts / 60.0) * descentTime;

    return qMakePair(tocDist, todDist);
}

QList<WaypointPrediction> PredictionEngine::computeWaypointPredictions(double initialFuelKg, double groundSpeedKnots,
                                                                     double fuelBurnRateKgPerHr)
{
    QList<WaypointPrediction> list;
    const auto &legs = FlightPlanManager::instance()->getLegs(FlightPlanManager::ACTIVE);
    if (legs.isEmpty()) {
        return list;
    }

    double speedKts = groundSpeedKnots > 0.0 ? groundSpeedKnots : 400.0;
    double burnPerMin = fuelBurnRateKgPerHr / 60.0;

    double accumulatedDistance = 0.0;
    double accumulatedTime = 0.0;
    double remainingFuel = initialFuelKg;

    for (int i = 0; i < legs.size(); ++i) {
        if (i > 0) {
            // Calculate distance between sequential legs using FlightDataManager's Haversine method
            double dist = FlightDataManager::calculateHaversineDistance(
                legs[i-1].latitude, legs[i-1].longitude,
                legs[i].latitude, legs[i].longitude
            );
            accumulatedDistance += dist;
            double timeForLeg = dist / (speedKts / 60.0);
            accumulatedTime += timeForLeg;
            remainingFuel -= burnPerMin * timeForLeg;
        }

        WaypointPrediction pred;
        pred.name = legs[i].waypointName;
        pred.distanceToGoNm = accumulatedDistance;
        pred.etaMinutes = accumulatedTime;
        pred.efobKg = qMax(0.0, remainingFuel);
        list.append(pred);
    }

    return list;
}
