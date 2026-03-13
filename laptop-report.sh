#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${HOME}/.termux-ssh-logs"
mkdir -p "$LOG_DIR"

MSG="${1:-No message provided}"
TS=$(date -Iseconds)

echo "[$TS] $MSG" >> "$LOG_DIR/error.log"
echo "Saved laptop error: $MSG"

exit 0
