#include "FMSComputer.hpp"
#include "FlightDataManager.hpp"
#include "ArincParser.hpp"
#include <QRegularExpression>
#include <QDebug>

FMSComputer::FMSComputer(QObject *parent)
    : QObject(parent)
{
    m_errorTimer.setSingleShot(true);
    m_errorTimer.setInterval(2000);
    connect(&m_errorTimer, &QTimer::timeout, this, [this]() {
        m_scratchpadError = false;
        emit scratchpadChanged();
    });
}

// ── Validation Helpers ────────────────────────────────────────────────────────

bool FMSComputer::isValidICAO(const QString &s)
{
    return QRegularExpression("^[A-Z]{4}$").match(s.toUpper()).hasMatch();
}

bool FMSComputer::isValidFL(int fl)
{
    return fl >= 0 && fl <= 410;
}

bool FMSComputer::isValidCostIndex(int ci)
{
    return ci >= 0 && ci <= 999;
}

void FMSComputer::showError()
{
    m_scratchpadError = true;
    m_errorTimer.start();
    emit scratchpadChanged();
}

void FMSComputer::consumeScratchpad()
{
    m_scratchpad.clear();
    m_scratchpadError = false;
    emit scratchpadChanged();
}

void FMSComputer::setScratchpadError(bool err)
{
    m_scratchpadError = err;
    if (err) m_errorTimer.start();
    emit scratchpadChanged();
}

// ── Keyboard ──────────────────────────────────────────────────────────────────

void FMSComputer::pressKey(const QString &key)
{
    if (key == "CLR") {
        if (!m_scratchpad.isEmpty())
            m_scratchpad.chop(1);
        else
            m_scratchpad = "CLR";
    } else if (key == "SP") {
        if (m_scratchpad.length() < 24)
            m_scratchpad += ' ';
    } else if (key == "PLUSMINUS") {
        if (m_scratchpad.startsWith('-'))
            m_scratchpad = m_scratchpad.mid(1);
        else
            m_scratchpad = '-' + m_scratchpad;
    } else {
        if (m_scratchpad == "CLR")
            m_scratchpad.clear();
        if (m_scratchpad.length() < 24)
            m_scratchpad += key;
    }
    m_scratchpadError = false;
    emit scratchpadChanged();
}

// ── Page Navigation ───────────────────────────────────────────────────────────

void FMSComputer::navigateTo(const QString &page)
{
    m_currentPage  = page;
    m_scrollOffset = 0;
    emit pageChanged();
    emit scrollOffsetChanged();
}

void FMSComputer::scrollUp()
{
    if (m_scrollOffset > 0) {
        m_scrollOffset--;
        emit scrollOffsetChanged();
    }
}

void FMSComputer::scrollDown()
{
    auto *fdm = FlightDataManager::instance();
    int max = qMax(0, fdm->waypointCount() - 4);
    if (m_scrollOffset < max) {
        m_scrollOffset++;
        emit scrollOffsetChanged();
    }
}

// ── LSK Dispatcher ────────────────────────────────────────────────────────────

void FMSComputer::handleLSK(const QString &side, int index)
{
    if      (m_currentPage == "init")   handleLSK_Init(side, index);
    else if (m_currentPage == "init_b") handleLSK_InitB(side, index);
    else if (m_currentPage == "fpln")   handleLSK_Fpln(side, index);
    else if (m_currentPage == "perf")   handleLSK_Perf(side, index);
    else if (m_currentPage == "prog")   handleLSK_Prog(side, index);
    else if (m_currentPage == "radnav") handleLSK_RadNav(side, index);
    else if (m_currentPage == "data")   handleLSK_Data(side, index);
}

// ── INIT Page ─────────────────────────────────────────────────────────────────

