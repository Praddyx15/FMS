#include <QCoreApplication>
#include <QDebug>
#include <QFile>
#include <cassert>
#include <iostream>
#include "AirDataComputer.hpp"
#include "AutopilotController.hpp"
#include "Core/Units.hpp"
#include "EngineModel.hpp"
#include "FlightControlLaws.hpp"
#include "FlightDataManager.hpp"
#include "FMSComputer.hpp"
#include "ArincParser.hpp"
#include "SystemsManager.hpp"
#include "Core/FlightDataBus.hpp"

// A simple macro for reporting test results
#define TEST_ASSERT(cond) \
    if (!(cond)) { \
        std::cerr << "Assertion failed: " << #cond << " at " << __FILE__ << ":" << __LINE__ << std::endl; \
        std::exit(1); \
    }

void testISA()
{
    std::cout << "Running testISA..." << std::endl;
    // ISA Temp at 0 ft should be ~288.15 K
    double t0 = AirDataComputer::isaTemperature(0.0);
    TEST_ASSERT(std::abs(t0 - 288.15) < 0.1);

    // ISA Temp at 36,089 ft (11,000m) should be ~216.65 K
    double t36 = AirDataComputer::isaTemperature(36089.0);
    TEST_ASSERT(std::abs(t36 - 216.65) < 0.1);

    // ISA Temp at 10,000 ft
    double t10 = AirDataComputer::isaTemperature(10000.0);
    TEST_ASSERT(t10 < 288.15 && t10 > 216.65);

    // ISA Pressure at 0 ft should be 101,325 Pa
    double p0 = AirDataComputer::isaPressure(0.0);
    TEST_ASSERT(std::abs(p0 - 101325.0) < 5.0);

    std::cout << "testISA passed!" << std::endl;
}

void testSpeeds()
{
    std::cout << "Running testSpeeds..." << std::endl;
    // Test conversion functions with positive values
    double mach = AirDataComputer::iasToMach(250.0, 10000.0);
    TEST_ASSERT(mach > 0.0 && mach < 1.0);

    double ias = AirDataComputer::machToIas(mach, 10000.0);
    TEST_ASSERT(std::abs(ias - 250.0) < 1.0);

    // Test zero or negative input handling
    TEST_ASSERT(AirDataComputer::iasToMach(0.0, 10000.0) == 0.0);
    TEST_ASSERT(AirDataComputer::iasToMach(-10.0, 10000.0) == 0.0);
    TEST_ASSERT(AirDataComputer::machToIas(0.0, 10000.0) == 0.0);
    TEST_ASSERT(AirDataComputer::machToIas(-0.5, 10000.0) == 0.0);

    std::cout << "testSpeeds passed!" << std::endl;
}

void testCoordinatesParser()
{
    std::cout << "Running testCoordinatesParser..." << std::endl;
    double lat = 0.0, lon = 0.0;

    // Test standard fixes lookup
    TEST_ASSERT(FMSComputer::parseWaypointInput("EDDF", lat, lon));
    TEST_ASSERT(std::abs(lat - 50.0379) < 0.0001);
    TEST_ASSERT(std::abs(lon - 8.5622) < 0.0001);

    TEST_ASSERT(FMSComputer::parseWaypointInput("EGLL", lat, lon));
    TEST_ASSERT(std::abs(lat - 51.4700) < 0.0001);
    TEST_ASSERT(std::abs(lon - (-0.4543)) < 0.0001);

    // Test degree-minute format: DDMMN/DDDMM[EW]
    // 5010N/00830E -> Lat: 50 + 10/60 = 50.1666..., Lon: 8 + 30/60 = 8.5
    TEST_ASSERT(FMSComputer::parseWaypointInput("5010N/00830E", lat, lon));
    TEST_ASSERT(std::abs(lat - 50.1666667) < 0.001);
    TEST_ASSERT(std::abs(lon - 8.5) < 0.001);

    // Test decimal degrees format: 50.166/8.544
    TEST_ASSERT(FMSComputer::parseWaypointInput("50.166/8.544", lat, lon));
    TEST_ASSERT(std::abs(lat - 50.166) < 0.0001);
    TEST_ASSERT(std::abs(lon - 8.544) < 0.0001);

    // Test invalid inputs
    TEST_ASSERT(!FMSComputer::parseWaypointInput("INVALID", lat, lon));
    TEST_ASSERT(!FMSComputer::parseWaypointInput("5010/00830", lat, lon));

    std::cout << "testCoordinatesParser passed!" << std::endl;
}

