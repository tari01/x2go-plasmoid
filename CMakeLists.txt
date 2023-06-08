cmake_minimum_required (VERSION 3.16)
project (x2go-plasmoid VERSION "1.0" LANGUAGES CXX)

if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    SET (CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "..." FORCE)
endif (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)

# Options

option (ENABLE_WERROR "Treat all build warnings as errors" OFF)
set (CMAKE_BUILD_TYPE "Release")

if (ENABLE_WERROR)
    add_definitions ("-Werror")
endif ()

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    add_definitions ("-Weverything")
else()
    add_definitions ("-Wall")
endif ()

# Prerequisites

find_package (ECM REQUIRED NO_MODULE)
set (CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
include (KDEInstallDirs)
include (ECMInstallIcons)
include (ECMQmlModule)
include (KDECMakeSettings)
find_package (Qt5 CONFIG REQUIRED Core Qml)
find_package (KF5 COMPONENTS Plasma I18n REQUIRED)

# Build: Applet

plasma_install_package (package org.x2go.plasmoid)

# Build: Plugin

ecm_add_qml_module (x2go-plasmoid-plugin URI org.x2go.plasmoid)
target_sources (x2go-plasmoid-plugin PRIVATE plugin/x2go-plasmoid-plugin.cpp)
target_link_libraries (x2go-plasmoid-plugin Qt::Core Qt::Qml)
ecm_finalize_qml_module (x2go-plasmoid-plugin DESTINATION ${KDE_INSTALL_QMLDIR})

# Build: Icon

ecm_install_icons (ICONS "data/sc-apps-x2go-plasmoid.svg" DESTINATION ${KDE_INSTALL_ICONDIR})

# Build: Translations

file (GLOB FILES "${CMAKE_SOURCE_DIR}/po/*.po")

foreach (FILE ${FILES})
    get_filename_component (FILENAME ${FILE} NAME_WE)
    configure_file ("${FILE}" "${CMAKE_BINARY_DIR}/po/${FILENAME}/plasma_applet_org.x2go.plasmoid.po" COPYONLY)
endforeach ()

ki18n_install (${CMAKE_BINARY_DIR}/po)

# Info

message (STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")
message (STATUS "Build with -Werror: ${ENABLE_WERROR}")
