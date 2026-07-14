// QApplication (QtWidgets), NOT QGuiApplication: Qt Charts' QChart renders via
// QGraphicsScene/QWidgetTextControl and segfaults under a plain QGuiApplication.
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>

#include "Backend/include/AirDataComputer.hpp"
#include "Backend/include/FlightDataManager.hpp"
#include "Backend/include/FMSComputer.hpp"
#include "Backend/include/InstructorEngine.hpp"
#include "Backend/include/ArincParser.hpp"
#include "Backend/include/FlightPlanManager.hpp"
#include "Backend/include/FMGCController.hpp"
#include "Backend/include/PerformanceEngine.hpp"
#include "Backend/include/PredictionEngine.hpp"
#include <QFile>
#include <QDir>
#include <QUrl>
#include <QDebug>
#include <QLibrary>
#include <QQuickStyle>
#include <QCoreApplication>

int main(int argc, char *argv[])
{
    // Single-threaded scene-graph render loop — avoids the threaded render
    // loop holding/leaking QtQuick Canvas backing buffers on repaint.
    qputenv("QSG_RENDER_LOOP", "basic");

    QApplication app(argc, argv);
    app.setApplicationName("A320neo FMS Trainer");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("FMS Trainer");
    app.setWindowIcon(QIcon(":/icons/fms_icon.png"));

    // Use the fully-customizable Basic style; the native Windows style rejects
    // contentItem/background overrides used throughout the QML controls.
    QQuickStyle::setStyle("Basic");

    // Load ARINC 424 Navigation Database.
    // Resolution order:
    //   1. FMS_ARINC_DB environment variable (override for any OS)
    //   2. <exe_dir>/../Reference/nav_db/FAACIFP18  (portable repo-relative)
    //   3. Hardcoded Windows fallbacks (legacy — keep for existing setup)
    QString arincPath = qEnvironmentVariable("FMS_ARINC_DB");

    if (arincPath.isEmpty()) {
        // Portable: place the CIFP file at Reference/nav_db/FAACIFP18
        arincPath = QCoreApplication::applicationDirPath()
                  + "/../Reference/nav_db/FAACIFP18";
    }
    // Repo layout: exe lives at <repo>/Frontend QML_Qt/FMS_Qt/build/, the
    // reference nav data at <repo>/Reference/... — three levels up from the exe.
    const QString repoRoot = QCoreApplication::applicationDirPath() + "/../../..";
    const QString repoCifpDir = repoRoot + "/Reference/FMS-Work/"
                                "Reference files and repos/FMS_Final_Files/Backend/"
                                "arinc424-main/data/CIFP/";
    if (!QFile::exists(arincPath))
        arincPath = repoCifpDir + "FAACIFP18_230223";
    if (!QFile::exists(arincPath))
        arincPath = repoCifpDir + "FAACIFP18_230126";
    if (!QFile::exists(arincPath)) {
        // Final fallback: cwd-relative (running from the repo root)
        arincPath = QDir::current().absoluteFilePath(
            "Reference/FMS-Work/Reference files and repos/"
            "FMS_Final_Files/Backend/arinc424-main/data/CIFP/FAACIFP18_230223");
    }

    qDebug() << "Initializing ARINC 424 Database from:" << arincPath;
    if (QFile::exists(arincPath)) {
        ArincParser::loadDatabase(arincPath);
    } else {
        qWarning() << "ARINC 424 database file not found. Falling back to default hardcoded fixes.";
    }

    // ─── Register C++ backend types ───────────────────────────────────────────
    // IMPORTANT: these live in their OWN module URI ("FmsBackend"), NOT in
    // "FmsTrainer". An imperatively-registered URI and a qt_add_qml_module on the
    // same URI conflict: the imperative one wins and Qt never reads the module's
    // qmldir, so loadFromModule("FmsTrainer","Main") reports "no type named Main".
    // Keeping them separate lets "FmsTrainer" stay the pure QML module.
    qmlRegisterType<AirDataComputer>   ("FmsBackend", 1, 0, "AirDataComputer");
    qmlRegisterType<FMSComputer>       ("FmsBackend", 1, 0, "FMSComputer");
    qmlRegisterType<InstructorEngine>  ("FmsBackend", 1, 0, "InstructorEngine");

    qmlRegisterSingletonType<FlightDataManager>("FmsBackend", 1, 0, "FlightDataManager",
        [](QQmlEngine *, QJSEngine *) -> QObject * {
            return FlightDataManager::instance();
        }
    );

    qmlRegisterSingletonType<FlightPlanManager>("FmsBackend", 1, 0, "FlightPlanManager",
        [](QQmlEngine *, QJSEngine *) -> QObject * {
            return FlightPlanManager::instance();
        }
    );

    qmlRegisterSingletonType<FMGCController>("FmsBackend", 1, 0, "FMGCController",
        [](QQmlEngine *, QJSEngine *) -> QObject * {
            return FMGCController::instance();
        }
    );

    qmlRegisterSingletonType<PerformanceEngine>("FmsBackend", 1, 0, "PerformanceEngine",
        [](QQmlEngine *, QJSEngine *) -> QObject * {
            return PerformanceEngine::instance();
        }
    );

    qmlRegisterSingletonType<PredictionEngine>("FmsBackend", 1, 0, "PredictionEngine",
        [](QQmlEngine *, QJSEngine *) -> QObject * {
            return PredictionEngine::instance();
        }
    );

    // Force-load the FmsFrontend QML module library. main.cpp references no
    // symbol from it (the C++ types live in FmsBackend), so the linker omits the
    // import and FmsFrontend.dll — which holds the qt_add_qml_module "FmsTrainer"
    // registration — would never load, giving "No module named FmsTrainer".
    QLibrary fmsFrontend("FmsFrontend");
    if (!fmsFrontend.load())
        qWarning() << "Failed to load FmsFrontend module library:" << fmsFrontend.errorString();

    // ─── QML Engine ──────────────────────────────────────────────────────────
    QQmlApplicationEngine engine;
    engine.addImportPath("qrc:/");

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { qWarning() << "Failed to create root QML object"; },
                     Qt::QueuedConnection);
    engine.loadFromModule("FmsTrainer", "Main");
    if (engine.rootObjects().isEmpty()) {
        qWarning() << "No root objects — Main.qml failed to load.";
        return -1;
    }

    return app.exec();
}
