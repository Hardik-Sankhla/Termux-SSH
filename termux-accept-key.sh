#!/usr/bin/env bash
set -euo pipefail

# termux-accept-key.sh
# Termux-side helper: read a public key from stdin and append to ~/.ssh/authorized_keys
# Usage: cat mykey.pub | ./termux-accept-key.sh

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

TMP="/tmp/termux_key_from_stdin.pub"
cat - > "$TMP"
if [ ! -s "$TMP" ]; then
  echo "No input received. Pipe a public key into this script." >&2
  exit 2
fi

grep -q -F "$(cat "$TMP")" "$HOME/.ssh/authorized_keys" 2>/dev/null && echo "Key already present" && rm -f "$TMP" && exit 0 || true

cat "$TMP" >> "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"
rm -f "$TMP"
echo "Appended public key to ~/.ssh/authorized_keys"
