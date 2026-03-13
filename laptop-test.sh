#!/usr/bin/env bash
set -euo pipefail

# Basic laptop-side tests before attempting to connect
LOG_DIR="${HOME}/.termux-ssh-logs"
mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"

# If KEY_FILE is '-' or empty, assume ssh-agent or default ssh keys will be used
KEY_FILE="${1:-$HOME/.ssh/termux_key}"

if [ "$KEY_FILE" != "-" ] && [ ! -f "$KEY_FILE" ]; then
  echo "Missing key file: $KEY_FILE" | tee -a "$LOG_DIR/error.log"
  exit 2
fi

if [ "$KEY_FILE" != "-" ]; then
  # Ensure private key permissions are strict
  perms=$(stat -c %a "$KEY_FILE" 2>/dev/null || true)
  if [ -n "$perms" ] && [ "$perms" -gt 600 ]; then
    echo "Warning: key file permissions are too open ($perms). Setting to 600." | tee -a "$LOG_DIR/error.log"
    chmod 600 "$KEY_FILE" || true
  fi
fi

if ! command -v ssh >/dev/null 2>&1; then
  echo "ssh client missing" | tee -a "$LOG_DIR/error.log"
  exit 2
fi

echo "OK: laptop tests passed"
exit 0
