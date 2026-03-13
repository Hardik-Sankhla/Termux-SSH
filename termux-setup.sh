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

# Ensure helper/network tools are available so scripts can detect the IP and status
echo "Installing helper packages (iproute2, inetutils, termux-api) if missing..."
pkg install -y iproute2 inetutils termux-api >/dev/null 2>&1 || true

# SECURITY: Do NOT generate client private keys on the Termux device for
# the purpose of connecting from your laptop. Best practice is to generate
# an SSH keypair on the laptop (client) and copy the laptop's PUBLIC key
# into Termux's ~/.ssh/authorized_keys. This keeps the private key only
# on the client machine.

if [ ! -f "$HOME/.ssh/authorized_keys" ]; then
  touch "$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"
fi

echo "Starting sshd (Termux default port: 8022)..."
sshd || echo "sshd failed to start — check package installation"

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

# Determine local IP (use ip, fallback to ifconfig)
IP=""
if command -v ip >/dev/null 2>&1; then
  IP=$(ip -o -4 addr show | awk '/scope global/ {print $4}' | head -n1 | cut -d/ -f1 || true)
elif command -v ifconfig >/dev/null 2>&1; then
  IP=$(ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}' || true)
fi

echo
echo "✅ Done. Connection info:" 
echo "- User: $(whoami)"
echo "- Port: 8022"
echo "- Local IP: ${IP:-(unknown)}"
echo
echo "IMPORTANT: generate an SSH keypair on your LAPTOP (do NOT generate private keys on the phone)."
echo "Example (on laptop): ssh-keygen -t ed25519 -f ~/.ssh/termux_client_id -N \"\" -C \"termux-client@$(hostname)\""
echo
echo "Copy the laptop public key to this device (replace <termux-user> and <ip>):"
echo "  scp -P 8022 ~/.ssh/termux_client_id.pub <termux-user>@${IP}:/tmp/termux_key.pub"
echo "  ssh -p 8022 <termux-user>@${IP} 'mkdir -p ~/.ssh && cat /tmp/termux_key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm /tmp/termux_key.pub'"
echo
echo "Then connect from laptop: ssh -i ~/.ssh/termux_client_id -p 8022 <termux-user>@${IP}"

exit 0
