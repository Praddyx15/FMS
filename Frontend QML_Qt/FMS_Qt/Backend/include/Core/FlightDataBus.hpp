#pragma once

#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QRecursiveMutex>
#include <vector>

namespace DataBus {

    struct Position {
        double latitude{0.0};
        double longitude{0.0};
        double altitude_geometric{0.0};
        double altitude_pressure{0.0};
        double altitude_radio{0.0};
    };

    struct Velocity {
        double ias{0.0};
        double tas{0.0};
        double gs{0.0};
        double mach{0.0};
        double vs{0.0};
    };

    struct Attitude {
        double pitch{0.0};
        double roll{0.0};
        double heading{0.0};
        double track{0.0};
    };

    struct AngularRates {
        double p{0.0};
        double q{0.0};
        double r{0.0};
    };

    struct AeroState {
        double alpha{0.0};
        double beta{0.0};
        double nz{1.0};
        double gamma{0.0};
    };

    struct Weight {
        double mass{58000.0};
        double cg_mac_pct{25.0};
        double fuel_per_tank[5]{800.0, 5400.0, 6200.0, 5400.0, 800.0};
    };

    struct Atmosphere {
        double oat{15.0};
        double tat{15.0};
        double pressure{1013.25};
        double density{1.225};
        double windHeading{270.0};
        double windSpeed{10.0};
        double turbulence{2.0};
    };

    struct EngineState {
        double n1Left{0.0};
        double n1Right{0.0};
        double n2Left{0.0};
        double n2Right{0.0};
        double egtLeft{0.0};
        double egtRight{0.0};
        double ffLeft{0.0};
        double ffRight{0.0};
        double oilPressureLeft{0.0};
        double oilPressureRight{0.0};
        double oilTempLeft{0.0};
        double oilTempRight{0.0};
        double vibN1Left{0.0};
        double vibN1Right{0.0};
        double vibN2Left{0.0};
        double vibN2Right{0.0};
        double thrustN1{0.0};
        double thrustN2{0.0};
        bool started1{false};
        bool started2{false};
        double bleedFlow1{0.0};
        double bleedFlow2{0.0};
    };

    struct AircraftState {
        Position position;
        Velocity velocity;
        Attitude attitude;
        AngularRates rates;
        AeroState aero;
        Weight weight;
        Atmosphere atmosphere;
        EngineState engines;
    };


    struct AutopilotState {
        bool ap1Active{false};
        bool ap2Active{false};
        bool athrActive{false};
        bool fdActive{true};
        double selectedSpeed{250.0};
        double selectedHeading{0.0};
        double selectedAltitude{5000.0};
        double selectedVS{0.0};
        QString lateralMode{"HDG"};
        QString verticalMode{"VS"};
        QString speedMode{"SELECTED"};
        QString headingMode{"SELECTED"};
        QString altitudeMode{"SELECTED"};
    };

    struct AvionicsState {
        AutopilotState ap;
        QString departure{"EDDF"};
        QString destination{"LFPG"};
        QString alternate{"EBBR"};
        QString flightNumber{"LH1234"};
        QString callsign{"DLH1234"};
        int cruiseAltitude{32000};
        double tripFuel{8500.0};
        double reserveFuel{2000.0};
        double alternateFuel{800.0};
        double finalReserve{1500.0};
        double zeroFuelWeight{58000.0};
        double blockFuel{12000.0};
        int passengers{150};
        double cargo{2000.0};
        int costIndex{35};
        QVariantList waypoints;
        int ndRange{80};
        QString ndMode{"ARC"};
        bool wxrOverlay{false};
        bool terrOverlay{false};
        bool tcasOverlay{false};
        bool vorOverlay{true};
        bool wptOverlay{true};
        double qnh{1013.0};
    };

    struct HydraulicSystem {
        bool greenPumpOn{true};
        bool bluePumpOn{true};
        bool yellowPumpOn{true};
        double greenPressure{3000.0}; // psi
        double bluePressure{3000.0};
        double yellowPressure{3000.0};
        bool ptuOn{false};
        bool ratDeployed{false};
        double accumulatorPressure{3000.0};
    };

    struct ElectricalSystem {
        bool idg1Active{true};
        bool idg2Active{true};
        bool apuGenActive{false};
        bool extPwrActive{false};
        bool emerGenActive{false};
        bool statInvActive{false};
        bool busTieClosed{true};
        bool bat1Active{true};
        bool bat2Active{true};
        
        // Bus voltages
        double acBus1{115.0};
        double acBus2{115.0};
        double acEss{115.0};
        double dcBus1{28.0};
        double dcBus2{28.0};
        double dcEss{28.0};
        double bat1Voltage{28.0};
        double bat2Voltage{28.0};
    };

    struct FuelSystem {
        bool pumps[6]{true, true, true, true, true, true}; // L1, L2, C1, C2, R1, R2
        bool crossfeedOpen{false};
        bool modeSelAuto{true};
    };

    struct SystemsState {
        HydraulicSystem hyd;
        ElectricalSystem elec;
        FuelSystem fuel;
        bool apuActive{false};
        bool apuMasterSw{false};
        bool apuStartSw{false};
        double apuN{0.0};    // % RPM
        double apuEgt{15.0};  // °C
        bool gnssActive{true};
        double gnssDrift{0.0};
        bool adirsActive[3]{true, true, true};
        int adirsMode[3]{2, 2, 2}; // 0 = OFF, 1 = ALIGN, 2 = NAV, 3 = ATT
        double adirsAlignTime[3]{0.0, 0.0, 0.0}; // seconds remaining to align
        bool packs[2]{true, true};
        bool antiIce[3]{false, false, false}; // wing, eng1, eng2

        // Pneumatics & Pressurization
        bool engBleed1{true};
        bool engBleed2{true};
        bool apuBleed{false};
        int crossBleedMode{1}; // 0 = OFF, 1 = AUTO, 2 = OPEN
        bool pack1On{true};
        bool pack2On{true};
        double cabinAltitude{0.0}; // ft
        double cabinVsi{0.0}; // ft/min
        double cabinDeltaP{0.0}; // psi
        double outflowValvePos{0.0}; // 0 = closed, 1 = open
        bool ditchingOverride{false};
        double bleedPressure1{0.0}; // psi
        double bleedPressure2{0.0}; // psi
    };

    struct FailureList {
        std::vector<QString> failures;
        bool contains(const QString &f) const {
            for (const auto &item : failures) {
                if (item == f) return true;
            }
            return false;
        }
    };

    struct TrainingState {
        QString activeMode{"Normal"};
        FailureList activeFailures;
    };

    class FlightDataBus {
    public:
        static FlightDataBus *instance();

        AircraftState &aircraft() { return m_aircraft; }
        const AircraftState &aircraft() const { return m_aircraft; }

        AvionicsState &avionics() { return m_avionics; }
        const AvionicsState &avionics() const { return m_avionics; }

        SystemsState &systems() { return m_systems; }
        const SystemsState &systems() const { return m_systems; }

        TrainingState &training() { return m_training; }
        const TrainingState &training() const { return m_training; }

        mutable QRecursiveMutex mutex;

    private:
        FlightDataBus() = default;
        static FlightDataBus *s_instance;
        AircraftState m_aircraft;
        AvionicsState m_avionics;
        SystemsState m_systems;
        TrainingState m_training;
    };
}
