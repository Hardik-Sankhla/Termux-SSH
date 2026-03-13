#!/bin/bash
# Autonomous Termux Discovery & Connection Script
# Designed for: Hardik Sankhla (Dell Precision 7750)

USER="u0_a352"
PORT="8022"
KEY_FILE="$HOME/.ssh/termux_key"
TARGET_HOSTNAME="hardik-phone.local"

echo "🚀 Starting Autonomous Discovery..."

# Method 1: Try mDNS (The fastest way)
if ping -c 1 -W 1 "$TARGET_HOSTNAME" > /dev/null 2>&1; then
    echo "✅ Found device via mDNS: $TARGET_HOSTNAME"
    ssh -i "$KEY_FILE" -p "$PORT" "$USER@$TARGET_HOSTNAME"
    exit 0
fi

# Method 2: Network Scan (The "Hunter" way)
echo "🔍 mDNS failed. Scanning local network for open Termux port ($PORT)..."
# Scans your current subnet automatically
CURRENT_SUBNET=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -n 1)
FOUND_IP=$(nmap -p $PORT --open -n $CURRENT_SUBNET -oG - | awk '/Up$/{print $2}')

if [ ! -z "$FOUND_IP" ]; then
    echo "✅ Found Termux at IP: $FOUND_IP"
    ssh -i "$KEY_FILE" -p "$PORT" "$USER@$FOUND_IP"
else
    echo "❌ Device not found. Please ensure Termux is open and 'sshd' is running."
fi