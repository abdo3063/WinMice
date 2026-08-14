#!/bin/sh
set -eu

APP="${1:?usage: verify-bundle-metadata.sh <WinMice.app> <expected-version>}"
EXPECTED_VERSION="${2:?usage: verify-bundle-metadata.sh <WinMice.app> <expected-version>}"
PLIST="$APP/Contents/Info.plist"
EXPECTED_ID="cz.anibalribeiro.winmice"

ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PLIST")
SHORT=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")
BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PLIST")

fail=0
[ "$ID" = "$EXPECTED_ID" ] || { echo "CFBundleIdentifier: got '$ID' want '$EXPECTED_ID'"; fail=1; }
[ "$SHORT" = "$EXPECTED_VERSION" ] || { echo "CFBundleShortVersionString: got '$SHORT' want '$EXPECTED_VERSION'"; fail=1; }
[ "$BUILD" = "$EXPECTED_VERSION" ] || { echo "CFBundleVersion: got '$BUILD' want '$EXPECTED_VERSION'"; fail=1; }
exit "$fail"
