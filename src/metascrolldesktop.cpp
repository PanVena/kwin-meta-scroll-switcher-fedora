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
    connect(nextAction, &QAction::triggered, this, [this] { requestSwitch(true); });
    effects->registerAxisShortcut(Qt::MetaModifier, PointerAxisDown, nextAction);

    auto prevAction = new QAction(this);
    connect(prevAction, &QAction::triggered, this, [this] { requestSwitch(false); });
    effects->registerAxisShortcut(Qt::MetaModifier, PointerAxisUp, prevAction);
}

void MetaScrollDesktopEffect::requestSwitch(bool forward)
{
    auto *output = effects->screenAt(effects->cursorPos().toPoint());
    if (!output) {
        return;
    }

    auto *current = effects->currentDesktop(output);
    const bool wrap = MetaScrollDesktopConfig::wrapAroundDesktops();
    auto *target = forward ? effects->desktopToRight(current, wrap)
                           : effects->desktopToLeft(current, wrap);
    if (target && target != current) {
        effects->setCurrentDesktop(target, output);
    }
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
