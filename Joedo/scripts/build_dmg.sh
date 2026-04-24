#!/bin/bash
# Build a distributable DMG of Joedo using hdiutil directly (no external
# create-dmg dependency). Produces dist/Joedo.dmg with:
#   • ad-hoc code signing
#   • custom volume icon (JoeDo.icns)
#   • Applications symlink for drag-to-install
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Joedo"
CONFIG="Release"
BUILD_DIR="$(pwd)/build"
APP_DIR="$BUILD_DIR/Build/Products/$CONFIG/$APP_NAME.app"
DIST_DIR="$(pwd)/dist"
STAGE_DIR="$DIST_DIR/stage"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
TEMP_DMG="$DIST_DIR/$APP_NAME-rw.dmg"
VOLICON="$(pwd)/../source-assets/AppIcon.appiconset/JoeDo.icns"

echo "==> Building $APP_NAME ($CONFIG)…"
xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration "$CONFIG" \
  -derivedDataPath "$BUILD_DIR" \
  -quiet \
  clean build

[[ -d "$APP_DIR" ]] || { echo "error: .app not found at $APP_DIR" >&2; exit 1; }

echo "==> Re-signing ad-hoc…"
codesign --force --deep --sign - "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"

echo "==> Staging DMG contents…"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
cp -R "$APP_DIR" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"
# Drop the volume icon in — will be activated by SetFile below.
if [[ -f "$VOLICON" ]]; then
  cp "$VOLICON" "$STAGE_DIR/.VolumeIcon.icns"
fi

echo "==> Creating read-write DMG…"
rm -f "$DMG_PATH" "$TEMP_DMG"
hdiutil create -volname "$APP_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov -format UDRW \
  "$TEMP_DMG" >/dev/null

if [[ -f "$VOLICON" ]]; then
  echo "==> Applying volume icon…"
  DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" \
           | grep -E "^/dev/" | head -1 | awk '{print $1}')
  MOUNT_POINT=$(hdiutil info | awk -v dev="$DEVICE" '$1==dev {print $3}' | head -1)
  if [[ -n "${MOUNT_POINT:-}" && -d "$MOUNT_POINT" ]]; then
    SetFile -a C "$MOUNT_POINT"
    sync
  fi
  hdiutil detach "$DEVICE" -quiet || true
fi

echo "==> Compressing to final DMG…"
hdiutil convert "$TEMP_DMG" \
  -format UDZO -imagekey zlib-level=9 \
  -o "$DMG_PATH" >/dev/null
rm -f "$TEMP_DMG"
rm -rf "$STAGE_DIR"

# Apply the icon to the DMG FILE itself (separate from the volume icon,
# which only shows when the DMG is mounted). NSWorkspace.setIcon embeds
# the custom icon into the file's extended attributes.
if [[ -f "$VOLICON" ]]; then
  echo "==> Stamping DMG file icon…"
  swift -e "
import AppKit
if let img = NSImage(contentsOfFile: \"$VOLICON\") {
    let ok = NSWorkspace.shared.setIcon(img, forFile: \"$DMG_PATH\", options: [])
    print(ok ? \"set\" : \"failed\")
} else {
    print(\"could not load icon\")
}
"
fi

echo "==> Done: $DMG_PATH"
du -h "$DMG_PATH"
