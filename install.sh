#!/usr/bin/env bash
set -euo pipefail

# Simple installer for both Termux (mobile) and laptop
# Usage:
#  ./install.sh termux [--enable-watcher]
#  ./install.sh laptop [path/to/termux_key.pub]
# If no arg provided the script will attempt to auto-detect Termux.

MODE="${1:-auto}"
ARG2="${2:-}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

is_termux() {
  command -v termux-info >/dev/null 2>&1
}

if [ "$MODE" = "auto" ]; then
  if is_termux; then
    MODE=termux
  else
    MODE=laptop
  fi
fi

if [ "$MODE" = "termux" ]; then
  echo "Installing on Termux..."
  chmod +x "$REPO_DIR"/*.sh || true
  "$REPO_DIR/termux-setup.sh"
  if [ "${2:-}" = "--enable-watcher" ] || [ "${ARG2}" = "--enable-watcher" ]; then
    nohup "$REPO_DIR/termux-watcher.sh" >/dev/null 2>&1 &
    echo "Watcher started (nohup)"
  fi
  echo "Done. Run: cat ~/.ssh/id_ed25519.pub and copy the output to your laptop as ~/.ssh/termux_key.pub"
  exit 0
fi

if [ "$MODE" = "laptop" ]; then
  echo "Installing on laptop..."
  chmod +x "$REPO_DIR"/*.sh || true

  # If a pubkey path is provided, install it as termux_key
  if [ -n "$ARG2" ]; then
    PUB="$ARG2"
    if [ -f "$PUB" ]; then
      mkdir -p "$HOME/.ssh"
      cp "$PUB" "$HOME/.ssh/termux_key.pub"
      mv "$HOME/.ssh/termux_key.pub" "$HOME/.ssh/termux_key"
      chmod 600 "$HOME/.ssh/termux_key"
      echo "Installed Termux public key to ~/.ssh/termux_key"
    else
      echo "Provided pubkey path not found: $PUB"
    fi
  else
    echo "No pubkey provided. Copy Termux public key to ~/.ssh/termux_key and then run connect-termux.sh"
  fi

  echo "Done. Use ./connect-termux.sh <termux-user> ~/.ssh/termux_key 8022 <hostname> to connect."
  exit 0
fi

echo "Unknown mode: $MODE. Use 'termux' or 'laptop' or no args for auto-detect."
exit 2
