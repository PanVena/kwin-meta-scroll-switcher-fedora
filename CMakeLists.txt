cmake_minimum_required(VERSION 3.16)
project(kwin-meta-scroll-desktop)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(ECM 6.0.0 REQUIRED NO_MODULE)
list(APPEND CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Quick)
find_package(KF6CoreAddons REQUIRED)
find_package(KWin REQUIRED)

kcoreaddons_add_plugin(kwin_meta_scroll_desktop
    SOURCES
        src/metascrolldesktop.cpp
        src/plugin.cpp
    INSTALL_NAMESPACE "kwin/effects/plugins"
)

target_link_libraries(kwin_meta_scroll_desktop PRIVATE
    KWin::kwin
    Qt6::Core
    Qt6::Gui
)
