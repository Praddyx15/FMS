#pragma once

#include <QObject>
#include <QTimer>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QtQml/qqml.h>

/**
 * FMSComputer — MCDU logic engine.
 *
 * Handles scratchpad, page navigation and LSK (Line Select Key) validation.
 * All MCDU page logic ported from store.ts::handleLSK.
 */
class FMSComputer : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString  scratchpad      READ scratchpad      NOTIFY scratchpadChanged)
    Q_PROPERTY(bool     scratchpadError READ scratchpadError NOTIFY scratchpadChanged)
    Q_PROPERTY(QString  currentPage     READ currentPage     NOTIFY pageChanged)
    Q_PROPERTY(int      scrollOffset    READ scrollOffset    NOTIFY scrollOffsetChanged)

public:
    explicit FMSComputer(QObject *parent = nullptr);

    QString scratchpad()      const { return m_scratchpad; }
    bool    scratchpadError() const { return m_scratchpadError; }
    QString currentPage()     const { return m_currentPage; }
    int     scrollOffset()    const { return m_scrollOffset; }

    // MCDU keyboard
    Q_INVOKABLE void pressKey(const QString &key);

    // Line Select Key (L/R, index 0-5)
    Q_INVOKABLE void handleLSK(const QString &side, int index);

    // Page navigation
    Q_INVOKABLE void navigateTo(const QString &page);

    // Scroll
    Q_INVOKABLE void scrollUp();
    Q_INVOKABLE void scrollDown();

signals:
    void scratchpadChanged();
    void pageChanged();
    void scrollOffsetChanged();

    // Forwarded to FlightDataManager / AirDataComputer
    void requestSetDeparture(const QString &dep, const QString &dest);
    void requestSetAlternate(const QString &altn);
    void requestSetFlightNumber(const QString &fn);
    void requestSetCostIndex(int ci);
    void requestSetCruiseAltitude(int alt);
    void requestSetZFW(double zfw);
    void requestSetBlockFuel(double block);
    void requestSetV1(double v);
    void requestSetVr(double v);
    void requestSetV2(double v);
    void requestAddWaypoint(const QString &name, int insertAt);
    void requestRemoveWaypoint(int index);

private:
    void showError();
    void consumeScratchpad();
    void setScratchpadError(bool err);

    // Page handlers
    void handleLSK_Init(const QString &side, int index);
    void handleLSK_InitB(const QString &side, int index);
    void handleLSK_Fpln(const QString &side, int index);
    void handleLSK_Perf(const QString &side, int index);
    void handleLSK_Prog(const QString &side, int index);
    void handleLSK_RadNav(const QString &side, int index);
    void handleLSK_Data(const QString &side, int index);

public:
    // Validation helpers (public for testing/verification)
    static bool isValidICAO(const QString &s);
    static bool isValidFL(int fl);
    static bool isValidCostIndex(int ci);
    static bool parseWaypointInput(const QString &input, double &lat, double &lon);

private:

    QTimer  m_errorTimer;
    QString m_scratchpad;
    bool    m_scratchpadError = false;
    QString m_currentPage     = "init";
    int     m_scrollOffset    = 0;
};
