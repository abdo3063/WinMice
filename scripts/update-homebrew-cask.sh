#!/bin/sh
set -eu

CASK_PATH="${1:?usage: update-homebrew-cask.sh <cask.rb> <version> <sha256>}"
VERSION="${2:?}"
SHA256="${3:?}"

[ -f "$CASK_PATH" ] || { echo "Missing cask: $CASK_PATH" >&2; exit 1; }

# Portable in-place edit for macOS / GNU sed
tmp="$(mktemp)"
sed -E \
  -e "s/^(  version )\"[^\"]*\"/\\1\"${VERSION}\"/" \
  -e "s/^(  sha256 )\"[^\"]*\"/\\1\"${SHA256}\"/" \
  -e "s|(WinMice-#\\{version\\}\\.)zip|\\1dmg|g" \
  -e "s|(WinMice-#\\{version\\}\\.)ZIP|\\1dmg|g" \
  "$CASK_PATH" > "$tmp"
mv "$tmp" "$CASK_PATH"

grep -q "version \"${VERSION}\"" "$CASK_PATH"
grep -q "sha256 \"${SHA256}\"" "$CASK_PATH"
grep -E 'url ".*WinMice-#\{version\}\.dmg"' "$CASK_PATH"
echo "Updated $CASK_PATH → version ${VERSION}"
