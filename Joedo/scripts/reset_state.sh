#!/bin/bash
# Nuke Joedo state so next launch is a true first-install experience.
# Sandboxed apps store prefs inside ~/Library/Containers/<bundle>/Data/…
# and cfprefsd caches them aggressively. We wipe both the file and the cache.
set -euo pipefail

BUNDLE_ID="allwyn.Joedo"
CONTAINER="$HOME/Library/Containers/$BUNDLE_ID"
DATA="$CONTAINER/Data"

echo "==> Killing any running Joedo…"
killall -9 Joedo 2>/dev/null || true

# Stop the prefs cache daemon BEFORE we delete files so it can't write
# cached values back on top of us.
echo "==> Stopping cfprefsd (will auto-respawn)…"
killall -u "$USER" cfprefsd 2>/dev/null || true
sleep 0.5

if [[ -d "$DATA" ]]; then
  echo "==> Clearing $DATA/ …"
  find "$DATA" -mindepth 1 -delete 2>/dev/null || true
fi

echo "==> Removing any user-domain prefs plists…"
rm -f "$HOME/Library/Preferences/$BUNDLE_ID.plist"

echo "==> Double-flush cfprefsd after delete…"
killall -u "$USER" cfprefsd 2>/dev/null || true
sleep 0.3

# Verify — read the container plist and fail loudly if the flag persists.
PLIST="$DATA/Library/Preferences/$BUNDLE_ID.plist"
if [[ -f "$PLIST" ]]; then
  echo "warning: plist was recreated at $PLIST" >&2
  /usr/libexec/PlistBuddy -c "Print" "$PLIST" 2>/dev/null || true
else
  echo "==> Plist confirmed gone."
fi

echo "==> Done. Next launch of Joedo is a cold start."
