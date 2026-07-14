#pragma once

#include <QObject>

class PerformanceEngine : public QObject {
    Q_OBJECT
public:
    static PerformanceEngine* instance();

    // V-speed estimations based on Weight (kg), Flaps index (0-4), OAT (C)
    Q_INVOKABLE void calculateTakeoffSpeeds(double grossWeightKg, int flapIndex, double oatCelsius,
                                            double &v1, double &vr, double &v2);

    // Dynamic speeds based on Gross Weight (kg) and Flap config (0=Clean, 1=Flap 1, 2=Flap 2, 3=Flap 3, 4=Full)
    Q_INVOKABLE double getVLS(double grossWeightKg, int flapIndex) const;
    Q_INVOKABLE double getGreenDot(double grossWeightKg) const;
    Q_INVOKABLE double getFSpeed(double grossWeightKg) const;
    Q_INVOKABLE double getSSpeed(double grossWeightKg) const;

    // Vapp wind correction formula: Vapp = VLS + clamp(headwind / 3, 5, 15)
    Q_INVOKABLE double getVapp(double grossWeightKg, int flapIndex, double headwindKnots) const;

    // BADA trip-fuel polynomial estimation: fuel burn (kg) per hour based on gross weight and flight phase
    Q_INVOKABLE double estimateFuelBurnRateKgPerHour(double grossWeightKg, const QString &phase) const;

private:
    PerformanceEngine() = default;
    ~PerformanceEngine() = default;
};
