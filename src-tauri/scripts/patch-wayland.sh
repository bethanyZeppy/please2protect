#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname)" != "Linux" ]; then
  echo "Not Linux, skipping AppImage patch"
  exit 0
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

APPIMAGE_DIR="src-tauri/target/release/bundle/appimage"
if [ ! -d "$APPIMAGE_DIR" ]; then
  echo "No appimage bundle directory, skipping patch"
  exit 0
fi

APPIMAGE_NAME=$(find "$APPIMAGE_DIR" -maxdepth 1 -name "*.AppImage" -type f | head -n 1 || true)
if [ -z "$APPIMAGE_NAME" ]; then
  echo "No AppImage found, skipping patch"
  exit 0
fi

echo "Patching AppImage: $APPIMAGE_NAME"

WORKDIR=$(mktemp -d)
cd "$WORKDIR"
"$repo_root/$APPIMAGE_NAME" --appimage-extract > /dev/null
cd "$repo_root"

mkdir -p "$WORKDIR/squashfs-root/apprun-hooks"
cp src-tauri/scripts/compat.sh "$WORKDIR/squashfs-root/apprun-hooks/wayland-compat.sh"
chmod +x "$WORKDIR/squashfs-root/apprun-hooks/wayland-compat.sh"

APPRUN="$WORKDIR/squashfs-root/AppRun"
if ! grep -q "wayland-compat.sh" "$APPRUN"; then
  sed -i 's|exec "$HERE/AppRun.wrapped"|source "$HERE/apprun-hooks/wayland-compat.sh"\nexec "$HERE/AppRun.wrapped"|' "$APPRUN"
fi

APPIMAGETOOL=$(find ~/.cache/tauri -name "appimagetool*" -type f 2>/dev/null | head -n 1 || true)
if [ -z "$APPIMAGETOOL" ]; then
  wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O /tmp/appimagetool
  chmod +x /tmp/appimagetool
  APPIMAGETOOL=/tmp/appimagetool
fi

rm -f "$repo_root/$APPIMAGE_NAME"
ARCH=x86_64 "$APPIMAGETOOL" --appimage-extract-and-run --no-appstream "$WORKDIR/squashfs-root" "$repo_root/$APPIMAGE_NAME"

rm -rf "$WORKDIR"

echo "AppImage repackaged with Wayland hook: $APPIMAGE_NAME"