void FMSComputer::handleLSK_Init(const QString &side, int index)
{
    auto *fdm = FlightDataManager::instance();

    if (side == "L") {
        switch (index) {
        case 0: // L1 FROM/TO
            if (m_scratchpad.contains('/')) {
                auto parts = m_scratchpad.split('/');
                if (parts.size() == 2
                    && isValidICAO(parts[0])
                    && isValidICAO(parts[1]))
                {
                    fdm->setDeparture(parts[0].toUpper());
                    fdm->setDestination(parts[1].toUpper());
                    emit requestSetDeparture(parts[0].toUpper(), parts[1].toUpper());
                    consumeScratchpad();
                } else showError();
            } else if (m_scratchpad.isEmpty()) {
                fdm->setDeparture("");
                fdm->setDestination("");
            } else showError();
            break;
        case 1: // L2 ALTN
            if (!m_scratchpad.isEmpty() && isValidICAO(m_scratchpad)) {
                fdm->setAlternate(m_scratchpad.toUpper());
                emit requestSetAlternate(m_scratchpad.toUpper());
                consumeScratchpad();
            } else if (m_scratchpad.isEmpty()) {
                fdm->setAlternate("");
            } else showError();
            break;
        case 2: // L3 FLT NBR
            if (!m_scratchpad.isEmpty() && m_scratchpad.length() <= 8) {
                fdm->setFlightNumber(m_scratchpad.toUpper());
                emit requestSetFlightNumber(m_scratchpad.toUpper());
                consumeScratchpad();
            } else if (m_scratchpad.isEmpty()) {
                fdm->setFlightNumber("");
            } else showError();
            break;
        }
    } else if (side == "R") {
        switch (index) {
        case 3: { // R4 COST INDEX
            int ci = m_scratchpad.toInt();
            if (!m_scratchpad.isEmpty() && isValidCostIndex(ci)) {
                fdm->setCostIndex(ci);
                emit requestSetCostIndex(ci);
                consumeScratchpad();
            } else if (m_scratchpad.isEmpty()) {
                fdm->setCostIndex(0);
            } else showError();
            break;
        }
        case 4: { // R5 CRZ FL
            if (!m_scratchpad.isEmpty()) {
                int alt = 0;
                if (m_scratchpad.startsWith("FL", Qt::CaseInsensitive)) {
                    alt = m_scratchpad.mid(2).toInt() * 100;
                } else {
                    int num = m_scratchpad.toInt();
                    alt = (num < 1000) ? num * 100 : num;
                }
                int fl = alt / 100;
                if (isValidFL(fl)) {
                    fdm->setCruiseAltitude(alt);
                    emit requestSetCruiseAltitude(alt);
                    consumeScratchpad();
                } else showError();
            } else {
                fdm->setCruiseAltitude(0);
            }
            break;
        }
        }
    }
}

// ── INIT B Page ───────────────────────────────────────────────────────────────

void FMSComputer::handleLSK_InitB(const QString &side, int index)
{
    auto *fdm = FlightDataManager::instance();
    if (side == "R") {
        switch (index) {
        case 0: { // ZFW
            if (m_scratchpad.contains('/')) {
                auto parts = m_scratchpad.split('/');
                double zfw = parts[0].toDouble() * 1000.0;
                if (zfw > 0 && zfw < 100000) {
                    double block = fdm->blockFuel();
                    double trip = fdm->tripFuel();
                    if (zfw + block - trip <= 66000.0) {
                        fdm->setZeroFuelWeight(zfw);
                        emit requestSetZFW(zfw);
                        consumeScratchpad();
                    } else showError();
                } else showError();
            } else {
                double val = m_scratchpad.toDouble();
                double zfw = (val < 200) ? val * 1000.0 : val;
                if (!m_scratchpad.isEmpty() && zfw > 0) {
                    double block = fdm->blockFuel();
                    double trip = fdm->tripFuel();
                    if (zfw + block - trip <= 66000.0) {
                        fdm->setZeroFuelWeight(zfw);
                        emit requestSetZFW(zfw);
                        consumeScratchpad();
                    } else showError();
                } else if (m_scratchpad.isEmpty()) { /* skip */ }
                else showError();
            }
            break;
        }
        case 1: { // BLOCK FUEL
            double val = m_scratchpad.toDouble();
            if (!m_scratchpad.isEmpty() && val > 0) {
                double block = (val < 100.0) ? val * 1000.0 : val;
                double zfw = fdm->zeroFuelWeight();
                double trip = fdm->tripFuel();
                if (zfw + block - trip <= 66000.0) {
                    fdm->setBlockFuel(block);
                    emit requestSetBlockFuel(block);
                    consumeScratchpad();
                } else showError();
            } else if (!m_scratchpad.isEmpty()) showError();
            break;
        }
        }
    }
}

// ── F-PLN Page ────────────────────────────────────────────────────────────────

void FMSComputer::handleLSK_Fpln(const QString &side, int index)
{
    auto *fdm = FlightDataManager::instance();
    if (side == "L") {
        int targetIndex = m_scrollOffset + index;
        if (m_scratchpad == "CLR") {
            if (targetIndex < fdm->waypointCount()) {
                fdm->removeWaypoint(targetIndex);
                emit requestRemoveWaypoint(targetIndex);
                consumeScratchpad();
            }
        } else if (!m_scratchpad.isEmpty()) {
            double lat = 0.0;
            double lon = 0.0;
            if (parseWaypointInput(m_scratchpad, lat, lon)) {
                fdm->insertWaypoint(targetIndex, m_scratchpad.toUpper(), lat, lon, 0, 0);
                emit requestAddWaypoint(m_scratchpad.toUpper(), targetIndex);
                consumeScratchpad();
            } else {
                showError();
            }
        }
    }
}

