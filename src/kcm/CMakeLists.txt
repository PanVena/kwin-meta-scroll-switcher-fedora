set(kwin_meta_scroll_desktop_config_SRCS
    metascrolldesktop_config.cpp
)

ki18n_wrap_ui(kwin_meta_scroll_desktop_config_SRCS metascrolldesktop_config.ui)
kconfig_add_kcfg_files(kwin_meta_scroll_desktop_config_SRCS ../metascrolldesktopconfig.kcfgc)

qt_add_dbus_interface(kwin_meta_scroll_desktop_config_SRCS
    ${KWIN_EFFECTS_INTERFACE}
    kwineffects_interface
)

add_library(kwin_meta_scroll_desktop_config MODULE ${kwin_meta_scroll_desktop_config_SRCS})

target_link_libraries(kwin_meta_scroll_desktop_config PRIVATE
    KF6::KCMUtils
    KF6::CoreAddons
    KF6::I18n
    KF6::ConfigGui
    Qt6::DBus
    Qt6::Widgets
)

install(TARGETS kwin_meta_scroll_desktop_config DESTINATION ${KDE_INSTALL_PLUGINDIR}/kwin/effects/configs)
