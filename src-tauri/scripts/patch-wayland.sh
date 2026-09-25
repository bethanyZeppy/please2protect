#!/usr/bin/env bash
set -euo pipefail

APP_DIR=$(find src-tauri/target/release/bundle/appimage -maxdepth 1 -type d -name "*.AppDir" | head -n 1)

if [ -z "$APP_DIR" ]; then
  echo "No AppDir found, skipping patch"
  exit 0
fi

echo "Patching AppDir: $APP_DIR"

mkdir -p "$APP_DIR/apprun-hooks"
cp src-tauri/appimage/compat.sh "$APP_DIR/apprun-hooks/compat.sh"
chmod +x "$APP_DIR/apprun-hooks/compat.sh"

APPRUN="$APP_DIR/AppRun"
if ! grep -q "compat.sh" "$APPRUN"; then
  sed -i 's|exec "$HERE/AppRun.wrapped"|source "$HERE/apprun-hooks/compat.sh"\nexec "$HERE/AppRun.wrapped"|' "$APPRUN"
fi

cd src-tauri/target/release/bundle/appimage
APPIMAGE_NAME=$(ls *.AppImage | head -n 1)
rm -f "$APPIMAGE_NAME"

APPIMAGETOOL=$(find ~/.cache/tauri -name "appimagetool*" -type f | head -n 1)
if [ -z "$APPIMAGETOOL" ]; then
  wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O /tmp/appimagetool
  chmod +x /tmp/appimagetool
  APPIMAGETOOL=/tmp/appimagetool
fi

ARCH=x86_64 "$APPIMAGETOOL" --appimage-extract-and-run --no-appstream "$APP_DIR"
echo "AppImage repackaged with Wayland hook"