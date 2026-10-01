# kwin-meta-scroll-switcher

> Switch virtual desktops by holding <kbd>Meta</kbd> and scrolling — no <kbd>Alt</kbd> needed.

KDE Plasma hardcodes <kbd>Meta</kbd>+<kbd>Alt</kbd>+scroll ([source](https://invent.kde.org/plasma/kwin/-/blob/master/src/virtualdesktops.cpp)) with no way to configure it ([KDE #510707](https://bugs.kde.org/show_bug.cgi?id=510707)). This plugin adds <kbd>Meta</kbd>-only scrolling as an independent KWin effect without touching the existing shortcut.

---

## Install

```bash
git clone https://github.com/R0h1tAnand/kwin-meta-scroll-switcher.git
cd kwin-meta-scroll-switcher
bash install.sh
```

| Flag | Action |
|---|---|
| *(none)* | Install deps, build, and enable |
| `--enable` | Enable without rebuilding |
| `--disable` | Disable the effect |
| `--uninstall` | Remove from system |

---

## Manual Build

<details>
<summary>Expand</summary>

```bash
# Dependencies (Debian/Ubuntu/Kali)
sudo apt install cmake extra-cmake-modules kwin-dev qt6-base-dev qt6-declarative-dev \
    libkf6coreaddons-dev libkf6config-dev libkf6globalaccel-dev libkf6i18n-dev \
    libkf6kcmutils-dev libdrm-dev libepoxy-dev libwayland-dev

# Build & install
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build
sudo cmake --install build
```

Enable via **System Settings → Apps → Desktop Effects → "Meta+Scroll Desktop Switch"**, or:

```bash
kwriteconfig6 --file kwinrc --group Plugins --key kwin_meta_scroll_desktopEnabled true
qdbus6 org.kde.KWin /KWin reconfigure
```

</details>

---

## Usage & Configuration

Hold <kbd>Meta</kbd> and scroll over any window to switch desktops.

By default, scrolling wraps around. To disable — open the effect's gear icon in Desktop Effects, or:

```bash
kwriteconfig6 --file kwinrc --group Effect-kwin_meta_scroll_desktop --key WrapAroundDesktops false
qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect kwin_meta_scroll_desktop
```

---

## Notes

- Built against KWin's internal effect ABI — **rebuild after major Plasma upgrades**.
- Tested on **Plasma/KWin 6.6.5**. Other 6.x versions should work.

---

## License

[GPL-2.0-or-later](LICENSE)
