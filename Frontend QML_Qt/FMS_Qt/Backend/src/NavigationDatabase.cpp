#include "NavigationDatabase.hpp"

NavigationDatabase* NavigationDatabase::instance()
{
    static NavigationDatabase inst;
    return &inst;
}

void NavigationDatabase::clear()
{
    m_lock.lockForWrite();
    m_runways.clear();
    m_navaids.clear();
    m_ilsMap.clear();
    m_holdings.clear();
    m_airways.clear();
    m_lock.unlock();
}

void NavigationDatabase::addRunway(const QString &airportIcao, const RunwayInfo &runway)
{
    m_lock.lockForWrite();
    m_runways[airportIcao.trimmed().toUpper()].append(runway);
    m_lock.unlock();
}

void NavigationDatabase::addNavaid(const QString &icao, const NavaidInfo &navaid)
{
    m_lock.lockForWrite();
    m_navaids[icao.trimmed().toUpper()] = navaid;
    m_lock.unlock();
}

void NavigationDatabase::addILS(const QString &airportIcao, const ILSInfo &ils)
{
    m_lock.lockForWrite();
    m_ilsMap[airportIcao.trimmed().toUpper()].append(ils);
    m_lock.unlock();
}

void NavigationDatabase::addHoldingPattern(const QString &waypoint, const HoldingPatternInfo &holding)
{
    m_lock.lockForWrite();
    m_holdings[waypoint.trimmed().toUpper()] = holding;
    m_lock.unlock();
}

void NavigationDatabase::addAirwayLeg(const QString &airwayId, const QString &waypoint)
{
    m_lock.lockForWrite();
    m_airways[airwayId.trimmed().toUpper()].append(waypoint.trimmed().toUpper());
    m_lock.unlock();
}

QList<RunwayInfo> NavigationDatabase::getRunways(const QString &airportIcao)
{
    m_lock.lockForRead();
    QList<RunwayInfo> res = m_runways.value(airportIcao.trimmed().toUpper());
    m_lock.unlock();
    return res;
}

bool NavigationDatabase::lookupNavaid(const QString &icao, NavaidInfo &navaid)
{
    m_lock.lockForRead();
    QString key = icao.trimmed().toUpper();
    bool found = m_navaids.contains(key);
    if (found) {
        navaid = m_navaids.value(key);
    }
    m_lock.unlock();
    return found;
}

bool NavigationDatabase::lookupILS(const QString &airportIcao, const QString &runwayId, ILSInfo &ils)
{
    m_lock.lockForRead();
    QString aptKey = airportIcao.trimmed().toUpper();
    QString rwyKey = runwayId.trimmed().toUpper();
    bool found = false;
    if (m_ilsMap.contains(aptKey)) {
        for (const auto &info : m_ilsMap.value(aptKey)) {
            if (info.runwayId.trimmed().toUpper() == rwyKey) {
                ils = info;
                found = true;
                break;
            }
        }
    }
    m_lock.unlock();
    return found;
}

bool NavigationDatabase::lookupHoldingPattern(const QString &waypoint, HoldingPatternInfo &holding)
{
    m_lock.lockForRead();
    QString key = waypoint.trimmed().toUpper();
    bool found = m_holdings.contains(key);
    if (found) {
        holding = m_holdings.value(key);
    }
    m_lock.unlock();
    return found;
}

QList<QString> NavigationDatabase::getAirwayWaypoints(const QString &airwayId)
{
    m_lock.lockForRead();
    QList<QString> res = m_airways.value(airwayId.trimmed().toUpper());
    m_lock.unlock();
    return res;
}
