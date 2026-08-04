#include "metascrolldesktop.h"

#include <effect/effecthandler.h>
#include <QAction>

namespace KWin
{

MetaScrollDesktopEffect::MetaScrollDesktopEffect()
{
    auto nextAction = new QAction(this);
    connect(nextAction, &QAction::triggered, this, [] {
        effects->setCurrentDesktop(effects->desktopToRight(effects->currentDesktop()));
    });
    effects->registerAxisShortcut(Qt::MetaModifier, PointerAxisDown, nextAction);

    auto prevAction = new QAction(this);
    connect(prevAction, &QAction::triggered, this, [] {
        effects->setCurrentDesktop(effects->desktopToLeft(effects->currentDesktop()));
    });
    effects->registerAxisShortcut(Qt::MetaModifier, PointerAxisUp, prevAction);
}

bool MetaScrollDesktopEffect::supported()
{
    return true;
}

} // namespace KWin
