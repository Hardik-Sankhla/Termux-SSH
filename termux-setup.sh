#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Termux SSH setup — installing and configuring openssh..."

if ! command -v sshd >/dev/null 2>&1; then
  echo "Installing openssh (requires termux package manager)..."
  pkg update -y || true
  pkg install -y openssh
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  echo "Generating ed25519 keypair..."
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "termux@$(hostname)"
else
  echo "SSH key already exists: $HOME/.ssh/id_ed25519"
fi

touch "$HOME/.ssh/authorized_keys"
cat "$HOME/.ssh/id_ed25519.pub" >> "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"


echo "Starting sshd (Termux default port: 8022)..."
sshd

termux-wake-lock >/dev/null 2>&1 || true

if [ "${1:-}" = "--enable-watcher" ]; then
  echo "Enabling termux-watcher in background..."
  if [ -f "$PWD/termux-watcher.sh" ]; then
    nohup "$PWD/termux-watcher.sh" >/dev/null 2>&1 &
    echo "Watcher started (nohup). To run on boot, install Termux:Boot and add this script to ~/.termux/boot/" 
  else
    echo "Watcher script not found in current directory. Ensure termux-watcher.sh is present in the repo clone." 
  fi
fi

IP=$(ip -o -4 addr show | awk '/scope global/ {print $4}' | head -n1 | cut -d/ -f1 || true)

echo
echo "✅ Done. Connection info:" 
echo "- User: $(whoami)"
echo "- Port: 8022"
echo "- Local IP: ${IP:-(unknown)}"
echo "- Public key path: $HOME/.ssh/id_ed25519.pub"
echo
echo "To connect from your laptop:" 
echo "  1) Copy the public key: cat $HOME/.ssh/id_ed25519.pub"
echo "  2) On laptop save it as ~/.ssh/termux_key.pub and then run:"
echo "     ssh -p 8022 <termux-user>@<ip> -i ~/.ssh/termux_key"

exit 0
