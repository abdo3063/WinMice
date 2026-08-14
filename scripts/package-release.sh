#!/bin/sh
set -eu

VERSION="${1:?usage: package-release.sh <version>}"
APP_DIR="dist/WinMice.app"
OUT="dist/WinMice-${VERSION}.zip"

[ -d "$APP_DIR" ] || { echo "Missing $APP_DIR — run build-app.sh first" >&2; exit 1; }

rm -f "$OUT"
# -X strips extended attrs that can make checksums flaky across machines
( cd dist && zip -r -X "$(basename "$OUT")" WinMice.app )

echo "Wrote $OUT"
