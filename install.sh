#!/usr/bin/env bash
# install.sh — Build and install kwin-meta-scroll-desktop
# Usage: bash install.sh [--uninstall] [--enable] [--disable]
# Requires: apt-based distro (Debian/Ubuntu/Kali), KDE Plasma 6

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[info]${NC}  $*"; }
success() { echo -e "${GREEN}[ok]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${NC}  $*"; }
error()   { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

PLUGIN_ID="kwin_meta_scroll_desktop"
PLUGIN_SO="/usr/lib/x86_64-linux-gnu/qt6/plugins/kwin/effects/plugins/${PLUGIN_ID}.so"
CONFIG_SO="/usr/lib/x86_64-linux-gnu/qt6/plugins/kwin/effects/configs/${PLUGIN_ID}_config.so"

# ── Helpers ───────────────────────────────────────────────────────────────────
reconfigure_kwin() {
    if command -v qdbus6 &>/dev/null; then
        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    elif command -v qdbus &>/dev/null; then
        qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    else
        warn "qdbus not found — restart KWin manually to apply changes."
    fi
}

# ── Modes ─────────────────────────────────────────────────────────────────────
case "${1:-}" in

    --uninstall)
        info "Uninstalling ${PLUGIN_ID}…"
        sudo rm -f "$PLUGIN_SO" "$CONFIG_SO"
        reconfigure_kwin
        success "Plugin removed."
        exit 0
        ;;

    --enable)
        info "Enabling ${PLUGIN_ID}…"
        kwriteconfig6 --file kwinrc --group Plugins --key "${PLUGIN_ID}Enabled" true
        reconfigure_kwin
        success "Plugin enabled. Hold Meta and scroll to switch desktops."
        exit 0
        ;;

    --disable)
        info "Disabling ${PLUGIN_ID}…"
        kwriteconfig6 --file kwinrc --group Plugins --key "${PLUGIN_ID}Enabled" false
        reconfigure_kwin
        success "Plugin disabled."
        exit 0
        ;;

    --help|-h)
        echo "Usage: bash install.sh [option]"
        echo ""
        echo "  (no args)    Install deps, build, and install the plugin"
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
echo -e "${CYAN}│  kwin-meta-scroll-desktop  ·  installer          │${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────┘${NC}"
echo ""

# 1. Dependencies
info "Installing build dependencies…"
sudo apt-get install -y \
    cmake \
    extra-cmake-modules \
    kwin-dev \
    qt6-base-dev \
    qt6-declarative-dev \
    libkf6coreaddons-dev \
    libkf6config-dev \
    libkf6globalaccel-dev \
    libkf6i18n-dev \
    libkf6kcmutils-dev \
    libdrm-dev \
    libepoxy-dev \
    libwayland-dev
success "Dependencies satisfied."

# 2. Build
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

info "Configuring with CMake…"
cmake -S "$SCRIPT_DIR" -B "$BUILD_DIR" -DCMAKE_INSTALL_PREFIX=/usr

info "Building…"
cmake --build "$BUILD_DIR" --parallel "$(nproc)"
success "Build complete."

# 3. Install
info "Installing (requires sudo)…"
sudo cmake --install "$BUILD_DIR"
success "Plugin installed to /usr/lib/.../kwin/effects/plugins/"

# 4. Enable
info "Enabling plugin in KWin…"
kwriteconfig6 --file kwinrc --group Plugins --key "${PLUGIN_ID}Enabled" true
reconfigure_kwin

echo ""
success "Done! Hold Meta and scroll to switch virtual desktops."
echo -e "  ${YELLOW}Tip:${NC} Run  bash install.sh --disable   to disable without uninstalling."
echo -e "  ${YELLOW}Tip:${NC} Run  bash install.sh --uninstall to remove it completely."
echo ""
