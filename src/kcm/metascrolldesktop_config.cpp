#include "metascrolldesktop_config.h"
#include "metascrolldesktopconfig.h"
#include "kwineffects_interface.h"

#include <KPluginFactory>

namespace KWin
{

K_PLUGIN_CLASS(MetaScrollDesktopEffectConfig)

MetaScrollDesktopEffectConfig::MetaScrollDesktopEffectConfig(QObject *parent, const KPluginMetaData &data)
    : KCModule(parent, data)
{
    ui.setupUi(widget());

    MetaScrollDesktopConfig::instance(QStringLiteral("kwinrc"));
    addConfig(MetaScrollDesktopConfig::self(), widget());
}

void MetaScrollDesktopEffectConfig::save()
{
    KCModule::save();

    OrgKdeKwinEffectsInterface interface(QStringLiteral("org.kde.KWin"),
                                          QStringLiteral("/Effects"),
                                          QDBusConnection::sessionBus());
    interface.reconfigureEffect(QStringLiteral("kwin_meta_scroll_desktop"));
}

} // namespace KWin

#include "metascrolldesktop_config.moc"
#include "moc_metascrolldesktop_config.cpp"
