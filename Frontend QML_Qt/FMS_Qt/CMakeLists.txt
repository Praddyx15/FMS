cmake_minimum_required(VERSION 3.21)

project(FmsTrainer VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# ─── Qt6 ──────────────────────────────────────────────────────────────────────
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Quick
    QuickControls2
    Charts
    Widgets
)

qt_standard_project_setup()

# Suppress Qt 6.x CMake policy warnings
if(COMMAND qt_policy)
    qt_policy(SET QTP0001 NEW)
    qt_policy(SET QTP0004 NEW)
endif()

# ─── Sub-projects ─────────────────────────────────────────────────────────────
add_subdirectory(Backend)
add_subdirectory(Frontend)

# ─── Main Executable ──────────────────────────────────────────────────────────
qt_add_executable(FmsTrainer
    main.cpp
)

target_link_libraries(FmsTrainer PRIVATE
    FmsBackend
    FmsFrontend
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Charts
    Qt6::Widgets
)

# Copy Qt runtime DLLs on Windows (windeployqt)
if(WIN32)
    add_custom_command(TARGET FmsTrainer POST_BUILD
        COMMAND "${Qt6_DIR}/../../../bin/windeployqt.exe"
                --qmldir "${CMAKE_SOURCE_DIR}/Frontend/qml"
                "$<TARGET_FILE:FmsTrainer>"
        COMMENT "Running windeployqt..."
    )
endif()
