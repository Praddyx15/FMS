#include "ArincParser.hpp"
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

    QTextStream in(&file);
    QRegularExpression latRegex("([NS])\\d{8}");
    QRegularExpression lonRegex("([EW])\\d{9}");

    while (!in.atEnd()) {
        QString line = in.readLine();
        if (line.length() < 120) {
            continue;
        }

        // Replicate logic from parse_arinc_data.js
        if (line.mid(90, 3) == "NAR" || line.contains("NAR")) {
            int narIndex = line.indexOf("NAR");
            // Extract Name (approx 30 chars after NAR)
            QString namePart = line.mid(narIndex + 3, 30).trimmed();

            // Split into parts to extract ICAO
            QStringList parts = line.trimmed().split(QRegularExpression("\\s+"));
            if (parts.size() < 2) {
                continue;
            }
            QString icao = parts[1].toUpper();

            // Extract Coordinates
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
