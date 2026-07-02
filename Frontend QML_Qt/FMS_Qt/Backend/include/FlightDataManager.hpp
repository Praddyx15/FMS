#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QRecursiveMutex>
#include <QtQml/qqml.h>

/**
 * FlightDataManager — Singleton holding all flight-plan data.
 * Exposed to QML as a singleton ("FlightDataManager 1.0").
 */
class FlightDataManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    // ── Flight Plan ──────────────────────────────────────────────────────────
    Q_PROPERTY(QString  departure    READ departure    WRITE setDeparture    NOTIFY flightDataChanged)
    Q_PROPERTY(QString  destination  READ destination  WRITE setDestination  NOTIFY flightDataChanged)
    Q_PROPERTY(QString  alternate    READ alternate    WRITE setAlternate    NOTIFY flightDataChanged)
    Q_PROPERTY(QString  flightNumber READ flightNumber WRITE setFlightNumber NOTIFY flightDataChanged)
    Q_PROPERTY(QString  callsign     READ callsign     WRITE setCallsign     NOTIFY flightDataChanged)
    Q_PROPERTY(int      cruiseAltitude READ cruiseAltitude WRITE setCruiseAltitude NOTIFY flightDataChanged)
    Q_PROPERTY(double   tripFuel     READ tripFuel     WRITE setTripFuel     NOTIFY flightDataChanged)
    Q_PROPERTY(double   reserveFuel  READ reserveFuel  WRITE setReserveFuel  NOTIFY flightDataChanged)
    Q_PROPERTY(double   alternateFuel READ alternateFuel WRITE setAlternateFuel NOTIFY flightDataChanged)
    Q_PROPERTY(double   finalReserve READ finalReserve  WRITE setFinalReserve  NOTIFY flightDataChanged)
    Q_PROPERTY(double   zeroFuelWeight READ zeroFuelWeight WRITE setZeroFuelWeight NOTIFY flightDataChanged)
    Q_PROPERTY(double   blockFuel    READ blockFuel    WRITE setBlockFuel    NOTIFY flightDataChanged)
    Q_PROPERTY(int      passengers   READ passengers   WRITE setPassengers   NOTIFY flightDataChanged)
    Q_PROPERTY(double   cargo        READ cargo        WRITE setCargo        NOTIFY flightDataChanged)
    Q_PROPERTY(int      costIndex    READ costIndex    WRITE setCostIndex    NOTIFY flightDataChanged)

    // ── Waypoints ────────────────────────────────────────────────────────────
    Q_PROPERTY(QVariantList waypoints READ waypoints NOTIFY waypointsChanged)

    // ── Weather ──────────────────────────────────────────────────────────────
    Q_PROPERTY(double windHeading  READ windHeading  WRITE setWindHeading  NOTIFY weatherChanged)
    Q_PROPERTY(double windSpeed    READ windSpeed    WRITE setWindSpeed    NOTIFY weatherChanged)
    Q_PROPERTY(double turbulence   READ turbulence   WRITE setTurbulence   NOTIFY weatherChanged)

    // ── Systems ───────────────────────────────────────────────────────
    Q_PROPERTY(bool hydraulicGreen  READ hydraulicGreen  WRITE setHydraulicGreen  NOTIFY systemsChanged)
    Q_PROPERTY(bool hydraulicYellow READ hydraulicYellow WRITE setHydraulicYellow NOTIFY systemsChanged)
    Q_PROPERTY(bool hydraulicBlue   READ hydraulicBlue   WRITE setHydraulicBlue   NOTIFY systemsChanged)
    Q_PROPERTY(bool gen1Active      READ gen1Active      WRITE setGen1Active      NOTIFY systemsChanged)
    Q_PROPERTY(bool gen2Active      READ gen2Active      WRITE setGen2Active      NOTIFY systemsChanged)
    Q_PROPERTY(bool apuActive       READ apuActive       WRITE setApuActive       NOTIFY systemsChanged)
    Q_PROPERTY(bool apuMasterSw     READ apuMasterSw     WRITE setApuMasterSw     NOTIFY systemsChanged)
    Q_PROPERTY(bool gnssActive      READ gnssActive      WRITE setGnssActive      NOTIFY systemsChanged)
    Q_PROPERTY(double gnssDrift     READ gnssDrift       WRITE setGnssDrift       NOTIFY systemsChanged)
    // ADIRS
    Q_PROPERTY(bool adirs1Active READ adirs1Active WRITE setAdirs1Active NOTIFY systemsChanged)
    Q_PROPERTY(bool adirs2Active READ adirs2Active WRITE setAdirs2Active NOTIFY systemsChanged)
    Q_PROPERTY(bool adirs3Active READ adirs3Active WRITE setAdirs3Active NOTIFY systemsChanged)
    // Air conditioning
    Q_PROPERTY(bool pack1Active  READ pack1Active  WRITE setPack1Active  NOTIFY systemsChanged)
    Q_PROPERTY(bool pack2Active  READ pack2Active  WRITE setPack2Active  NOTIFY systemsChanged)
    // Anti-ice
    Q_PROPERTY(bool wingAntiIce  READ wingAntiIce  WRITE setWingAntiIce  NOTIFY systemsChanged)
    Q_PROPERTY(bool eng1AntiIce  READ eng1AntiIce  WRITE setEng1AntiIce  NOTIFY systemsChanged)
    Q_PROPERTY(bool eng2AntiIce  READ eng2AntiIce  WRITE setEng2AntiIce  NOTIFY systemsChanged)
    // Fuel tanks (kg)
    Q_PROPERTY(int fuelLOuter READ fuelLOuter WRITE setFuelLOuter NOTIFY systemsChanged)
    Q_PROPERTY(int fuelLInner READ fuelLInner WRITE setFuelLInner NOTIFY systemsChanged)
    Q_PROPERTY(int fuelCentre READ fuelCentre WRITE setFuelCentre NOTIFY systemsChanged)
    Q_PROPERTY(int fuelRInner READ fuelRInner WRITE setFuelRInner NOTIFY systemsChanged)
    Q_PROPERTY(int fuelROuter READ fuelROuter WRITE setFuelROuter NOTIFY systemsChanged)

    // ── EFIS ─────────────────────────────────────────────────────────────────
    Q_PROPERTY(int     ndRange     READ ndRange     WRITE setNdRange     NOTIFY efisChanged)
    Q_PROPERTY(QString ndMode      READ ndMode      WRITE setNdMode      NOTIFY efisChanged)
    Q_PROPERTY(bool    wxrOverlay  READ wxrOverlay  WRITE setWxrOverlay  NOTIFY efisChanged)
    Q_PROPERTY(bool    terrOverlay READ terrOverlay WRITE setTerrOverlay NOTIFY efisChanged)
    Q_PROPERTY(bool    tcasOverlay READ tcasOverlay WRITE setTcasOverlay NOTIFY efisChanged)
    Q_PROPERTY(bool    vorOverlay  READ vorOverlay  WRITE setVorOverlay  NOTIFY efisChanged)
    Q_PROPERTY(bool    wptOverlay  READ wptOverlay  WRITE setWptOverlay  NOTIFY efisChanged)
    Q_PROPERTY(double  qnh         READ qnh         WRITE setQnh         NOTIFY efisChanged)

