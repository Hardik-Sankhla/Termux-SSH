#!/usr/bin/env bash
set -euo pipefail

# Quickstart helper for one-way laptop -> Termux setup
# Usage:
#  ./quickstart.sh auto            # auto-detect and run minimal steps
#  ./quickstart.sh termux          # run Termux-side minimal setup
#  ./quickstart.sh laptop [opts]   # run laptop-side minimal setup
# Options for laptop mode:
#   --generate-key    : generate an ed25519 key at ~/.ssh/termux_client_id if missing
#   --copy-to user@host : attempt to scp the public key to Termux (over port 8022)

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-auto}"

is_termux() { command -v termux-info >/dev/null 2>&1; }

if [ "$MODE" = "auto" ]; then
  if is_termux; then MODE=termux; else MODE=laptop; fi
fi

if [ "$MODE" = "termux" ]; then
  echo "[quickstart] Running Termux-side minimal setup..."
  chmod +x "$REPO_DIR/termux-setup.sh" "$REPO_DIR/termux-test.sh" || true
  echo "-> Ensuring openssh and starting sshd"
  "$REPO_DIR/termux-setup.sh"
  echo "-> Running health checks"
  "$REPO_DIR/termux-test.sh" || echo "termux-test failed; check logs in ~/termux-ssh-logs"
  echo "Termux quickstart finished. Copy your laptop public key to Termux's ~/.ssh/authorized_keys to allow connections."
  exit 0
fi

if [ "$MODE" = "laptop" ]; then
  shift || true
  # parse simple options
  GENERATE_KEY=0
  COPY_TO=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --generate-key) GENERATE_KEY=1; shift;;
      --copy-to) COPY_TO="$2"; shift 2;;
      -h|--help) echo "Usage: $0 laptop [--generate-key] [--copy-to user@host]"; exit 0;;
      *) echo "Unknown option: $1"; exit 2;;
    esac
  done

  KEY_PATH="$HOME/.ssh/termux_client_id"
  PUB_PATH="$KEY_PATH.pub"

  if [ ! -f "$KEY_PATH" ]; then
    if [ "$GENERATE_KEY" -eq 1 ]; then
      echo "Generating ed25519 keypair at $KEY_PATH"
      mkdir -p "$HOME/.ssh" && ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "termux-client@$(hostname)"
      chmod 600 "$KEY_PATH"
    else
      echo "No key found at $KEY_PATH. To create one, re-run with --generate-key or create manually."
    fi
  else
    echo "Found existing key: $KEY_PATH"
  fi

  if [ -f "$PUB_PATH" ]; then
    echo "Public key available: $PUB_PATH"
    echo "You can copy it to Termux with scp or ssh-copy-id. Example:"
    echo "  scp -P 8022 $PUB_PATH <termux-user>@<termux-ip>:/tmp/termux_key.pub"
    echo "  ssh -p 8022 <termux-user>@<termux-ip> 'mkdir -p ~/.ssh && cat /tmp/termux_key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm /tmp/termux_key.pub'"
    if [ -n "$COPY_TO" ]; then
      echo "Attempting to copy public key to $COPY_TO"
      scp -P 8022 "$PUB_PATH" "$COPY_TO:/tmp/termux_key.pub" && \
        ssh -p 8022 "$COPY_TO" "mkdir -p ~/.ssh && cat /tmp/termux_key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm /tmp/termux_key.pub" || \
        echo "Failed to copy key automatically. Use the manual instructions above."
    fi
  else
    echo "Public key not found. Generate with --generate-key or create a public key at $PUB_PATH"
  fi

  echo "Running laptop pre-checks"
  chmod +x "$REPO_DIR/laptop-test.sh" || true
  "$REPO_DIR/laptop-test.sh" "${KEY_PATH}" || echo "laptop-test failed; address issues before connecting"

  echo "Laptop quickstart finished. Use ./connect-termux.sh <termux-user> ${KEY_PATH} 8022 <termux-ip> to connect, or use ssh-agent and pass '-' as the key-file."
  exit 0
fi

echo "Unknown mode: $MODE. Use 'termux', 'laptop', or 'auto'."
exit 2
