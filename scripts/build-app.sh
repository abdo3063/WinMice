#!/bin/sh
set -eu

VERSION="${WINMICE_VERSION:-0.0.0-dev}"
while [ $# -gt 0 ]; do
  case "$1" in
    --version)
      VERSION="${2:?--version requires a value}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done
case "$VERSION" in
  "") echo "Version must be non-empty" >&2; exit 1 ;;
esac

swift build -c release

APP_DIR="dist/WinMice.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
ICONSET="dist/WinMice.iconset"

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"

cp ".build/release/WinMice" "$MACOS/WinMice"
swift scripts/make-icons.swift "$ICONSET"
iconutil -c icns "$ICONSET" -o "$RESOURCES/WinMice.icns"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>WinMice</string>
    <key>CFBundleIdentifier</key>
    <string>cz.anibalribeiro.winmice</string>
    <key>CFBundleName</key>
    <string>WinMice</string>
    <key>CFBundleDisplayName</key>
    <string>WinMice</string>
    <key>CFBundleIconFile</key>
    <string>WinMice.icns</string>
    <key>CFBundleIconName</key>
    <string>WinMice</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAccessibilityUsageDescription</key>
    <string>WinMice uses accessibility to bring the window under the cursor forward, post native scroll events, and handle back/forward navigation on your behalf.</string>
</dict>
</plist>
PLIST

ENTITLEMENTS="$(CDPATH= cd -- "$(dirname "$0")" && pwd)/WinMice.entitlements"
if [ -n "${CODESIGN_IDENTITY:-}" ]; then
  # --timestamp requests a secure timestamp explicitly; notarization requires
  # one, and codesign's unspecified default may skip it on some signatures.
  codesign --force --options runtime --timestamp \
    --entitlements "$ENTITLEMENTS" \
    --sign "$CODESIGN_IDENTITY" \
    "$APP_DIR"
else
  if [ "${WINMICE_REQUIRE_DEVELOPER_ID:-0}" = "1" ]; then
    echo "CODESIGN_IDENTITY is required when WINMICE_REQUIRE_DEVELOPER_ID=1 (refusing to ad-hoc sign a release build)" >&2
    exit 1
  fi
  codesign --force --deep --sign - "$APP_DIR" >/dev/null
fi
touch "$APP_DIR"

echo "Built $APP_DIR"
