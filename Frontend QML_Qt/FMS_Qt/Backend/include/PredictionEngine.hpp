#pragma once

#include <QObject>
#include <QList>
#include <QPair>

struct WaypointPrediction {
    QString name;
    double distanceToGoNm = 0.0;
    double etaMinutes = 0.0;
    double efobKg = 0.0;
};

class PredictionEngine : public QObject {
    Q_OBJECT
public:
    static PredictionEngine* instance();

    // Computes Top of Climb (TOC) and Top of Descent (TOD) positions
    // Returns pair of: (distance to TOC from origin in NM, distance to TOD from destination in NM)
    Q_INVOKABLE QPair<double, double> calculateClimbDescentPoints(double currentAltFeet, double cruiseAltFeet,
                                                                   double climbRateFpm, double descentRateFpm,
                                                                   double groundSpeedKnots);

    // Iterates waypoints, calculating DTG, ETA, and EFOB per leg
    Q_INVOKABLE QList<WaypointPrediction> computeWaypointPredictions(double initialFuelKg, double groundSpeedKnots,
                                                                     double fuelBurnRateKgPerHr);

private:
    PredictionEngine() = default;
    ~PredictionEngine() = default;
};
