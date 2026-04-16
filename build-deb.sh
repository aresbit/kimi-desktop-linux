#!/usr/bin/env bash
set -e

# Build .deb package from the assembled kimi-linux/ directory.
# Requires: dpkg-deb, standard GNU tools.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPT_DIR}/kimi-linux"
VERSION="3.0.0"
ARCH="amd64"
PKG_NAME="kimi_${VERSION}_${ARCH}.deb"
BUILD_DIR="${SCRIPT_DIR}/deb-pkg"

if [ ! -d "${APP_DIR}" ]; then
    echo "Error: ${APP_DIR} not found."
    echo "Please download the Linux runtime + app.asar from GitHub Releases,"
    echo "or run the conversion steps locally to produce kimi-linux/."
    exit 1
fi

echo "Building ${PKG_NAME} ..."

# Clean previous build
rm -rf "${BUILD_DIR}"

# Directory structure
mkdir -p "${BUILD_DIR}/DEBIAN"
mkdir -p "${BUILD_DIR}/usr/lib/kimi"
mkdir -p "${BUILD_DIR}/usr/share/applications"
mkdir -p "${BUILD_DIR}/usr/share/icons/hicolor/1024x1024/apps"
mkdir -p "${BUILD_DIR}/usr/share/icons/hicolor/256x256/apps"
mkdir -p "${BUILD_DIR}/usr/share/icons/hicolor/128x128/apps"
mkdir -p "${BUILD_DIR}/usr/share/icons/hicolor/64x64/apps"
mkdir -p "${BUILD_DIR}/usr/share/icons/hicolor/32x32/apps"
mkdir -p "${BUILD_DIR}/usr/bin"

# Copy app
cp -r "${APP_DIR}"/* "${BUILD_DIR}/usr/lib/kimi/"

# Generate icons if icon.png exists
if [ -f "${SCRIPT_DIR}/icon.png" ]; then
    python3 - <<PY
from PIL import Image
import os

src = "${SCRIPT_DIR}/icon.png"
base = "${BUILD_DIR}/usr/share/icons/hicolor"
img = Image.open(src)

for size in [1024, 256, 128, 64, 32]:
    resized = img.resize((size, size), Image.LANCZOS)
    path = os.path.join(base, f"{size}x{size}/apps/kimi.png")
    resized.save(path)
    print(f"Generated {size}x{size} icon")
PY
else
    echo "Warning: icon.png not found, skipping icon generation"
fi

# Desktop entry
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
MimeType=x-scheme-handler/kimi;
EOF

# Launcher script
cat > "${BUILD_DIR}/usr/bin/kimi" <<'EOF'
#!/bin/sh
exec /usr/lib/kimi/kimi --no-sandbox "$@"
EOF
chmod 755 "${BUILD_DIR}/usr/bin/kimi"

# Debian control
cat > "${BUILD_DIR}/DEBIAN/control" <<EOF
Package: kimi
Version: ${VERSION}
Section: net
Priority: optional
Architecture: ${ARCH}
Depends: libgtk-3-0, libnotify4, libnss3, libxss1, libxtst6, xdg-utils, libatspi2.0-0, libuuid1, libsecret-1-0
Recommends: libgbm1, libasound2
Maintainer: Package Maintainer <maintainer@example.com>
Description: Kimi AI Desktop
 Kimi desktop application for Linux.
EOF

# Post-install script
cat > "${BUILD_DIR}/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
chmod 4755 /usr/lib/kimi/chrome-sandbox || true
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor || true
fi
exit 0
EOF
chmod 755 "${BUILD_DIR}/DEBIAN/postinst"

# Permissions
chmod 755 "${BUILD_DIR}/usr/lib/kimi/kimi"
chmod 4755 "${BUILD_DIR}/usr/lib/kimi/chrome-sandbox"

# Build package
dpkg-deb --build "${BUILD_DIR}" "${SCRIPT_DIR}/${PKG_NAME}"

echo ""
echo "Success: ${PKG_NAME}"
echo "Install with: sudo dpkg -i ${PKG_NAME}"
