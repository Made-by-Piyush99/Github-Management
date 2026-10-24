cmake_minimum_required(VERSION 3.20)

project(DevSyncStudio VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickControls2
    Widgets
)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/cpp
)

set(SOURCES
    app/main.cpp
    cpp/BackendBridge.h
    cpp/BackendBridge.cpp
    cpp/ProjectModel.h
    cpp/ProjectModel.cpp
    cpp/ActivityModel.h
    cpp/ActivityModel.cpp
    cpp/FileStatusModel.h
    cpp/FileStatusModel.cpp
    cpp/ThemeManager.h
    cpp/ThemeManager.cpp
    qml.qrc
    app.rc
)

qt_add_executable(DevSyncStudio
    MANUAL_FINALIZATION
    ${SOURCES}
)

target_link_libraries(DevSyncStudio PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
)

set_target_properties(DevSyncStudio PROPERTIES
    WIN32_EXECUTABLE TRUE
    OUTPUT_NAME "DevSyncStudio"
)

qt_finalize_executable(DevSyncStudio)
