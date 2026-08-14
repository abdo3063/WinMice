#!/bin/sh
set -eu

DMG="${1:?usage: verify-notarized-dmg.sh <WinMice.dmg>}"
[ -f "$DMG" ] || { echo "missing disk image: $DMG" >&2; exit 1; }

codesign --verify --verbose=2 "$DMG"

INFO="$(mktemp)"
trap 'rm -f "$INFO"' EXIT
codesign -dv --verbose=4 "$DMG" >"$INFO" 2>&1 || true

if grep -q 'Signature=adhoc' "$INFO"; then
  echo "refusing ad-hoc signature" >&2
  exit 1
fi
if ! grep -q 'Developer ID Application' "$INFO"; then
  echo "expected Developer ID Application identity" >&2
  cat "$INFO" >&2
  exit 1
fi
if ! grep -q '^Timestamp=' "$INFO"; then
  echo "expected a secure timestamp" >&2
  cat "$INFO" >&2
  exit 1
fi

spctl --assess --type open --context context:primary-signature -vv "$DMG"
xcrun stapler validate "$DMG"

echo "Verified notarized disk image: $DMG"
