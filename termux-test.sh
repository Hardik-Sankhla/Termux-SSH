#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${HOME}/termux-ssh-logs"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")

fail() {
  echo "[$(date -Iseconds)] ERROR: $*" | tee -a "$LOG_DIR/error.log"
  "$PWD/report-error.sh" "Termux test failed: $*" || true
  exit 1
}

echo "Running Termux health checks..."

# Check sshd is running
if ! pgrep -f sshd >/dev/null 2>&1; then
  fail "sshd not running"
fi

# Check port 8022 is listening
if ! ss -ltn | awk '{print $4}' | grep -q ":8022$" >/dev/null 2>&1; then
  fail "Port 8022 not listening"
fi

# Check disk space (ensure at least 50MB free on /data or /)
AVAIL=$(df --output=avail /data 2>/dev/null | tail -n1 || df --output=avail / | tail -n1)
if [ -n "$AVAIL" ] && [ "$AVAIL" -lt 51200 ]; then
  fail "Low disk space: ${AVAIL}K available"
fi

echo "OK: Termux health checks passed"
exit 0