void testWaypointsBounds()
{
    std::cout << "Running testWaypointsBounds..." << std::endl;
    auto *fdm = FlightDataManager::instance();
    // Clear waypoints first
    while (fdm->waypointCount() > 0) {
        fdm->removeWaypoint(0);
    }
    TEST_ASSERT(fdm->waypointCount() == 0);

    // Add up to 100 waypoints
    for (int i = 0; i < 100; ++i) {
        fdm->addWaypoint(QString("WP%1").arg(i), 50.0, 8.0);
    }
    TEST_ASSERT(fdm->waypointCount() == 100);

    // Try adding the 101st waypoint - should be ignored/ignored due to capacity bounds
    fdm->addWaypoint("WP101", 50.0, 8.0);
    TEST_ASSERT(fdm->waypointCount() == 100);

    std::cout << "testWaypointsBounds passed!" << std::endl;
}

void testHaversineDistance()
{
    std::cout << "Running testHaversineDistance..." << std::endl;
    // Test distance between EDDF (50.0379, 8.5622) and LFPG (49.0097, 2.5479)
    // Great circle distance is approx 244 NM or 450 km.
    double dist = FlightDataManager::calculateHaversineDistance(50.0379, 8.5622, 49.0097, 2.5479);
    TEST_ASSERT(dist > 230.0 && dist < 260.0);

    // Distance to same point should be zero
    double zeroDist = FlightDataManager::calculateHaversineDistance(50.0379, 8.5622, 50.0379, 8.5622);
    TEST_ASSERT(zeroDist == 0.0);

    std::cout << "testHaversineDistance passed!" << std::endl;
}

void testArincParser()
{
    std::cout << "Running testArincParser..." << std::endl;

    // Test DMS conversion: N51521587W176402739
    // Lat: 51 deg, 52 min, 15.87 sec N -> 51 + 52/60 + 15.87/3600 = 51.871075
    // Lon: 176 deg, 40 min, 27.39 sec W -> -(176 + 40/60 + 27.39/3600) = -176.674275
    double lat = 0.0, lon = 0.0;
    TEST_ASSERT(ArincParser::parseDMS("N51521587", "W176402739", lat, lon));
    TEST_ASSERT(std::abs(lat - 51.871075) < 0.0001);
    TEST_ASSERT(std::abs(lon - (-176.674275)) < 0.0001);

    // Test database loading — resolve like main.cpp: env override, then repo-
    // relative (tests exe lives at <repo>/Frontend QML_Qt/FMS_Qt/build/)
    QString testFilePath = qEnvironmentVariable("FMS_ARINC_DB");
    if (testFilePath.isEmpty() || !QFile::exists(testFilePath)) {
        testFilePath = QCoreApplication::applicationDirPath()
                     + "/../../../Reference/FMS-Work/Reference files and repos/"
                       "FMS_Final_Files/Backend/arinc424-main/data/CIFP/FAACIFP18_230223";
    }
    if (QFile::exists(testFilePath)) {
        TEST_ASSERT(ArincParser::loadDatabase(testFilePath));
        TEST_ASSERT(ArincParser::isLoaded());
        TEST_ASSERT(ArincParser::count() > 0);

        // Try lookup of some standard airport/waypoint expected in CIFP
        // E.g., ADK (Adak Airport)
        double lookupLat = 0.0, lookupLon = 0.0;
        if (ArincParser::lookup("ADK", lookupLat, lookupLon)) {
            TEST_ASSERT(std::abs(lookupLat - 51.878) < 0.1);
        }
    }

    std::cout << "testArincParser passed!" << std::endl;
}

