#!/usr/bin/env bash
set -euo pipefail

# Simple laptop-side connector for Termux devices
# Usage: connect-termux.sh <termux-user> [key-file] [port] [hostname]

USER="${1:-}"
KEY_FILE="${2:-$HOME/.ssh/termux_key}"
PORT="${3:-8022}"
TARGET_HOSTNAME="${4:-hardik-phone.local}"

# run laptop-side tests first
if ! "$PWD/laptop-test.sh" "$KEY_FILE" >/dev/null 2>&1; then
  echo "Pre-checks failed — logging and aborting"
  "$PWD/laptop-report.sh" "Pre-checks failed on laptop (missing key or ssh)" || true
  exit 2
fi

if [ -z "$USER" ]; then
  echo "Usage: $0 <termux-user> [key-file] [port] [hostname]"
  echo "Example: $0 u0_a352 ~/.ssh/termux_key 8022 hardik-phone.local"
  exit 2
fi

echo "🔎 Trying mDNS: $TARGET_HOSTNAME"
if ping -c 1 -W 1 "$TARGET_HOSTNAME" > /dev/null 2>&1; then
  echo "Found via mDNS — connecting to $TARGET_HOSTNAME"
  if [ "$KEY_FILE" = "-" ]; then
    ssh -p "$PORT" "$USER@$TARGET_HOSTNAME"
  else
    ssh -i "$KEY_FILE" -p "$PORT" "$USER@$TARGET_HOSTNAME"
  fi
  exit 0
fi

if command -v nmap >/dev/null 2>&1; then
  echo "mDNS failed. Scanning local subnet for open port $PORT (requires nmap)..."
  CURRENT_SUBNET=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -n 1)
  FOUND_IP=$(nmap -p "$PORT" --open -n "$CURRENT_SUBNET" -oG - | awk '/open/ {print $2; exit}')

    if [ -n "$FOUND_IP" ]; then
        echo "Found Termux at IP: $FOUND_IP — connecting..."
        if [ "$KEY_FILE" = "-" ]; then
          ssh -p "$PORT" "$USER@$FOUND_IP"
        else
          ssh -i "$KEY_FILE" -p "$PORT" "$USER@$FOUND_IP"
        fi
        exit 0
      fi
else
  echo "nmap not installed. Install nmap or run: ssh -p $PORT $USER@<ip> -i $KEY_FILE"
fi

echo "❌ Device not found. Ensure Termux is running and sshd started (on port $PORT)."
exit 1
