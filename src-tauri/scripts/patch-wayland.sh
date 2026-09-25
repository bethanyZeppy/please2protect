#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname)" != "Linux" ]; then
  exit 0
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

APPIMAGE_DIR="src-tauri/target/release/bundle/appimage"
if [ ! -d "$APPIMAGE_DIR" ]; then
  exit 0
fi

APPIMAGE_NAME=$(find "$APPIMAGE_DIR" -maxdepth 1 -name "*.AppImage" -type f | head -n 1 || true)
if [ -z "$APPIMAGE_NAME" ]; then
  exit 0
fi

echo "Stripping GPU/Wayland libs from AppImage: $APPIMAGE_NAME"

WORKDIR=$(mktemp -d)
cd "$WORKDIR"
"$repo_root/$APPIMAGE_NAME" --appimage-extract > /dev/null
cd "$repo_root"

find "$WORKDIR/squashfs-root" \( \
  -name "libEGL.so*" -o \
  -name "libEGL_mesa.so*" -o \
  -name "libGLX.so*" -o \
  -name "libGLX_mesa.so*" -o \
  -name "libGLdispatch.so*" -o \
  -name "libGLESv2.so*" -o \
  -name "libGL.so*" -o \
  -name "libOpenGL.so*" -o \
  -name "libglapi.so*" -o \
  -name "libgbm.so*" -o \
  -name "libwayland-client.so*" -o \
  -name "libwayland-server.so*" -o \
  -name "libwayland-cursor.so*" -o \
  -name "libwayland-egl.so*" \
\) -delete

APPIMAGETOOL=$(find ~/.cache/tauri -name "appimagetool*" -type f 2>/dev/null | head -n 1 || true)
if [ -z "$APPIMAGETOOL" ]; then
  wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O /tmp/appimagetool
  chmod +x /tmp/appimagetool
  APPIMAGETOOL=/tmp/appimagetool
fi

rm -f "$repo_root/$APPIMAGE_NAME"
ARCH=x86_64 "$APPIMAGETOOL" --appimage-extract-and-run --no-appstream "$WORKDIR/squashfs-root" "$repo_root/$APPIMAGE_NAME"

rm -rf "$WORKDIR"

echo "AppImage repackaged without GPU/Wayland libs: $APPIMAGE_NAME"