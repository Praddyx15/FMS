#pragma once

#include <QObject>
#include <QRecursiveMutex>
#include "Core/FlightDataBus.hpp"

class SystemsManager : public QObject
{
    Q_OBJECT

public:
    static SystemsManager *instance();
    explicit SystemsManager(QObject *parent = nullptr);

    // Run the systems simulation loop
    void tick(double dt);

    // Braking applications (called by wheels/brakes inputs)
    Q_INVOKABLE void applyBrakes();
    Q_INVOKABLE QString getBrakingChannel() const;

private:
    static SystemsManager *s_instance;
    mutable QRecursiveMutex m_mutex;

    // Simulation states
    double m_accumPressure = 3000.0;
    int m_brakeApplications = 0;

    void updateHydraulics(double dt, DataBus::FlightDataBus *bus);
    void updateElectrical(double dt, DataBus::FlightDataBus *bus);
    void updateFuel(double dt, DataBus::FlightDataBus *bus);
    void updateAPU(double dt, DataBus::FlightDataBus *bus);
    void updateADIRS(double dt, DataBus::FlightDataBus *bus);
};
