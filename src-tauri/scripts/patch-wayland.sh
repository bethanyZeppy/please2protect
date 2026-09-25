#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname)" != "Linux" ]; then
  echo "Not Linux, skipping AppImage patch"
  exit 0
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

if [ ! -d "src-tauri/target/release/bundle/appimage" ]; then
  echo "No appimage bundle directory, skipping patch"
  exit 0
fi

APP_DIR_REL=$(find src-tauri/target/release/bundle/appimage -maxdepth 1 -type d -name "*.AppDir" 2>/dev/null | head -n 1 || true)

if [ -z "$APP_DIR_REL" ]; then
  echo "No AppDir found, skipping patch"
  exit 0
fi

APP_DIR="$(cd "$APP_DIR_REL" && pwd)"
echo "Patching AppDir: $APP_DIR"

mkdir -p "$APP_DIR/apprun-hooks"
cp src-tauri/scripts/compat.sh "$APP_DIR/apprun-hooks/wayland-compat.sh"
chmod +x "$APP_DIR/apprun-hooks/wayland-compat.sh"

APPRUN="$APP_DIR/AppRun"
if ! grep -q "wayland-compat.sh" "$APPRUN"; then
  sed -i 's|exec "$HERE/AppRun.wrapped"|source "$HERE/apprun-hooks/wayland-compat.sh"\nexec "$HERE/AppRun.wrapped"|' "$APPRUN"
fi

APPIMAGE_NAME=$(ls "$APP_DIR/../"*.AppImage 2>/dev/null | head -n 1 || true)
if [ -n "$APPIMAGE_NAME" ]; then
  rm -f "$APPIMAGE_NAME"
fi

APPIMAGETOOL=$(find ~/.cache/tauri -name "appimagetool*" -type f 2>/dev/null | head -n 1 || true)
if [ -z "$APPIMAGETOOL" ]; then
  wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O /tmp/appimagetool
  chmod +x /tmp/appimagetool
  APPIMAGETOOL=/tmp/appimagetool
fi

ARCH=x86_64 "$APPIMAGETOOL" --appimage-extract-and-run --no-appstream "$APP_DIR"
echo "AppImage repackaged with Wayland hook"