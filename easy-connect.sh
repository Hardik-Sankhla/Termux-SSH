#!/usr/bin/env bash
set -euo pipefail

# easy-connect.sh
# Laptop-side helper to copy a public key to a Termux device and verify SSH access.
# Usage:
#   ./easy-connect.sh user@host [port] [keyfile]
#   ./easy-connect.sh host [port] [keyfile]  # you'll be prompted for user

TARGET="${1:-}"
PORT="${2:-8022}"
KEY_FILE="${3:-$HOME/.ssh/termux_client_id}"

usage(){
  echo "Usage: $0 [user@]host [port] [keyfile]"
  exit 2
}

if [ -z "$TARGET" ]; then
  usage
fi

# parse optional user@host
if [[ "$TARGET" == *"@"* ]]; then
  USER_HOST="$TARGET"
else
  read -rp "Termux username (for example u0_a352) or press Enter to try current username [$USER]: " UIN
  if [ -z "$UIN" ]; then
    UIN="$USER"
  fi
  USER_HOST="$UIN@$TARGET"
fi

if [ ! -f "$KEY_FILE" ]; then
  echo "Keyfile not found: $KEY_FILE"
  read -rp "Generate a new ed25519 key at $KEY_FILE? (yes/no) " yn
  if [[ "$yn" =~ ^(y|Y) ]]; then
    mkdir -p "$(dirname "$KEY_FILE")"
    ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "termux-client@$(hostname)"
    chmod 600 "$KEY_FILE"
  else
    echo "Create a key and re-run. Aborting."; exit 1
  fi
fi

PUB="$KEY_FILE.pub"
if [ ! -f "$PUB" ]; then
  echo "Public key not found; generating from private key..."
  ssh-keygen -y -f "$KEY_FILE" > "$PUB"
fi

echo "Copying public key to $USER_HOST (port $PORT)..."
set +e
scp -P "$PORT" "$PUB" "$USER_HOST:/tmp/termux_key.pub"
SCP_EXIT=$?
set -e

if [ $SCP_EXIT -ne 0 ]; then
  echo "Automatic copy failed. Possible causes: wrong username, device unreachable, or sshd not running."
  echo "You can still copy the key manually. Here is the public key (start):"; echo; cat "$PUB"; echo
  echo "On the Termux device paste it into ~/.ssh/authorized_keys and set permissions:"
  echo "  mkdir -p ~/.ssh && echo 'PASTE_HERE' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
  exit 1
fi

echo "Installing public key on remote host..."
ssh -p "$PORT" "$USER_HOST" "mkdir -p ~/.ssh && cat /tmp/termux_key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm /tmp/termux_key.pub"

echo "Verifying SSH login (using key)..."
set +e
ssh -i "$KEY_FILE" -p "$PORT" -o BatchMode=yes -o ConnectTimeout=10 "$USER_HOST" 'echo OK' >/dev/null 2>&1
RC=$?
set -e

if [ $RC -eq 0 ]; then
  echo "Success: SSH key installed and login verified. You can now run:"
  echo "  ssh -i $KEY_FILE -p $PORT $USER_HOST"
  exit 0
else
  echo "Warning: SSH login test failed. Possible issues: key not accepted, wrong username, or sshd config requires different options.";
  echo "Try: ssh -v -i $KEY_FILE -p $PORT $USER_HOST to get debug output.";
  exit 2
fi