void testUnits()
{
    std::cout << "Running testUnits..." << std::endl;
    using namespace Units;
    using namespace Units::Literals;

    // Length round-trip
    Feet f = 32000.0_ft;
    Meters m = toMeters(f);
    TEST_ASSERT(std::abs(m.value() - 9753.6) < 0.1);
    TEST_ASSERT(std::abs(toFeet(m).value() - 32000.0) < 0.01);

    // Speed
    Knots kt = 250.0_kt;
    TEST_ASSERT(std::abs(toMetersPerSec(kt).value() - 128.611) < 0.01);

    // Angle round-trip
    Degrees d = 180.0_deg;
    TEST_ASSERT(std::abs(toRadians(d).value() - kPi) < 1e-9);
    TEST_ASSERT(std::abs(toDegrees(toRadians(d)).value() - 180.0) < 1e-9);

    // Temperature
    TEST_ASSERT(std::abs(toKelvin(Celsius{15.0}).value() - 288.15) < 1e-9);

    // Arithmetic stays in-unit
    Feet sum = 1000.0_ft + 500.0_ft;
    TEST_ASSERT(sum.value() == 1500.0);

    std::cout << "testUnits passed!" << std::endl;
}

void testEngineModel()
{
    std::cout << "Running testEngineModel..." << std::endl;
    EngineModel eng;

    // Converges toward thrust*2.1 target from the 67% initial state
    eng.thrust1 = 40.0;  // target N1 = 84
    eng.thrust2 = 40.0;
    for (int i = 0; i < 200; ++i)
        eng.tick(0.08, false, false);
    TEST_ASSERT(std::abs(eng.n1Left - 84.0) < 1.0);
    TEST_ASSERT(std::abs(eng.n1Right - 84.0) < 1.0);
    // EGT tracks the linear map
    TEST_ASSERT(std::abs(eng.egtLeft - (400.0 + eng.n1Left * 5.0)) < 1e-6);

    // Engine fire: thrust decays, N1 follows thrust*2
    EngineModel burning;
    burning.thrust1 = 30.0;
    burning.tick(1.0, true, false);
    TEST_ASSERT(std::abs(burning.thrust1 - 25.0) < 1e-9);   // -5/s
    TEST_ASSERT(std::abs(burning.n1Left - 50.0) < 1e-9);    // thrust*2
    for (int i = 0; i < 100; ++i)
        burning.tick(1.0, true, false);
    TEST_ASSERT(burning.thrust1 == 0.0 && burning.n1Left == 0.0);

    std::cout << "testEngineModel passed!" << std::endl;
}

void testAutopilotController()
{
    std::cout << "Running testAutopilotController..." << std::endl;
    AutopilotController ap;

    // On ground, AP off, FD on → HDG/FPA annunciation, phase "ground"
    bool changed = ap.update(0.08, { 0.0, 0.0, 0.0 });
    TEST_ASSERT(changed && ap.flightPhase == "ground");
    TEST_ASSERT(ap.lateralMode == "HDG" && ap.verticalMode == "FPA");
    TEST_ASSERT(ap.autoThrustMode == "OFF");

    // AP engaged, managed heading, at selected altitude → NAV / ALT
    ap.ap1Active = true;
    ap.athrActive = true;
    ap.selectedAltitude = 32000.0;
    changed = ap.update(0.08, { 32000.0, 450.0, 0.0 });
    TEST_ASSERT(changed && ap.flightPhase == "cruise");
    TEST_ASSERT(ap.lateralMode == "NAV" && ap.verticalMode == "ALT");
    TEST_ASSERT(ap.autoThrustMode == "SPEED");   // managed speed

    // Selected V/S climb far below target → VS active, ALT* armed
    ap.altitudeMode = "SELECTED";
    ap.update(0.08, { 20000.0, 450.0, 1500.0 });
    TEST_ASSERT(ap.flightPhase == "climb");
    TEST_ASSERT(ap.verticalMode == "VS" && ap.armedVerticalMode == "ALT*");

    // Low descent → approach phase arms ILS
    ap.update(0.08, { 3000.0, 140.0, -700.0 });
    ap.update(0.08, { 3000.0, 140.0, -50.0 });   // vsi<=0, below 5000
    TEST_ASSERT(ap.flightPhase == "approach");
    TEST_ASSERT(ap.ilsArmed && ap.approachMode == "LOC");

    std::cout << "testAutopilotController passed!" << std::endl;
}

