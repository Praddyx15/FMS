#pragma once

#include <QString>
#include <QHash>
#include <QList>
#include <QReadWriteLock>

struct RunwayInfo {
    QString identifier;
    double lengthFeet = 0.0;
    double headingDegrees = 0.0;
    double thresholdLatitude = 0.0;
    double thresholdLongitude = 0.0;
};

struct NavaidInfo {
    QString identifier;
    QString name;
    QString type; // "VOR", "DME", "NDB", "TACAN"
    double frequencyMhz = 0.0;
    double latitude = 0.0;
    double longitude = 0.0;
    double elevationFeet = 0.0;
};

struct ILSInfo {
    QString identifier;
    QString airportIcao;
    QString runwayId;
    double frequencyMhz = 0.0;
    double latitude = 0.0;
    double longitude = 0.0;
    double glidepathAngle = 3.0; // standard 3 degrees
};

struct HoldingPatternInfo {
    QString waypointName;
    double inboundCourseDegrees = 0.0;
    QString turnDirection; // "R" (Right) or "L" (Left)
    double legTimeMinutes = 1.0;
    double legDistanceNm = 0.0;
};

struct AirwayInfo {
    QString identifier;
    QList<QString> waypoints;
};

class NavigationDatabase {
public:
    static NavigationDatabase* instance();

    void clear();

    // Insertion APIs called by ArincParser
    void addRunway(const QString &airportIcao, const RunwayInfo &runway);
    void addNavaid(const QString &icao, const NavaidInfo &navaid);
    void addILS(const QString &airportIcao, const ILSInfo &ils);
    void addHoldingPattern(const QString &waypoint, const HoldingPatternInfo &holding);
    void addAirwayLeg(const QString &airwayId, const QString &waypoint);

    // Query APIs
    QList<RunwayInfo> getRunways(const QString &airportIcao);
    bool lookupNavaid(const QString &icao, NavaidInfo &navaid);
    bool lookupILS(const QString &airportIcao, const QString &runwayId, ILSInfo &ils);
    bool lookupHoldingPattern(const QString &waypoint, HoldingPatternInfo &holding);
    QList<QString> getAirwayWaypoints(const QString &airwayId);

private:
    NavigationDatabase() = default;
    ~NavigationDatabase() = default;

    QReadWriteLock m_lock;

    // Maps: keying off Airport ICAO or waypoint identifiers
    QHash<QString, QList<RunwayInfo>> m_runways;
    QHash<QString, NavaidInfo> m_navaids;
    QHash<QString, QList<ILSInfo>> m_ilsMap; // Airport -> List of ILS
    QHash<QString, HoldingPatternInfo> m_holdings;
    QHash<QString, QList<QString>> m_airways; // AirwayName -> List of Waypoint Names
};