public:
    static FlightDataManager *instance();
    explicit FlightDataManager(QObject *parent = nullptr);

    // Flight Plan
    QString departure()     const;
    QString destination()   const;
    QString alternate()     const;
    QString flightNumber()  const;
    QString callsign()      const;
    int     cruiseAltitude() const;
    double  tripFuel()      const;
    double  reserveFuel()   const;
    double  alternateFuel() const;
    double  finalReserve()  const;
    double  zeroFuelWeight() const;
    double  blockFuel()     const;
    int     passengers()    const;
    double  cargo()         const;
    int     costIndex()     const;

    // Waypoints
    QVariantList waypoints() const;

    // Weather
    double windHeading()  const;
    double windSpeed()    const;
    double turbulence()   const;

    // Systems
    bool   hydraulicGreen()  const;
    bool   hydraulicYellow() const;
    bool   hydraulicBlue()   const;
    bool   gen1Active()      const;
    bool   gen2Active()      const;
    bool   apuActive()       const;
    bool   apuMasterSw()     const;
    bool   gnssActive()      const;
    double gnssDrift()       const;
    bool   adirs1Active()    const;
    bool   adirs2Active()    const;
    bool   adirs3Active()    const;
    bool   pack1Active()     const;
    bool   pack2Active()     const;
    bool   wingAntiIce()     const;
    bool   eng1AntiIce()     const;
    bool   eng2AntiIce()     const;
    int    fuelLOuter()      const;
    int    fuelLInner()      const;
    int    fuelCentre()      const;
    int    fuelRInner()      const;
    int    fuelROuter()      const;

    // EFIS
    int     ndRange()     const;
    QString ndMode()      const;
    bool    wxrOverlay()  const;
    bool    terrOverlay() const;
    bool    tcasOverlay() const;
    bool    vorOverlay()  const;
    bool    wptOverlay()  const;
    double  qnh()         const;

    // Setters
    void setDeparture(const QString &v);
    void setDestination(const QString &v);
    void setAlternate(const QString &v);
    void setFlightNumber(const QString &v);
    void setCallsign(const QString &v);
    void setCruiseAltitude(int v);
    void setTripFuel(double v);
    void setReserveFuel(double v);
    void setAlternateFuel(double v);
    void setFinalReserve(double v);
    void setZeroFuelWeight(double v);
    void setBlockFuel(double v);
    void setPassengers(int v);
    void setCargo(double v);
    void setCostIndex(int v);
    void setWindHeading(double v);
    void setWindSpeed(double v);
    void setTurbulence(double v);
    void setHydraulicGreen(bool v);
    void setHydraulicYellow(bool v);
    void setHydraulicBlue(bool v);
    void setGen1Active(bool v);
    void setGen2Active(bool v);
    void setApuActive(bool v);
    void setApuMasterSw(bool v);
    void setGnssActive(bool v);
    void setGnssDrift(double v);
    void setAdirs1Active(bool v);
    void setAdirs2Active(bool v);
    void setAdirs3Active(bool v);
    void setPack1Active(bool v);
    void setPack2Active(bool v);
    void setWingAntiIce(bool v);
    void setEng1AntiIce(bool v);
    void setEng2AntiIce(bool v);
    void setFuelLOuter(int v);
    void setFuelLInner(int v);
    void setFuelCentre(int v);
    void setFuelRInner(int v);
    void setFuelROuter(int v);
    void setNdRange(int v);
    void setNdMode(const QString &v);
    void setWxrOverlay(bool v);
    void setTerrOverlay(bool v);
    void setTcasOverlay(bool v);
    void setVorOverlay(bool v);
    void setWptOverlay(bool v);
    void setQnh(double v);

    // Fuel burn — called by AirDataComputer::onTick()
    Q_INVOKABLE void decrementFuel(double kg);

    // Waypoint management
    Q_INVOKABLE void addWaypoint(const QString &name, double lat, double lon,
                                  double altitude = 0, double speed = 0);
    Q_INVOKABLE void removeWaypoint(int index);
    Q_INVOKABLE void insertWaypoint(int index, const QString &name, double lat, double lon,
                                     double altitude = 0, double speed = 0);
    Q_INVOKABLE QVariantMap waypointAt(int index) const;
    Q_INVOKABLE int  waypointCount() const;

    static double calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2);
    void recalculateRouteDistances();

