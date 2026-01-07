cmake_minimum_required(VERSION 3.16)

project(ACQProcessor VERSION 1.0.0 LANGUAGES CXX)

# C++ Standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt setup
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Find Qt6 packages
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Quick
    Qml
    Charts
    Widgets
)

# Include directories
include_directories(
    ${CMAKE_SOURCE_DIR}/cpp/inc
    ${CMAKE_SOURCE_DIR}/cpp/inc/backend
    ${CMAKE_SOURCE_DIR}/cpp/inc/models
    ${CMAKE_SOURCE_DIR}/cpp/inc/controllers
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/thirdparty
)

# Backend sources
set(BACKEND_SOURCES
    cpp/src/backend/ACQDataLoader.cpp
    cpp/src/backend/SignalProcessor.cpp
    cpp/src/backend/DataAnalyzer.cpp
    cpp/src/backend/DSPFilters.cpp
)

set(BACKEND_HEADERS
    cpp/inc/backend/ACQDataLoader.h
    cpp/inc/backend/SignalProcessor.h
    cpp/inc/backend/DataAnalyzer.h
    cpp/inc/backend/DSPFilters.h
)

# Model sources
set(MODEL_SOURCES
    cpp/src/models/ChannelData.cpp
    cpp/src/models/ACQMetadata.cpp
    cpp/src/models/SegmentLabel.cpp
)

set(MODEL_HEADERS
    cpp/inc/models/ChannelData.h
    cpp/inc/models/ACQMetadata.h
    cpp/inc/models/SegmentLabel.h
)

# Controller sources (QML-C++ bridge)
set(CONTROLLER_SOURCES
    cpp/src/controllers/FilterController.cpp
    cpp/src/controllers/ApplicationController.cpp
    cpp/src/controllers/LabelManager.cpp
)

set(CONTROLLER_HEADERS
    cpp/inc/controllers/FilterController.h
    cpp/inc/controllers/ApplicationController.h
    cpp/inc/controllers/LabelManager.h
)

# Main application
set(APP_SOURCES
    cpp/src/main.cpp
)

# QML files
set(QML_SOURCES
    qml/main.qml
    qml/MainWindow.qml
    qml/WaveformView.qml
    qml/FilterDesignWindow.qml
    qml/LabelingTools.qml
)

# Qt Resources file
qt_add_resources(QML_RESOURCES
    qml/qml.qrc
)

# Combine all sources
set(ALL_SOURCES
    ${APP_SOURCES}
    ${BACKEND_SOURCES}
    ${MODEL_SOURCES}
    ${CONTROLLER_SOURCES}
)

set(ALL_HEADERS
    ${BACKEND_HEADERS}
    ${MODEL_HEADERS}
    ${CONTROLLER_HEADERS}
)

# Create executable
qt_add_executable(${PROJECT_NAME}
    ${ALL_SOURCES}
    ${ALL_HEADERS}
    ${QML_RESOURCES}
)

# Set QML import path for Qt Creator
set(QML_IMPORT_PATH ${CMAKE_SOURCE_DIR}/qml CACHE STRING "" FORCE)

# Link Qt libraries
target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::Charts
    Qt6::Widgets
)

# Installation rules
install(TARGETS ${PROJECT_NAME}
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)

# Deploy QML files
install(DIRECTORY qml/
    DESTINATION bin/qml
    FILES_MATCHING PATTERN "*.qml"
)

# Enable warnings
if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /W4)
else()
    target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra -pedantic)
endif()

# Set output directory
set_target_properties(${PROJECT_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)

# Print configuration summary
message(STATUS "")
message(STATUS "========================================")
message(STATUS "  ${PROJECT_NAME} v${PROJECT_VERSION}")
message(STATUS "========================================")
message(STATUS "  Qt6 Version: ${Qt6_VERSION}")
message(STATUS "  C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "  Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  Install Prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "  Source Directory: ${CMAKE_SOURCE_DIR}")
message(STATUS "  QML Import Path: ${QML_IMPORT_PATH}")
message(STATUS "========================================")
message(STATUS "")
