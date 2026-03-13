#!/usr/bin/env bash
set -euo pipefail

# Background watcher for Termux: periodically runs tests and ensures sshd
# Usage: run with nohup or add to Termux:Boot

INTERVAL=${INTERVAL_SECONDS:-300}
LOG_DIR="${HOME}/termux-ssh-logs"
mkdir -p "$LOG_DIR"

echo "Termux watcher starting (interval ${INTERVAL}s)..."

while true; do
  if ! pgrep -f sshd >/dev/null 2>&1; then
    echo "[$(date -Iseconds)] sshd not running — attempting start" | tee -a "$LOG_DIR/watcher.log"
    sshd || true
    "$PWD/report-error.sh" "sshd restarted by watcher" || true
  fi

  # Run health checks
  if ! "$PWD/termux-test.sh" >/dev/null 2>&1; then
    echo "[$(date -Iseconds)] termux-test failed" | tee -a "$LOG_DIR/watcher.log"
  fi

  sleep "$INTERVAL"
done
