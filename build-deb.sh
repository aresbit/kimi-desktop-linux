#!/usr/bin/env bash
# Build kimi_3.2.28_amd64.deb from the Linux Electron assembly (kimi-linux/) + macOS DMG resources.
# Requires: dpkg-deb, the prepared kimi-linux/ dir and dmg/ extraction.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="3.2.28"
ARCH="amd64"
PKG_NAME="kimi_${VERSION}_${ARCH}.deb"
BUILD_DIR="${SCRIPT_DIR}/deb-pkg"
APP_SRC="${SCRIPT_DIR}/kimi-linux"
DMG_APP="${SCRIPT_DIR}/dmg/Kimi Installer 3.2.28-arm64/Kimi Installer.app/Contents/Helpers/Kimi.app/Contents"
ICONS="${SCRIPT_DIR}/icons"

if [ ! -d "${APP_SRC}" ]; then
    echo "Error: ${APP_SRC} not found. Assemble the Electron runtime first." >&2
    exit 1
fi
if [ ! -f "${DMG_APP}/Resources/app.asar" ]; then
    echo "Error: extracted DMG app not found at ${DMG_APP}" >&2
    exit 1
fi

echo "Building ${PKG_NAME} ..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/DEBIAN" \
         "${BUILD_DIR}/usr/lib/kimi" \
         "${BUILD_DIR}/usr/bin" \
         "${BUILD_DIR}/usr/share/applications" \
         "${BUILD_DIR}/usr/share/icons/hicolor"

# --- Electron runtime (binary renamed to kimi) ---
cp -a "${APP_SRC}/." "${BUILD_DIR}/usr/lib/kimi/"
rm -rf "${BUILD_DIR}/usr/lib/kimi/resources/app"
rm -f  "${BUILD_DIR}/usr/lib/kimi/resources/default_app.asar" \
       "${BUILD_DIR}/usr/lib/kimi/resources/icon.icns"
mv "${BUILD_DIR}/usr/lib/kimi/electron" "${BUILD_DIR}/usr/lib/kimi/kimi"

# --- App payload straight from the DMG (unaltered asar) ---
cp -a "${DMG_APP}/Resources/app.asar" "${BUILD_DIR}/usr/lib/kimi/resources/"
cp -a "${DMG_APP}/Resources/app.asar.unpacked" "${BUILD_DIR}/usr/lib/kimi/resources/"
# resources/resources comes from kimi-linux (patched with the Linux daimon runtime:
# linux node, uv, CPython 3.12 and @node-rs/jieba-linux-x64-gnu)
rm -rf "${BUILD_DIR}/usr/lib/kimi/resources/resources"
cp -a "${APP_SRC}/resources/resources" "${BUILD_DIR}/usr/lib/kimi/resources/"
# strip AppleDouble/xattr sidecar files
find "${BUILD_DIR}/usr/lib/kimi/resources" -name '*:com.apple.*' -delete

# --- icons ---
for size in 32 64 128 256 512 1024; do
    d="${BUILD_DIR}/usr/share/icons/hicolor/${size}x${size}/apps"
    mkdir -p "$d"
    install -m 644 "${ICONS}/kimi-${size}.png" "$d/kimi.png"
done
# --- desktop entry ---
cat > "${BUILD_DIR}/usr/share/applications/kimi.desktop" <<'EOF'
[Desktop Entry]
Name=Kimi
Comment=Kimi AI Desktop
Exec=/usr/bin/kimi --no-sandbox %U
Terminal=false
Type=Application
Icon=kimi
Categories=Office;Network;
StartupNotify=true
StartupWMClass=kimi
MimeType=x-scheme-handler/kimi;
EOF

# --- launcher: seed mainland region on first run so +86 login is available ---
cat > "${BUILD_DIR}/usr/bin/kimi" <<'EOF'
#!/bin/sh
# Default to the mainland (kimi.com) region so the login dialog offers +86.
# Users can switch back to the international login from the dialog; an existing
# region.json is never overwritten.
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kimi-desktop/bridge-store"
if [ ! -f "$CONF_DIR/region.json" ]; then
    mkdir -p "$CONF_DIR" 2>/dev/null || true
    printf '%s\n' '{"manual":"china","lastEffective":"china"}' > "$CONF_DIR/region.json" 2>/dev/null || true
fi
exec /usr/lib/kimi/kimi --no-sandbox --class=kimi "$@"
EOF
chmod 755 "${BUILD_DIR}/usr/bin/kimi"

# --- debian control ---
cat > "${BUILD_DIR}/DEBIAN/control" <<EOF
Package: kimi
Version: ${VERSION}
Section: net
Priority: optional
Architecture: ${ARCH}
Depends: libgtk-3-0, libnotify4, libnss3, libxss1, libxtst6, xdg-utils, libatspi2.0-0, libuuid1, libsecret-1-0
Recommends: libgbm1, libasound2 | libasound2t64
Maintainer: Package Maintainer <maintainer@example.com>
Description: Kimi AI Desktop
 Kimi desktop application for Linux, repackaged from the macOS 3.2.28 build.
EOF

cat > "${BUILD_DIR}/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
chmod 4755 /usr/lib/kimi/chrome-sandbox 2>/dev/null || true
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor || true
fi
exit 0
EOF
chmod 755 "${BUILD_DIR}/DEBIAN/postinst"

# --- build ---
dpkg-deb --build "${BUILD_DIR}" "${SCRIPT_DIR}/${PKG_NAME}"

echo ""
echo "Success: ${PKG_NAME}"
echo "Install with: sudo dpkg -i ${PKG_NAME}"
