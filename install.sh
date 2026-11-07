#!/usr/bin/env bash
# install.sh — Build and install kwin-meta-scroll-desktop
# Usage: bash install.sh [--uninstall] [--enable] [--disable]
# Requires: Fedora/dnf-based distro, KDE Plasma 6

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[info]${NC}  $*"; }
success() { echo -e "${GREEN}[ok]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${NC}  $*"; }
error()   { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

PLUGIN_ID="kwin_meta_scroll_desktop"

# On Fedora, 64-bit libraries are located in /usr/lib64
LIB_DIR="/usr/lib64"
if [ ! -d "$LIB_DIR" ]; then
    LIB_DIR="/usr/lib"
fi

PLUGIN_SO="${LIB_DIR}/qt6/plugins/kwin/effects/plugins/${PLUGIN_ID}.so"
CONFIG_SO="${LIB_DIR}/qt6/plugins/kwin/effects/configs/${PLUGIN_ID}_config.so"

# Auto-rebuild after KWin updates (see systemd/)
REBUILD_UNIT="kwin-meta-scroll-rebuild.service"
REBUILD_UNIT_PATH="/etc/systemd/system/${REBUILD_UNIT}"
REBUILD_BIN="/usr/local/bin/kwin-meta-scroll-rebuild"
REBUILD_ACTIONS="/etc/dnf/libdnf5-plugins/actions.d/kwin-meta-scroll-rebuild.actions"
REBUILD_SRC="/usr/local/src/kwin-meta-scroll-desktop"
REBUILD_STATE="/var/lib/kwin-meta-scroll-desktop"

# ── Helpers ───────────────────────────────────────────────────────────────────
effects_call() {
    busctl --user call org.kde.KWin /Effects org.kde.kwin.Effects "$1" s "$PLUGIN_ID" \
        >/dev/null 2>&1 || true
}

# KWin's reconfigure does not load a newly enabled effect, so ask for it by name.
# Unloading first makes a rebuild take effect when the old one is still loaded.
load_effect() {
    effects_call unloadEffect
    effects_call loadEffect
}

# ── Modes ─────────────────────────────────────────────────────────────────────
case "${1:-}" in

    --uninstall)
        info "Uninstalling ${PLUGIN_ID}…"
        effects_call unloadEffect
        sudo systemctl disable "$REBUILD_UNIT" 2>/dev/null || true
        sudo rm -f "$REBUILD_UNIT_PATH" "$REBUILD_BIN" "$REBUILD_ACTIONS"
        sudo rm -rf "$REBUILD_SRC" "$REBUILD_STATE"
        sudo systemctl daemon-reload
        sudo rm -f "$PLUGIN_SO" "$CONFIG_SO"
        success "Plugin removed."
        exit 0
        ;;

    --enable)
        info "Enabling ${PLUGIN_ID}…"
        kwriteconfig6 --file kwinrc --group Plugins --key "${PLUGIN_ID}Enabled" true
        load_effect
        success "Plugin enabled. Hold Meta and scroll to switch desktops."
        exit 0
        ;;

    --disable)
        info "Disabling ${PLUGIN_ID}…"
        kwriteconfig6 --file kwinrc --group Plugins --key "${PLUGIN_ID}Enabled" false
        effects_call unloadEffect
        success "Plugin disabled."
        exit 0
        ;;

    --help|-h)
        echo "Usage: bash install.sh [option]"
        echo ""
        echo "  (no args)    Install deps, build, install the plugin and its auto-rebuild service"
        echo "  --enable     Enable the plugin in KWin"
        echo "  --disable    Disable the plugin in KWin"
        echo "  --uninstall  Remove the plugin from the system"
        echo "  --help       Show this help"
        exit 0
        ;;
esac

# ── Full install (default) ────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}┌─────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│  kwin-meta-scroll-desktop  ·  installer         │${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────┘${NC}"
echo ""

# 1. Dependencies
info "Installing build dependencies…"
sudo dnf install -y \
    cmake \
    extra-cmake-modules \
    kwin-devel \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    kf6-kcoreaddons-devel \
    kf6-kconfig-devel \
    kf6-kglobalaccel-devel \
    kf6-ki18n-devel \
    kf6-kcmutils-devel \
    libdrm-devel \
    libepoxy-devel \
    wayland-devel \
    libdnf5-plugin-actions
success "Dependencies satisfied."

# 2. Build
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

info "Configuring with CMake…"
# Specify libdir explicitly so CMake builds the plugin in the correct location (lib64)
cmake -S "$SCRIPT_DIR" -B "$BUILD_DIR" -DCMAKE_INSTALL_PREFIX=/usr -DKDE_INSTALL_LIBDIR=lib64

info "Building…"
cmake --build "$BUILD_DIR" --parallel "$(nproc)"
success "Build complete."

# 3. Install
info "Installing (requires sudo)…"
# Unlink first: cmake overwrites in place, which would crash a KWin that has the
# old plugin mapped. An unlinked file stays valid for the running process.
sudo rm -f "$PLUGIN_SO" "$CONFIG_SO"
sudo cmake --install "$BUILD_DIR"
success "Plugin installed."

# 4. Auto-rebuild after KWin updates
info "Setting up automatic rebuild after KWin updates…"
sudo rm -rf "$REBUILD_SRC"
sudo mkdir -p "$REBUILD_SRC" "$REBUILD_STATE"
sudo cp -r "${SCRIPT_DIR}/CMakeLists.txt" "${SCRIPT_DIR}/src" "$REBUILD_SRC/"
sudo install -D -m 755 "${SCRIPT_DIR}/systemd/kwin-meta-scroll-rebuild.sh" "$REBUILD_BIN"
sudo install -m 644 "${SCRIPT_DIR}/systemd/${REBUILD_UNIT}" "$REBUILD_UNIT_PATH"
sudo install -D -m 644 "${SCRIPT_DIR}/systemd/kwin-meta-scroll-rebuild.actions" "$REBUILD_ACTIONS"
rpm -q kwin | sudo tee "${REBUILD_STATE}/built-for" >/dev/null
sudo systemctl daemon-reload
sudo systemctl enable "$REBUILD_UNIT"
success "Auto-rebuild enabled."

# 5. Enable
info "Enabling plugin in KWin…"
kwriteconfig6 --file kwinrc --group Plugins --key "${PLUGIN_ID}Enabled" true
load_effect

echo ""
success "Done! Hold Meta and scroll to switch virtual desktops."
echo -e "  ${YELLOW}Tip:${NC} Run  bash install.sh --disable   to disable without uninstalling."
echo -e "  ${YELLOW}Tip:${NC} Run  bash install.sh --uninstall to remove it completely."
echo ""
