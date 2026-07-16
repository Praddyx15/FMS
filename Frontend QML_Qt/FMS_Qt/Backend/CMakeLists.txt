cmake_minimum_required(VERSION 3.21)

add_library(FmsBackend STATIC
    src/AirDataComputer.cpp
    src/AutopilotController.cpp
    src/EngineModel.cpp
    src/FlightControlLaws.cpp
    src/FlightDataManager.cpp
    src/FlightDataBus.cpp
    src/SystemsManager.cpp
    src/FMSComputer.cpp
    src/InstructorEngine.cpp
    src/ArincParser.cpp
    src/NavigationDatabase.cpp
    src/FlightPlanManager.cpp
    src/FMGCController.cpp
    src/PerformanceEngine.cpp
    src/PredictionEngine.cpp
    src/ThrottleQuadrantModel.cpp
    src/GroundModel.cpp
    include/AirDataComputer.hpp
    include/AutopilotController.hpp
    include/EngineModel.hpp
    include/FlightControlLaws.hpp
    include/Core/Units.hpp
    include/Core/FlightDataBus.hpp
    include/FlightDataManager.hpp
    include/SystemsManager.hpp
    include/FMSComputer.hpp
    include/InstructorEngine.hpp
    include/ArincParser.hpp
    include/NavigationDatabase.hpp
    include/FlightPlanManager.hpp
    include/FMGCController.hpp
    include/PerformanceEngine.hpp
    include/PredictionEngine.hpp
    include/ThrottleQuadrantModel.hpp
    include/GroundModel.hpp
)

target_include_directories(FmsBackend PUBLIC include)

target_link_libraries(FmsBackend PUBLIC
    Qt6::Core
    Qt6::Gui
)

# ─── Tests Executable ────────────────────────────────────────────────────────
add_executable(FmsTests tests/main.cpp)
set_target_properties(FmsTests PROPERTIES
    AUTOMOC OFF
    AUTOUIC OFF
    AUTORCC OFF
)
target_link_libraries(FmsTests PRIVATE
    FmsBackend
    Qt6::Core
)

