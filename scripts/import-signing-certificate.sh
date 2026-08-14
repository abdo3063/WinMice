#!/bin/sh
set -eu

P12_B64="${APPLE_DEVELOPER_ID_P12_BASE64:?APPLE_DEVELOPER_ID_P12_BASE64 is required}"
P12_PASS="${APPLE_DEVELOPER_ID_P12_PASSWORD:?APPLE_DEVELOPER_ID_P12_PASSWORD is required}"

TMP="${RUNNER_TEMP:-}"
CREATED_TMP=0
if [ -z "$TMP" ]; then
  TMP="$(mktemp -d)"
  CREATED_TMP=1
fi

KEYCHAIN="$TMP/winmice-signing.keychain-db"
KEYCHAIN_PASS="$(/usr/bin/openssl rand -base64 32)"
P12_PATH="$TMP/winmice-signing.p12"

cleanup() {
  rm -f "$P12_PATH"
  if [ "$CREATED_TMP" -eq 1 ]; then
    rm -rf "$TMP"
  fi
}
trap cleanup EXIT HUP INT TERM

umask 077
printf '%s' "$P12_B64" | base64 --decode > "$P12_PATH"
chmod 600 "$P12_PATH"
echo "$KEYCHAIN" > "$TMP/winmice-keychain-path"

# The security CLI is not silent (e.g. `security import` prints
# "1 identity imported."). Every call below is redirected so the script's
# only stdout is the final identity line the workflow captures.
security create-keychain -p "$KEYCHAIN_PASS" "$KEYCHAIN" >/dev/null
security set-keychain-settings -lut 21600 "$KEYCHAIN" >/dev/null
security unlock-keychain -p "$KEYCHAIN_PASS" "$KEYCHAIN" >/dev/null

security import "$P12_PATH" -k "$KEYCHAIN" -P "$P12_PASS" \
  -T /usr/bin/codesign -T /usr/bin/security -T /usr/bin/productsign >/dev/null

# Rebuild the user keychain search list with the temp keychain first.
EXISTING="$(mktemp)"
security list-keychains -d user | sed 's/^[[:space:]]*"//;s/"[[:space:]]*$//' >"$EXISTING"
set -- "$KEYCHAIN"
while IFS= read -r kc; do
  [ -n "$kc" ] || continue
  set -- "$@" "$kc"
done <"$EXISTING"
rm -f "$EXISTING"
security list-keychains -d user -s "$@" >/dev/null

security set-key-partition-list -S apple-tool:,apple:,codesign: \
  -s -k "$KEYCHAIN_PASS" "$KEYCHAIN" >/dev/null

IDENTITY="$(security find-identity -v -p codesigning "$KEYCHAIN" \
  | awk -F'"' '/Developer ID Application/ { print $2; exit }')"

if [ -z "$IDENTITY" ]; then
  echo "No Developer ID Application identity found in keychain" >&2
  security find-identity -v -p codesigning "$KEYCHAIN" >&2 || true
  exit 1
fi

printf '%s\n' "$IDENTITY"
