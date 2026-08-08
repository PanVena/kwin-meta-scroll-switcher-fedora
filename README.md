# kwin-meta-scroll-switcher

A KWin effect plugin that switches virtual desktops by holding <kbd>Meta</kbd> and scrolling the mouse wheel — no <kbd>Alt</kbd> required.

KDE Plasma ships a hardcoded <kbd>Meta</kbd>+<kbd>Alt</kbd>+scroll shortcut for this ([`src/virtualdesktops.cpp`](https://invent.kde.org/plasma/kwin/-/blob/master/src/virtualdesktops.cpp)), and it isn't configurable from System Settings. [KDE bug 510707](https://bugs.kde.org/show_bug.cgi?id=510707) tracks making it configurable upstream, but as of writing nobody has picked it up. This plugin adds the <kbd>Meta</kbd>-only binding as a separate, independent effect — it doesn't touch or replace the existing shortcut.

## How it works

KWin effects can register a modifier+scroll-wheel shortcut via `EffectsHandler::registerAxisShortcut()` — the same mechanism the built-in Zoom and Magnifier effects use for their configurable scroll-to-zoom bindings. This plugin registers two axis shortcuts under the `Meta` modifier alone and wires them to KWin's `desktopToRight()` / `desktopToLeft()` navigation.

## Requirements

- KDE Plasma 6 / KWin 6.x on Wayland or X11
- Debian/Ubuntu/Kali-based distro (package names below match `apt`; adjust for other distros)

## Building

Install the build dependencies:

```bash
sudo apt install cmake extra-cmake-modules kwin-dev qt6-base-dev qt6-declarative-dev \
    libkf6coreaddons-dev libkf6config-dev libkf6globalaccel-dev libkf6i18n-dev \
    libkf6kcmutils-dev libdrm-dev libepoxy-dev libwayland-dev
```

Then build:

```bash
git clone https://github.com/R0h1tAnand/kwin-meta-scroll-switcher.git
cd kwin-meta-scroll-switcher
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build
```

## Installing

```bash
sudo cmake --install build
```

This installs the plugin to `/usr/lib/x86_64-linux-gnu/qt6/plugins/kwin/effects/plugins/`.

## Enabling

Either toggle it on from **System Settings → Apps → Desktop Effects → "Meta+Scroll Desktop Switch"**, or from a terminal:

```bash
kwriteconfig6 --file kwinrc --group Plugins --key kwin_meta_scroll_desktopEnabled true
qdbus6 org.kde.KWin /KWin reconfigure
```

## Usage

Hold <kbd>Meta</kbd> and scroll over any window (not just the desktop background) to switch virtual desktops.

## Configuration

By default, scrolling past the last desktop wraps around to the first (and vice versa). This can be turned off from the effect's settings — click the gear icon next to "Meta+Scroll Desktop Switch" in **System Settings → Apps → Desktop Effects** and uncheck "Wrap around when reaching the first or last desktop", or from a terminal:

```bash
kwriteconfig6 --file kwinrc --group Effect-kwin_meta_scroll_desktop --key WrapAroundDesktops false
qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect kwin_meta_scroll_desktop
```

## Uninstalling

```bash
sudo rm /usr/lib/x86_64-linux-gnu/qt6/plugins/kwin/effects/plugins/kwin_meta_scroll_desktop.so
qdbus6 org.kde.KWin /KWin reconfigure
```

## Caveats

- Compiled against KWin's internal effect ABI, which is not stable across Plasma releases. Expect to rebuild after major Plasma version upgrades.
- Tested on Plasma/KWin 6.6.5. Other 6.x versions should work but aren't verified.

## License

[GPL-2.0-or-later](LICENSE), matching the license of the KWin library this plugin links against.
