#include "InstructorEngine.hpp"
#include "AirDataComputer.hpp"
#include <QDebug>

// Failure catalogue matching React store failure IDs
const QStringList InstructorEngine::s_catalogue = {
    "ENGINE_FIRE_1",
    "ENGINE_FIRE_2",
    "PITOT_BLOCKAGE",
    "STATIC_PORT_BLOCKAGE",
    "DUAL_FMS_FAILURE",
    "HYDRAULIC_GREEN_FAILURE",
    "HYDRAULIC_YELLOW_FAILURE",
    "HYDRAULIC_BLUE_FAILURE",
    "GEN1_FAILURE",
    "GEN2_FAILURE",
    "APU_FAILURE",
    "TCAS_FAILURE",
    "GPWS_FAILURE",
    "WINDSHEAR_ALERT",
    "STALL_WARNING",
    "OVERSPEED_WARNING",
};

InstructorEngine::InstructorEngine(QObject *parent)
    : QObject(parent)
{
}

void InstructorEngine::setInstructorActive(bool v)
{
    m_instructorActive = v;
    emit instructorActiveChanged();
}

void InstructorEngine::setWeatherOverride(bool v)
{
    m_weatherOverride = v;
    emit weatherOverrideChanged();
}

void InstructorEngine::injectFailure(const QString &id)
{
    if (!m_activeFailures.contains(id)) {
        m_activeFailures.append(id);
        emit failuresChanged();
        emit failureInjected(id, true);
        qDebug() << "[Instructor] Injected failure:" << id;
    }
}

void InstructorEngine::clearFailure(const QString &id)
{
    if (m_activeFailures.removeAll(id) > 0) {
        emit failuresChanged();
        emit failureInjected(id, false);
        qDebug() << "[Instructor] Cleared failure:" << id;
    }
}

void InstructorEngine::clearAllFailures()
{
    if (!m_activeFailures.isEmpty()) {
        QStringList cleared = m_activeFailures;
        m_activeFailures.clear();
        emit failuresChanged();
        for (const auto &id : cleared)
            emit failureInjected(id, false);
    }
}

bool InstructorEngine::hasFailure(const QString &id) const
{
    return m_activeFailures.contains(id);
}

QStringList InstructorEngine::availableFailures() const
{
    return s_catalogue;
}

void InstructorEngine::startScenario(const QString &scenarioId)
{
    clearAllFailures();

    if (scenarioId == "takeoff") {
        // Pre-takeoff configuration — no failures, engines running
        qDebug() << "[Instructor] Loaded scenario: TAKEOFF";
    } else if (scenarioId == "approach") {
        // Stabilized approach
        qDebug() << "[Instructor] Loaded scenario: APPROACH";
    } else if (scenarioId == "engine_fire_1") {
        injectFailure("ENGINE_FIRE_1");
    } else if (scenarioId == "dual_fms") {
        injectFailure("DUAL_FMS_FAILURE");
    } else if (scenarioId == "pitot_blockage") {
        injectFailure("PITOT_BLOCKAGE");
    }

    emit scenarioLoaded(scenarioId);
}
