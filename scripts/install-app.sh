#!/bin/sh
set -eu

# Builds the bundle and replaces the copy in /Applications with it, then relaunches.

DEST="/Applications/WinMice.app"

sh "$(dirname "$0")/build-app.sh"

if pgrep -x WinMice >/dev/null 2>&1; then
    osascript -e 'quit app "WinMice"' >/dev/null 2>&1 || pkill -x WinMice || true
    # Give the app a moment to tear down its event tap before the bundle disappears.
    sleep 1
fi

# Replace in place with ditto so the path stays stable. Ad-hoc re-signing still changes the
# code directory hash, so Privacy grants may need to be toggled again after an update.
mkdir -p "$(dirname "$DEST")"
ditto dist/WinMice.app "$DEST"

# The Dock caches an app's icon by bundle path, so a new icon keeps showing the old one until
# LaunchServices re-reads the bundle.
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
"$LSREGISTER" -f "$DEST"
killall Dock >/dev/null 2>&1 || true

open "$DEST"

echo "Installed $DEST"
echo "If scrolling still does nothing: System Settings → Privacy & Security → Accessibility →"
echo "remove every WinMice row, enable $DEST, then quit and reopen WinMice."
