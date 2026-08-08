#pragma once

#include <effect/effect.h>

namespace KWin
{

class MetaScrollDesktopEffect : public Effect
{
    Q_OBJECT

public:
    MetaScrollDesktopEffect();

    static bool supported();

    void reconfigure(ReconfigureFlags flags) override;
};

} // namespace KWin
