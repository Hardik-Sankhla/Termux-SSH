#!/usr/bin/env bash
set -euo pipefail

# Install the watcher into Termux:Boot (~/.termux/boot/) so it runs on device boot.
# Requires Termux:Boot app installed on the Android device.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BOOT_DIR="$HOME/.termux/boot"

mkdir -p "$BOOT_DIR"
cp -a "$REPO_DIR/termux-watcher.sh" "$BOOT_DIR/"
chmod +x "$BOOT_DIR/termux-watcher.sh"

echo "Installed termux-watcher.sh to $BOOT_DIR"
echo "Ensure you have Termux:Boot installed from F-Droid or Play Store. The watcher will start automatically on device boot."

exit 0