void testFlightControlLaws()
{
    std::cout << "Running testFlightControlLaws..." << std::endl;

    // Manual input clamped to legacy limits
    double pitch = 0.0, roll = 0.0;
    FlightControlLaws::applyManual(45.0, -60.0, pitch, roll);
    TEST_ASSERT(pitch == FlightControlLaws::kPitchLimitDeg);
    TEST_ASSERT(roll == -FlightControlLaws::kRollLimitDeg);

    // AP engaged: attitude converges to trim (2.5° / 0°)
    pitch = 15.0; roll = -20.0;
    for (int i = 0; i < 500; ++i)
        FlightControlLaws::updateAttitude(0.08, 0.0, 0.0, true, pitch, roll);
    TEST_ASSERT(std::abs(pitch - FlightControlLaws::kTrimPitchDeg) < 0.1);
    TEST_ASSERT(std::abs(roll) < 0.1);

    std::cout << "testFlightControlLaws passed!" << std::endl;
}

void testSystemsManager()
{
    std::cout << "Running testSystemsManager..." << std::endl;
    auto *bus = DataBus::FlightDataBus::instance();
    auto *sys = SystemsManager::instance();

    // Verify default values
    TEST_ASSERT(bus->systems().hyd.greenPressure == 3000.0);
    TEST_ASSERT(sys->getBrakingChannel() == "NORMAL");

    // Mock failure to test cascade / fallback
    bus->training().activeFailures.failures.push_back("HYD_GREEN_LEAK");
    
    // Tick systems
    sys->tick(0.1);
    TEST_ASSERT(bus->systems().hyd.greenPressure < 2500.0);
    
    // Braking should fall back to Yellow (ALTERNATE)
    TEST_ASSERT(sys->getBrakingChannel() == "ALTERNATE");

    std::cout << "testSystemsManager passed!" << std::endl;
}

#include "NavigationDatabase.hpp"
#include "FlightPlanManager.hpp"
#include "FMGCController.hpp"
#include "PerformanceEngine.hpp"
#include "PredictionEngine.hpp"

void testNavigationDatabase()
{
    std::cout << "Running testNavigationDatabase..." << std::endl;
    auto *db = NavigationDatabase::instance();
    db->clear();

    // Test runway insertion/query
    RunwayInfo rwy;
    rwy.identifier = "RW34L";
    rwy.lengthFeet = 12000.0;
    db->addRunway("KLAX", rwy);
    auto rwys = db->getRunways("KLAX");
    TEST_ASSERT(rwys.size() == 1);
    TEST_ASSERT(rwys[0].identifier == "RW34L");

    // Test navaid insertion/query
    NavaidInfo nav;
    nav.identifier = "LAX";
    nav.name = "LOS ANGELES VOR";
    nav.type = "VOR";
    db->addNavaid("LAX", nav);
    NavaidInfo res;
    TEST_ASSERT(db->lookupNavaid("LAX", res));
    TEST_ASSERT(res.name == "LOS ANGELES VOR");

    // Test ILS insertion/query
    ILSInfo ils;
    ils.identifier = "I-LAX";
    ils.runwayId = "RW24R";
    db->addILS("KLAX", ils);
    ILSInfo ilsRes;
    TEST_ASSERT(db->lookupILS("KLAX", "RW24R", ilsRes));
    TEST_ASSERT(ilsRes.identifier == "I-LAX");

    std::cout << "testNavigationDatabase passed!" << std::endl;
}

