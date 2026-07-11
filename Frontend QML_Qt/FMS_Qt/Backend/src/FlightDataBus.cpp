#include "Core/FlightDataBus.hpp"
#include <QMutexLocker>

namespace DataBus {

FlightDataBus *FlightDataBus::s_instance = nullptr;

FlightDataBus *FlightDataBus::instance()
{
    static QRecursiveMutex initMutex;
    QMutexLocker locker(&initMutex);
    if (!s_instance)
        s_instance = new FlightDataBus();
    return s_instance;
}

} // namespace DataBus
