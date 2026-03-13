#!/usr/bin/env bash
set -euo pipefail

# Simple error reporter/logger for both Termux and laptop
LOG_DIR="${HOME}/termux-ssh-logs"
mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"

MSG="${1:-Error occurred (no message)}"
TS=$(date -Iseconds)
BASE="$LOG_DIR/$(date -u +"%Y%m%dT%H%M%SZ")"

echo "[$TS] $MSG" >> "$LOG_DIR/error.log"

# Save diagnostics
ps aux > "$BASE.ps.txt" 2>&1 || true
# 'ss' may not be available on all devices; capture net info conservatively
if command -v ss >/dev/null 2>&1; then
	ss -tuln > "$BASE.net.txt" 2>&1 || true
elif command -v netstat >/dev/null 2>&1; then
	netstat -tuln > "$BASE.net.txt" 2>&1 || true
fi
ip addr show > "$BASE.ip.txt" 2>&1 || true
df -h > "$BASE.df.txt" 2>&1 || true

echo "Saved diagnostics to: $BASE.*"

exit 0
