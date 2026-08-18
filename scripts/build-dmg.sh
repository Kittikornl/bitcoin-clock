#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="BitcoinClock"
VERSION="${1:-1.0.0}"
if [[ ! "$VERSION" =~ ^[0-9][0-9A-Za-z.+-]*$ ]]; then
  echo "Invalid version '$VERSION' (expected e.g. 1.0.0)" >&2
  exit 1
fi
BUILD_DIR=".build/dist"
STAGING_DIR="$BUILD_DIR/staging"
APP_BUNDLE="$STAGING_DIR/$APP_NAME.app"

rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

echo "Building universal binary (arm64 + x86_64)..."
swift build -c release --arch arm64
swift build -c release --arch x86_64
lipo -create \
  ".build/arm64-apple-macosx/release/$APP_NAME" \
  ".build/x86_64-apple-macosx/release/$APP_NAME" \
  -output "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.kittikornl.bitcoinclock</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>Bitcoin Clock</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "Ad-hoc signing app bundle..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Building dmg..."
ln -s /Applications "$STAGING_DIR/Applications"
DMG_PATH="$BUILD_DIR/$APP_NAME-$VERSION.dmg"
rm -f "$DMG_PATH"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"

echo "Done: $DMG_PATH"
