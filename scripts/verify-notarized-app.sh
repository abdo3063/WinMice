#!/bin/sh
set -eu

APP="${1:?usage: verify-notarized-app.sh <WinMice.app>}"
[ -d "$APP" ] || { echo "missing app bundle: $APP" >&2; exit 1; }

codesign --verify --deep --strict --verbose=2 "$APP"

INFO="$(mktemp)"
trap 'rm -f "$INFO"' EXIT
codesign -dv --verbose=4 "$APP" >"$INFO" 2>&1 || true

if grep -q 'Signature=adhoc' "$INFO"; then
  echo "refusing ad-hoc signature" >&2
  exit 1
fi
if ! grep -q 'Developer ID Application' "$INFO"; then
  echo "expected Developer ID Application identity" >&2
  cat "$INFO" >&2
  exit 1
fi
if ! grep -q 'flags=.*runtime' "$INFO"; then
  echo "expected hardened runtime" >&2
  cat "$INFO" >&2
  exit 1
fi
if ! grep -q '^Timestamp=' "$INFO"; then
  echo "expected a secure timestamp" >&2
  cat "$INFO" >&2
  exit 1
fi

spctl --assess --type execute -vv "$APP"
xcrun stapler validate "$APP"

echo "Verified notarized app: $APP"