void testFlightPlanManager()
{
    std::cout << "Running testFlightPlanManager..." << std::endl;
    auto *fpm = FlightPlanManager::instance();
    fpm->clear(FlightPlanManager::ACTIVE);
    fpm->clear(FlightPlanManager::TEMPORARY_A);

    // Insert waypoints in ACTIVE
    fpm->insertWaypoint(FlightPlanManager::ACTIVE, 0, "KLAX", 33.94, -118.40);
    fpm->insertWaypoint(FlightPlanManager::ACTIVE, 1, "KSFO", 37.62, -122.38);
    TEST_ASSERT(fpm->getWaypointCount(FlightPlanManager::ACTIVE) == 2);
    TEST_ASSERT(fpm->getWaypointName(FlightPlanManager::ACTIVE, 1) == "KSFO");

    // Insert constraints
    fpm->setAltitudeConstraint(FlightPlanManager::ACTIVE, 1, 10000.0, "ABOVE");
    TEST_ASSERT(fpm->getWaypointAltitudeConstraint(FlightPlanManager::ACTIVE, 1) == 10000.0);
    TEST_ASSERT(fpm->getWaypointAltitudeConstraintType(FlightPlanManager::ACTIVE, 1) == "ABOVE");

    // Test temporary copy & commit
    fpm->copyPlan(FlightPlanManager::ACTIVE, FlightPlanManager::TEMPORARY_A);
    fpm->insertWaypoint(FlightPlanManager::TEMPORARY_A, 2, "KSEA", 47.45, -122.30);
    TEST_ASSERT(fpm->getWaypointCount(FlightPlanManager::TEMPORARY_A) == 3);
    TEST_ASSERT(fpm->getWaypointCount(FlightPlanManager::ACTIVE) == 2);

    fpm->commitTemporary(FlightPlanManager::TEMPORARY_A);
    TEST_ASSERT(fpm->getWaypointCount(FlightPlanManager::ACTIVE) == 3);
    TEST_ASSERT(fpm->getWaypointName(FlightPlanManager::ACTIVE, 2) == "KSEA");

    std::cout << "testFlightPlanManager passed!" << std::endl;
}

void testFMGCController()
{
    std::cout << "Running testFMGCController..." << std::endl;
    auto *fmgc = FMGCController::instance();
    fmgc->setPhase(FMGCController::PREFLIGHT);

    // Dynamic phase update checks
    // Preflight -> Takeoff when thrust levers pushed and gs > 80
    fmgc->update(1.0, 100.0, 140.0, 95.0, true, true);
    TEST_ASSERT(fmgc->getPhase() == FMGCController::TAKEOFF);

    // Takeoff -> Climb above thrust reduction alt (1500 ft)
    fmgc->update(1.0, 1600.0, 200.0, 90.0, false, true);
    TEST_ASSERT(fmgc->getPhase() == FMGCController::CLIMB);

    std::cout << "testFMGCController passed!" << std::endl;
}

void testPerformanceEngine()
{
    std::cout << "Running testPerformanceEngine..." << std::endl;
    auto *perf = PerformanceEngine::instance();

    // VLS speed calculations
    double vlsClean = perf->getVLS(64000.0, 0); // flap 0
    double vlsFull = perf->getVLS(64000.0, 4);  // flap 4
    TEST_ASSERT(vlsClean > vlsFull);

    // Green dot check
    double gd = perf->getGreenDot(64000.0);
    TEST_ASSERT(gd > 120.0 && gd < 250.0);

    std::cout << "testPerformanceEngine passed!" << std::endl;
}

void testPredictionEngine()
{
    std::cout << "Running testPredictionEngine..." << std::endl;
    auto *pred = PredictionEngine::instance();

    // Climb & descent points check
    auto points = pred->calculateClimbDescentPoints(1500.0, 35000.0, 2000.0, 2000.0, 450.0);
    TEST_ASSERT(points.first > 0.0);
    TEST_ASSERT(points.second > 0.0);

    std::cout << "testPredictionEngine passed!" << std::endl;
}

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    std::cout << "========== STARTING FMS UNIT TESTS ==========" << std::endl;
    testISA();
    testSpeeds();
    testCoordinatesParser();
    testWaypointsBounds();
    testHaversineDistance();
    testArincParser();
    testUnits();
    testEngineModel();
    testAutopilotController();
    testFlightControlLaws();
    testSystemsManager();
    testNavigationDatabase();
    testFlightPlanManager();
    testFMGCController();
    testPerformanceEngine();
    testPredictionEngine();
    std::cout << "========== ALL TESTS PASSED SUCCESSFULLY ==========" << std::endl;
    return 0;
}
