#pragma once

#include <QString>
#include <QHash>
#include <QPair>
#include <QReadWriteLock>

/**
 * ArincParser parses raw ARINC 424 navigation files (e.g. CIFP files).
 * It converts coordinates from DMS format (e.g., N51521587W176402739) to decimal degrees
 * and caches them for fast, thread-safe, DO-178C compliant lookup during simulation.
 */
class ArincParser
{
public:
    struct WaypointInfo {
        QString name;
        double latitude = 0.0;
        double longitude = 0.0;
    };

    // Load database from file path
    static bool loadDatabase(const QString &filePath);

    // Thread-safe lookup for a waypoint/airport identifier
    static bool lookup(const QString &name, double &lat, double &lon);

    // Clear the database (useful for testing)
    static void clear();

    // Check if the database has been loaded
    static bool isLoaded();

    // Count of loaded waypoints
    static int count();

    // Helper: Parse DMS coordinates string to decimal degrees
    static bool parseDMS(const QString &latStr, const QString &lonStr, double &lat, double &lon);

private:
    static QHash<QString, WaypointInfo> s_database;
    static QReadWriteLock s_lock;
    static bool s_isLoaded;
};
