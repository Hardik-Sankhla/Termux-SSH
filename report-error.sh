#!/usr/bin/env bash
set -euo pipefail

# Simple error reporter/logger for both Termux and laptop
LOG_DIR="${HOME}/termux-ssh-logs"
mkdir -p "$LOG_DIR"

MSG="${1:-Error occurred (no message)}"
TS=$(date -Iseconds)
BASE="$LOG_DIR/$(date -u +"%Y%m%dT%H%M%SZ")"

echo "[$TS] $MSG" >> "$LOG_DIR/error.log"

# Save diagnostics
ps aux > "$BASE.ps.txt" 2>&1 || true
ss -tulpen > "$BASE.net.txt" 2>&1 || true
ip addr show > "$BASE.ip.txt" 2>&1 || true
df -h > "$BASE.df.txt" 2>&1 || true

echo "Saved diagnostics to: $BASE.*"

exit 0
