cmake_minimum_required(VERSION 3.21)

# Theme is a QML singleton (pragma Singleton) — must be marked before the module
set_source_files_properties(qml/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(FmsFrontend
    URI "FmsTrainer"
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    QML_FILES
        Main.qml
        qml/Theme.qml
        qml/cockpit/MainLayout.qml
        qml/cockpit/PreFlightSetup.qml
        qml/displays/PFD.qml
        qml/displays/AttitudeIndicator.qml
        qml/displays/SpeedTape.qml
        qml/displays/AltitudeTape.qml
        qml/displays/FMA.qml
        qml/displays/VSIndicator.qml
        qml/displays/HeadingTape.qml
        qml/displays/ND.qml
        qml/displays/CompassRose.qml
        qml/displays/FlightPlanOverlay.qml
        qml/displays/ECAM.qml
        qml/displays/ECAMLowerDisplay.qml
        qml/displays/EFISControl.qml
        qml/instruments/AirspeedIndicator.qml
        qml/instruments/Altimeter.qml
        qml/instruments/AttitudeIndicatorAnalog.qml
        qml/instruments/HeadingIndicator.qml
        qml/instruments/TurnCoordinator.qml
        qml/instruments/VerticalSpeedIndicator.qml
        qml/instruments/BasicInstrumentsPanel.qml
        qml/mcdu/MCDU.qml
        qml/mcdu/MCDUScreen.qml
        qml/mcdu/MCDUKey.qml
        qml/mcdu/LineKey.qml
        qml/mcdu/RoundKnob.qml
        qml/mcdu/pages/InitPage.qml
        qml/mcdu/pages/FplnPage.qml
        qml/mcdu/pages/PerfPage.qml
        qml/mcdu/pages/ProgPage.qml
        qml/mcdu/pages/RadNavPage.qml
        qml/mcdu/pages/DataPage.qml
        qml/mcdu/McduPage.qml
        qml/mcdu/McduRow.qml
        qml/mcdu/McduSep.qml
        qml/mcdu/pages/InitBPage.qml
        qml/mcdu/pages/FltInitPage.qml
        qml/mcdu/pages/IrsInitPage.qml
        qml/mcdu/pages/PosInitPage.qml
        qml/mcdu/pages/DeparturePage.qml
        qml/mcdu/pages/ArrivalPage.qml
        qml/mcdu/pages/RteSelPage.qml
        qml/mcdu/pages/AlternatePage.qml
        qml/mcdu/pages/DirectToPage.qml
        qml/mcdu/pages/FuelPredPage.qml
        qml/mcdu/pages/PerfCrzPage.qml
        qml/mcdu/pages/PerfApprPage.qml
        qml/mcdu/pages/WindPage.qml
        qml/mcdu/pages/WeatherPage.qml
        qml/mcdu/pages/WeatherReqPage.qml
        qml/mcdu/pages/TropoPage.qml
        qml/mcdu/pages/GndTempPage.qml
        qml/mcdu/pages/ATCCommPage.qml
        qml/mcdu/pages/AtsuPage.qml
        qml/mcdu/pages/AocPage.qml
        qml/mcdu/pages/SysStatusPage.qml
        qml/mcdu/pages/SecFplnPage.qml
        qml/mcdu/pages/FmgcPage.qml
        qml/mcdu/pages/DataIndexPage.qml
        qml/mcdu/pages/MCDUMenuPage.qml
        qml/cockpit/FCU.qml
        qml/cockpit/Yoke.qml
        qml/cockpit/RudderPedals.qml
        qml/cockpit/ThrottleQuadrant.qml
        qml/cockpit/OverheadPanel.qml
        qml/cockpit/Pedestal.qml
        qml/cockpit/CockpitSplitView.qml
        qml/cockpit/SystemStatus.qml
        qml/instructor/InstructorStation.qml
        qml/instructor/FailureInjection.qml
        qml/instructor/ExamCenter.qml
        qml/instructor/TrainingScenarios.qml
        qml/instructor/Analytics.qml
        qml/instructor/AICoach.qml
    RESOURCES
        fonts/HoneywellMCDU.ttf
        fonts/HoneywellMCDUSmall.ttf
        fonts/ECAMFontRegular.ttf
        fonts/AirbusFCU.ttf
)

target_link_libraries(FmsFrontend PUBLIC
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Charts
    FmsBackend
)
