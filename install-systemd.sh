#!/usr/bin/env bash
set -euo pipefail

# Install a systemd service to run the repo's termux-watcher.sh on boot
# Usage: sudo ./install-systemd.sh

if [ "$EUID" -ne 0 ]; then
  echo "This script should be run with sudo to install a systemd unit. Try: sudo $0" >&2
  exit 1
fi

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_PATH="/etc/systemd/system/termux-watcher.service"
USER_NAME="${SUDO_USER:-$(whoami)}"

cat > "$SERVICE_PATH" <<SERVICE
[Unit]
Description=Termux Watcher (runs termux-watcher.sh from repo)
After=network-online.target
Wants=network-online.target

[Service]
User=$USER_NAME
WorkingDirectory=$REPO_DIR
ExecStart=/bin/bash $REPO_DIR/termux-watcher.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

chmod 644 "$SERVICE_PATH"
systemctl daemon-reload
systemctl enable --now termux-watcher.service || true
echo "Installed and started termux-watcher.service (user: $USER_NAME)."
echo "To inspect logs: sudo journalctl -u termux-watcher.service -f"

exit 0
