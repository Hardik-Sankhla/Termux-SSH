# Termux-SSH — small repo to automate SSH between laptop and Termux

This repository contains two simple scripts you can clone to both devices and use to quickly set up and connect:

- **Termux (mobile)**: `termux-setup.sh` — installs `openssh`, ensures `~/.ssh/authorized_keys` exists with secure permissions, starts `sshd`, and prints connection info. Do NOT generate client private keys on the mobile device; instead copy your laptop public key into `authorized_keys`.
- **Laptop**: `connect-termux.sh` — attempts to connect using mDNS (`hostname.local`) or scans the local subnet for port `8022` (requires `nmap`).

Quick setup

1. Clone this repo on both devices:

```bash
git clone https://github.com/Hardik-Sankhla/Termux-SSH.git
cd Termux-SSH
```

2. On your Termux device (mobile):

```bash
chmod +x termux-setup.sh
./termux-setup.sh
# Termux is ready to accept public keys. On your laptop generate a keypair if you don't have one:
#   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
# Then copy the laptop public key to Termux (replace <termux-user> and <ip>):
#   scp -P 8022 ~/.ssh/id_ed25519.pub <termux-user>@<ip>:/tmp/termux_key.pub
#   ssh -p 8022 <termux-user>@<ip> 'mkdir -p ~/.ssh && cat /tmp/termux_key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm /tmp/termux_key.pub'
```

3. On your laptop:

```bash
mkdir -p ~/.ssh
# If you prefer, manually save the laptop public key as ~/.ssh/termux_key.pub and move it to ~/.ssh/termux_key
mv ~/.ssh/termux_key.pub ~/.ssh/termux_key || true
chmod 600 ~/.ssh/termux_key || true
chmod +x connect-termux.sh
# connect (replace <termux-user> and <ip/hostname> if needed). To use your ssh-agent instead of a separate key, pass '-' as the key-file:
./connect-termux.sh <termux-user> ~/.ssh/termux_key 8022 hardik-phone.local
# or using ssh-agent (when your key is loaded in the agent):
./connect-termux.sh <termux-user> - 8022 hardik-phone.local
```

Pushing changes to this GitHub repo

```bash
git add .
git commit -m "Update README and add install/update scripts"
git push
```

Notes

- Termux's sshd usually listens on port `8022` by default.
- `connect-termux.sh` uses `nmap` to scan the subnet; install it if you want auto-discovery (`sudo apt install nmap` on many Linux distros).
- Keep your private keys secure. Only copy the public key (`id_ed25519.pub`) to the laptop.

If you'd like, I can:
- Add a helper to automatically fetch the Termux public key over `adb` or via QR code.
- Add systemd unit or cron entries on the laptop for one-click reconnect.
