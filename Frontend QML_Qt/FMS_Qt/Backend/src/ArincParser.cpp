#include "ArincParser.hpp"
#include "NavigationDatabase.hpp"
#include <QFile>
#include <QTextStream>
#include <QRegularExpression>
#include <QDebug>

QHash<QString, ArincParser::WaypointInfo> ArincParser::s_database;
QReadWriteLock ArincParser::s_lock;
bool ArincParser::s_isLoaded = false;


bool ArincParser::loadDatabase(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Failed to open ARINC database file:" << filePath;
        return false;
    }

    s_lock.lockForWrite();
    s_database.clear();
    NavigationDatabase::instance()->clear();

    QTextStream in(&file);
    QRegularExpression latRegex("([NS])\\d{8}");
    QRegularExpression lonRegex("([EW])\\d{9}");

    while (!in.atEnd()) {
        QString line = in.readLine();
        if (line.length() < 120) {
            continue;
        }

        // Section/Subsection code identification
        // ARINC 424 Columns: Record Type (1), Customer/Area Code (2-4), Section Code (5), Sub-section Code (13)
        // C++ 0-indexed: Section Code is index 4, Sub-section is index 12.
        if (line.length() >= 13) {
            QChar sectionCode = line[4];
            QChar subSectionCode = line[12];

            // 1. Airports (PA)
            if (sectionCode == 'P' && subSectionCode == 'A') {
                // Airport Identifier (ICAO) is usually columns 7-10 (index 6-9)
                QString icao = line.mid(6, 4).trimmed().toUpper();
                // Lat: 32-41 (index 32-40), Lon: 41-51 (index 41-50)
                QString latStr = line.mid(32, 9).trimmed();
                QString lonStr = line.mid(41, 10).trimmed();
                double lat = 0.0, lon = 0.0;
                if (parseDMS(latStr, lonStr, lat, lon)) {
                    WaypointInfo info;
                    info.name = icao + " AIRPORT";
                    info.latitude = lat;
                    info.longitude = lon;
                    s_database.insert(icao, info);
                }
            }
            // 2. Runways (PG)
            else if (sectionCode == 'P' && subSectionCode == 'G') {
                QString airportIcao = line.mid(6, 4).trimmed().toUpper();
                QString runwayId = line.mid(13, 5).trimmed().toUpper(); // runway id: e.g. RW34L
                // Runway length is usually columns 22-26 (index 22-25)
                double length = line.mid(22, 5).toDouble();
                // Runway bearing/heading: columns 27-30 (index 27-30) / 10
                double heading = line.mid(27, 4).toDouble() / 10.0;
                // Lat: 32-41 (index 32-40), Lon: 41-51 (index 41-50)
                QString latStr = line.mid(32, 9).trimmed();
                QString lonStr = line.mid(41, 10).trimmed();
                double lat = 0.0, lon = 0.0;
                if (parseDMS(latStr, lonStr, lat, lon)) {
                    RunwayInfo rwy;
                    rwy.identifier = runwayId;
                    rwy.lengthFeet = length;
                    rwy.headingDegrees = heading;
                    rwy.thresholdLatitude = lat;
                    rwy.thresholdLongitude = lon;
                    NavigationDatabase::instance()->addRunway(airportIcao, rwy);
                }
            }
            // 3. VHF/NDB Navaids (D or DB)
            else if (sectionCode == 'D') {
                // VHF Navaid (D + blank/space or G/etc) or NDB (DB)
                QString type = (subSectionCode == 'B') ? "NDB" : "VOR";
                QString navaidId = line.mid(13, 4).trimmed().toUpper();
                // Name starts around 93
                QString name = line.mid(93, 30).trimmed();
                // Frequency is around 44-48 / 100
                double freq = line.mid(44, 5).toDouble() / 100.0;
                // Elevation (meters/feet) is around 74-79
                double elev = line.mid(74, 5).toDouble();
                
                QString latStr = line.mid(32, 9).trimmed();
                QString lonStr = line.mid(41, 10).trimmed();
                double lat = 0.0, lon = 0.0;
                if (parseDMS(latStr, lonStr, lat, lon)) {
                    NavaidInfo nav;
                    nav.identifier = navaidId;
                    nav.name = name;
                    nav.type = type;
                    nav.frequencyMhz = freq;
                    nav.latitude = lat;
                    nav.longitude = lon;
                    nav.elevationFeet = elev;
                    NavigationDatabase::instance()->addNavaid(navaidId, nav);
                    
                    // Also cache in standard s_database for waypoint lookup
                    WaypointInfo info;
                    info.name = name;
                    info.latitude = lat;
                    info.longitude = lon;
                    s_database.insert(navaidId, info);
                }
            }
            // 4. ILS (PI)
            else if (sectionCode == 'P' && subSectionCode == 'I') {
                QString airportIcao = line.mid(6, 4).trimmed().toUpper();
                QString ilsId = line.mid(13, 4).trimmed().toUpper();
                QString runwayId = line.mid(27, 5).trimmed().toUpper();
                double freq = line.mid(44, 5).toDouble() / 100.0;
                
                QString latStr = line.mid(32, 9).trimmed();
                QString lonStr = line.mid(41, 10).trimmed();
                double lat = 0.0, lon = 0.0;
                if (parseDMS(latStr, lonStr, lat, lon)) {
                    ILSInfo ils;
                    ils.identifier = ilsId;
                    ils.airportIcao = airportIcao;
                    ils.runwayId = runwayId;
                    ils.frequencyMhz = freq;
                    ils.latitude = lat;
                    ils.longitude = lon;
                    ils.glidepathAngle = 3.0; // standard 3.0 deg
                    NavigationDatabase::instance()->addILS(airportIcao, ils);
                }
            }
            // 5. Holding Patterns (EP)
            else if (sectionCode == 'E' && subSectionCode == 'P') {
                QString fixName = line.mid(13, 5).trimmed().toUpper();
                double course = line.mid(27, 4).toDouble() / 10.0;
                QString turn = line.mid(31, 1).trimmed().toUpper(); // R/L
                double time = line.mid(32, 3).toDouble() / 10.0;
                if (time <= 0.0) time = 1.0;
                
                HoldingPatternInfo hold;
                hold.waypointName = fixName;
                hold.inboundCourseDegrees = course;
                hold.turnDirection = turn.isEmpty() ? "R" : turn;
                hold.legTimeMinutes = time;
                hold.legDistanceNm = 0.0;
                NavigationDatabase::instance()->addHoldingPattern(fixName, hold);
            }
            // 6. Airways (ER)
            else if (sectionCode == 'E' && subSectionCode == 'R') {
                QString airwayId = line.mid(13, 5).trimmed().toUpper();
                QString fixName = line.mid(27, 5).trimmed().toUpper();
                if (!airwayId.isEmpty() && !fixName.isEmpty()) {
                    NavigationDatabase::instance()->addAirwayLeg(airwayId, fixName);
                }
            }
        }

        // Keep legacy NAR fallback/general waypoint parsing for backwards compatibility
        if (line.mid(90, 3) == "NAR" || line.contains("NAR")) {
            int narIndex = line.indexOf("NAR");
            QString namePart = line.mid(narIndex + 3, 30).trimmed();
            QStringList parts = line.trimmed().split(QRegularExpression("\\s+"));
            if (parts.size() < 2) {
                continue;
            }
            QString icao = parts[1].toUpper();

            auto latMatch = latRegex.match(line);
            auto lonMatch = lonRegex.match(line);

            if (latMatch.hasMatch() && lonMatch.hasMatch()) {
                double lat = 0.0;
                double lon = 0.0;
                if (parseDMS(latMatch.captured(0), lonMatch.captured(0), lat, lon)) {
                    if (icao.length() <= 4 && !namePart.isEmpty()) {
                        WaypointInfo info;
                        info.name = namePart;
                        info.latitude = lat;
                        info.longitude = lon;
                        s_database.insert(icao, info);
                    }
                }
            }
        }
    }

    s_isLoaded = true;
    s_lock.unlock();
    qDebug() << "ARINC 424 database loaded successfully. Total waypoints:" << s_database.size();
    return true;
}