// ── PERF Page ─────────────────────────────────────────────────────────────────

void FMSComputer::handleLSK_Perf(const QString &side, int index)
{
    if (side == "L") {
        double val = m_scratchpad.toDouble();
        switch (index) {
        case 0: // V1
            if (!m_scratchpad.isEmpty() && val >= 100 && val <= 185) {
                emit requestSetV1(val); consumeScratchpad();
            } else if (!m_scratchpad.isEmpty()) showError();
            break;
        case 1: // VR
            if (!m_scratchpad.isEmpty() && val >= 100 && val <= 190) {
                emit requestSetVr(val); consumeScratchpad();
            } else if (!m_scratchpad.isEmpty()) showError();
            break;
        case 2: // V2
            if (!m_scratchpad.isEmpty() && val >= 100 && val <= 200) {
                emit requestSetV2(val); consumeScratchpad();
            } else if (!m_scratchpad.isEmpty()) showError();
            break;
        }
    }
}

// ── PROG / RAD NAV / DATA pages (stubs) ──────────────────────────────────────

void FMSComputer::handleLSK_Prog(const QString &side, int index)
{
    Q_UNUSED(side) Q_UNUSED(index)
    // Read-only page — no LSK action needed in this version
}

void FMSComputer::handleLSK_RadNav(const QString &side, int index)
{
    Q_UNUSED(side) Q_UNUSED(index)
    // Future: set VOR/ILS frequencies
    consumeScratchpad();
}

void FMSComputer::handleLSK_Data(const QString &side, int index)
{
    Q_UNUSED(side) Q_UNUSED(index)
    consumeScratchpad();
}

bool FMSComputer::parseWaypointInput(const QString &input, double &lat, double &lon)
{
    QString upper = input.trimmed().toUpper();
    // 1. Database lookup (ARINC 424 database)
    if (ArincParser::lookup(upper, lat, lon)) {
        return true;
    }

    // Fallback to hardcoded list if database is not loaded yet
    if (upper == "EDDF")  { lat = 50.0379; lon = 8.5622; return true; }
    if (upper == "LFPG")  { lat = 49.0097; lon = 2.5479; return true; }
    if (upper == "EGLL")  { lat = 51.4700; lon = -0.4543; return true; }
    if (upper == "LBU")   { lat = 50.8667; lon = 8.0833; return true; }
    if (upper == "KRH")   { lat = 51.2833; lon = 6.9167; return true; }
    if (upper == "DKB")   { lat = 49.2638; lon = 10.2225; return true; }
    if (upper == "DF401") { lat = 50.1167; lon = 8.5200; return true; }
    if (upper == "RIDAR") { lat = 49.9125; lon = 8.3583; return true; }

    // 2. Degree/Minute Coordinate format: DDMMN/DDDMM[EW] or similar
    // Pattern: ^(\d{2})(\d{2})([NS])\/(\d{3})(\d{2})([EW])$
    static const QRegularExpression degMinRegex("^(\\d{2})(\\d{2})([NS])\\/(\\d{3})(\\d{2})([EW])$");
    auto matchDegMin = degMinRegex.match(upper);
    if (matchDegMin.hasMatch()) {
        double latDeg = matchDegMin.captured(1).toDouble();
        double latMin = matchDegMin.captured(2).toDouble();
        QString latHem = matchDegMin.captured(3);
        double lonDeg = matchDegMin.captured(4).toDouble();
        double lonMin = matchDegMin.captured(5).toDouble();
        QString lonHem = matchDegMin.captured(6);

        double parsedLat = latDeg + (latMin / 60.0);
        if (latHem == "S") parsedLat = -parsedLat;

        double parsedLon = lonDeg + (lonMin / 60.0);
        if (lonHem == "W") parsedLon = -parsedLon;

        if (parsedLat >= -90.0 && parsedLat <= 90.0 && parsedLon >= -180.0 && parsedLon <= 180.0) {
            lat = parsedLat;
            lon = parsedLon;
            return true;
        }
        return false;
    }

    // 3. Decimal degrees format: 50.166/8.544
    // Pattern: ^([+-]?\d+(?:\.\d+)?)\/([+-]?\d+(?:\.\d+)?)$
    static const QRegularExpression decRegex("^([+-]?\\d+(?:\\.\\d+)?)\\/([+-]?\\d+(?:\\.\\d+)?)$");
    auto matchDec = decRegex.match(upper);
    if (matchDec.hasMatch()) {
        double parsedLat = matchDec.captured(1).toDouble();
        double parsedLon = matchDec.captured(2).toDouble();
        if (parsedLat >= -90.0 && parsedLat <= 90.0 && parsedLon >= -180.0 && parsedLon <= 180.0) {
            lat = parsedLat;
            lon = parsedLon;
            return true;
        }
    }

    return false;
}
