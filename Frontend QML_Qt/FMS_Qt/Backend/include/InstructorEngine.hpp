#pragma once

#include <QObject>
#include <QStringList>
#include <QtQml/qqml.h>

/**
 * InstructorEngine — Failure injection and scenario management.
 *
 * The instructor can inject any named failure; each failure propagates to
 * AirDataComputer via the applyFailure() signal.  Failures are identified
 * by string IDs matching those used in the React store.
 */
class InstructorEngine : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QStringList activeFailures READ activeFailures NOTIFY failuresChanged)
    Q_PROPERTY(bool        instructorActive READ instructorActive
               WRITE setInstructorActive NOTIFY instructorActiveChanged)
    Q_PROPERTY(bool        weatherOverride READ weatherOverride
               WRITE setWeatherOverride NOTIFY weatherOverrideChanged)

public:
    explicit InstructorEngine(QObject *parent = nullptr);

    QStringList activeFailures()   const { return m_activeFailures; }
    bool        instructorActive() const { return m_instructorActive; }
    bool        weatherOverride()  const { return m_weatherOverride; }

    void setInstructorActive(bool v);
    void setWeatherOverride(bool v);

    Q_INVOKABLE void injectFailure(const QString &id);
    Q_INVOKABLE void clearFailure(const QString &id);
    Q_INVOKABLE void clearAllFailures();
    Q_INVOKABLE bool hasFailure(const QString &id) const;

    // Scenario quick-load: sets up a named flight state
    Q_INVOKABLE void startScenario(const QString &scenarioId);

    // Available failure catalogue
    Q_INVOKABLE QStringList availableFailures() const;

signals:
    void failuresChanged();
    void instructorActiveChanged();
    void weatherOverrideChanged();
    void failureInjected(const QString &id, bool active);
    void scenarioLoaded(const QString &scenarioId);

private:
    QStringList m_activeFailures;
    bool        m_instructorActive = false;
    bool        m_weatherOverride  = false;

    static const QStringList s_catalogue;
};
