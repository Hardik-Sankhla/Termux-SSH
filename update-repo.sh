#!/usr/bin/env bash
set -euo pipefail

# Pull latest repo and restart Termux watcher if present (safe to run on laptop or Termux)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

echo "Updating repository in $REPO_DIR"
if [ -d .git ]; then
  git pull --ff-only || echo "git pull failed or no changes"
else
  echo "Not a git repo (no .git). Skipping git pull."
fi

is_termux() {
  command -v termux-info >/dev/null 2>&1
}

if is_termux; then
  echo "Detected Termux environment. Restarting watcher if present."
  if [ -f "$REPO_DIR/termux-watcher.sh" ]; then
    pkill -f termux-watcher.sh >/dev/null 2>&1 || true
    nohup "$REPO_DIR/termux-watcher.sh" >/dev/null 2>&1 &
    echo "Watcher restarted"
  else
    echo "termux-watcher.sh not found; nothing to restart"
  fi
else
  echo "Not Termux. If you want the watcher on laptop, start it manually from the repo."
fi

echo "Update complete."
exit 0
