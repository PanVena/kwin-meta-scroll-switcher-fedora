#pragma once

#include "ui_metascrolldesktop_config.h"
#include <KCModule>

namespace KWin
{

class MetaScrollDesktopEffectConfig : public KCModule
{
    Q_OBJECT

public:
    explicit MetaScrollDesktopEffectConfig(QObject *parent, const KPluginMetaData &data);

    void save() override;

private:
    Ui::MetaScrollDesktopEffectConfigForm ui;
};

} // namespace KWin