bool ArincParser::lookup(const QString &name, double &lat, double &lon)
{
    s_lock.lockForRead();
    QString key = name.trimmed().toUpper();
    bool found = s_database.contains(key);
    if (found) {
        const auto &info = s_database.value(key);
        lat = info.latitude;
        lon = info.longitude;
    }
    s_lock.unlock();
    return found;
}

void ArincParser::clear()
{
    s_lock.lockForWrite();
    s_database.clear();
    s_isLoaded = false;
    s_lock.unlock();
}

bool ArincParser::isLoaded()
{
    s_lock.lockForRead();
    bool loaded = s_isLoaded;
    s_lock.unlock();
    return loaded;
}

int ArincParser::count()
{
    s_lock.lockForRead();
    int size = s_database.size();
    s_lock.unlock();
    return size;
}

bool ArincParser::parseDMS(const QString &latStr, const QString &lonStr, double &lat, double &lon)
{
    if (latStr.length() < 9 || lonStr.length() < 10) {
        return false;
    }

    // Latitude Format: N51521587 (N/S + 2 deg + 2 min + 4 sec/100)
    bool ok = false;
    int latDeg = latStr.mid(1, 2).toInt(&ok);
    if (!ok) return false;
    int latMin = latStr.mid(3, 2).toInt(&ok);
    if (!ok) return false;
    double latSec = latStr.mid(5, 4).toDouble(&ok) / 100.0;
    if (!ok) return false;

    // Guard denominator for division-by-zero or negative results
    lat = latDeg + (latMin / 60.0) + (latSec / 3600.0);
    if (latStr[0] == 'S') {
        lat = -lat;
    }

    // Longitude Format: W176402739 (E/W + 3 deg + 2 min + 4 sec/100)
    int lonDeg = lonStr.mid(1, 3).toInt(&ok);
    if (!ok) return false;
    int lonMin = lonStr.mid(4, 2).toInt(&ok);
    if (!ok) return false;
    double lonSec = lonStr.mid(6, 4).toDouble(&ok) / 100.0;
    if (!ok) return false;

    lon = lonDeg + (lonMin / 60.0) + (lonSec / 3600.0);
    if (lonStr[0] == 'W') {
        lon = -lon;
    }

    return true;
}
