#!/usr/bin/env bash
set -euo pipefail

# Basic laptop-side tests before attempting to connect
LOG_DIR="${HOME}/.termux-ssh-logs"
mkdir -p "$LOG_DIR"

KEY_FILE="${1:-$HOME/.ssh/termux_key}"

if [ ! -f "$KEY_FILE" ]; then
  echo "Missing key file: $KEY_FILE" | tee -a "$LOG_DIR/error.log"
  exit 2
fi

if ! command -v ssh >/dev/null 2>&1; then
  echo "ssh client missing" | tee -a "$LOG_DIR/error.log"
  exit 2
fi

echo "OK: laptop tests passed"
exit 0