signals:
    void flightDataChanged();
    void waypointsChanged();
    void weatherChanged();
    void systemsChanged();
    void efisChanged();

private:
    static FlightDataManager *s_instance;
    void initDefaultWaypoints();

    mutable QRecursiveMutex m_mutex;

    // Flight Plan
    QString m_departure     = "EDDF";
    QString m_destination   = "LFPG";
    QString m_alternate     = "EBBR";
    QString m_flightNumber  = "LH1234";
    QString m_callsign      = "DLH1234";
    int     m_cruiseAltitude = 32000;
    double  m_tripFuel      = 8500.0;
    double  m_reserveFuel   = 2000.0;
    double  m_alternateFuel = 800.0;
    double  m_finalReserve  = 1500.0;
    double  m_zeroFuelWeight = 58000.0;
    double  m_blockFuel     = 12000.0;
    int     m_passengers    = 150;
    double  m_cargo         = 2000.0;
    int     m_costIndex     = 35;

    // Waypoints
    QVariantList m_waypoints;

    // Weather
    double  m_windHeading   = 270.0;
    double  m_windSpeed     = 10.0;
    double  m_turbulence    = 2.0;

    // Systems
    bool    m_hydraulicGreen  = true;
    bool    m_hydraulicYellow = true;
    bool    m_hydraulicBlue   = true;
    bool    m_gen1Active      = true;
    bool    m_gen2Active      = true;
    bool    m_apuActive       = false;
    bool    m_apuMasterSw     = false;
    bool    m_gnssActive      = true;
    double  m_gnssDrift       = 0.0;
    bool    m_adirs1Active    = true;
    bool    m_adirs2Active    = true;
    bool    m_adirs3Active    = true;
    bool    m_pack1Active     = true;
    bool    m_pack2Active     = true;
    bool    m_wingAntiIce     = false;
    bool    m_eng1AntiIce     = false;
    bool    m_eng2AntiIce     = false;
    // Fuel tanks (kg) — A320 standard loading: 800+5400+6200+5400+800 = 18600
    int     m_fuelLOuter      = 800;
    int     m_fuelLInner      = 5400;
    int     m_fuelCentre      = 6200;
    int     m_fuelRInner      = 5400;
    int     m_fuelROuter      = 800;

    // EFIS
    int     m_ndRange    = 80;
    QString m_ndMode     = "ARC";
    bool    m_wxrOverlay  = false;
    bool    m_terrOverlay = false;
    bool    m_tcasOverlay = false;
    bool    m_vorOverlay  = true;
    bool    m_wptOverlay  = true;
    double  m_qnh        = 1013.0;
};
