#!/usr/bin/env bash
# Rebuild the effect when the installed KWin differs from the one it was built
# for. KWin refuses plugins built for any other version, so every Plasma update
# needs a rebuild. Runs as root at boot and after dnf updates KWin, from a
# root-owned copy of the sources.

set -euo pipefail

SRC_DIR="/usr/local/src/kwin-meta-scroll-desktop"
STAMP="/var/lib/kwin-meta-scroll-desktop/built-for"
PLUGIN_SO="/usr/lib64/qt6/plugins/kwin/effects/plugins/kwin_meta_scroll_desktop.so"
CONFIG_SO="/usr/lib64/qt6/plugins/kwin/effects/configs/kwin_meta_scroll_desktop_config.so"
PREFIX="/usr"

current="$(rpm -q kwin)"

if [ -f "$PLUGIN_SO" ] && [ "$(cat "$STAMP" 2>/dev/null)" = "$current" ]; then
    exit 0
fi

echo "Rebuilding for ${current}"

build_dir="$(mktemp -d /var/tmp/kwin-meta-scroll-desktop.XXXXXX)"
trap 'rm -rf "$build_dir"' EXIT

cmake -S "$SRC_DIR" -B "$build_dir" -DCMAKE_INSTALL_PREFIX="$PREFIX" -DKDE_INSTALL_LIBDIR=lib64
cmake --build "$build_dir" --parallel "$(nproc)"
# Unlink first: cmake overwrites in place, which would crash a KWin that has the
# old plugin mapped. An unlinked file stays valid for the running process.
rm -f "$PLUGIN_SO" "$CONFIG_SO"
cmake --install "$build_dir"

# Written last: a failed build leaves the stamp alone and retries on next boot.
mkdir -p "$(dirname "$STAMP")"
echo "$current" > "$STAMP"
