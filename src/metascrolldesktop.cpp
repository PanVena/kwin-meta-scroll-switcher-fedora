#include "metascrolldesktop.h"
#include "metascrolldesktopconfig.h"

#include <effect/effecthandler.h>
#include <QAction>

namespace KWin
{

MetaScrollDesktopEffect::MetaScrollDesktopEffect()
{
    MetaScrollDesktopConfig::instance(effects->config());
    reconfigure(ReconfigureAll);

    auto nextAction = new QAction(this);
    connect(nextAction, &QAction::triggered, this, [] {
        effects->setCurrentDesktop(effects->desktopToRight(effects->currentDesktop(), MetaScrollDesktopConfig::wrapAroundDesktops()));
    });
    effects->registerAxisShortcut(Qt::MetaModifier, PointerAxisDown, nextAction);

    auto prevAction = new QAction(this);
    connect(prevAction, &QAction::triggered, this, [] {
        effects->setCurrentDesktop(effects->desktopToLeft(effects->currentDesktop(), MetaScrollDesktopConfig::wrapAroundDesktops()));
    });
    effects->registerAxisShortcut(Qt::MetaModifier, PointerAxisUp, prevAction);
}

bool MetaScrollDesktopEffect::supported()
{
    return true;
}

void MetaScrollDesktopEffect::reconfigure(ReconfigureFlags flags)
{
    Q_UNUSED(flags)
    MetaScrollDesktopConfig::self()->read();
}

} // namespace KWin
