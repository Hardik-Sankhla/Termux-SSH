# Termux-SSH — small repo to automate SSH between laptop and Termux

This repository contains two simple scripts you can clone to both devices and use to quickly set up and connect:

- **Termux (mobile)**: `termux-setup.sh` — installs `openssh`, generates an ed25519 keypair, appends the public key to `authorized_keys`, starts `sshd`, and prints connection info.
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
# then run: cat ~/.ssh/id_ed25519.pub  # copy this to your laptop (or save to a file)
```

3. On your laptop:

```bash
mkdir -p ~/.ssh
# Save the Termux public key you copied into ~/.ssh/termux_key.pub, then run:
mv ~/.ssh/termux_key.pub ~/.ssh/termux_key
chmod 600 ~/.ssh/termux_key
chmod +x connect-termux.sh
# connect (replace <termux-user> and <ip/hostname> if needed):
./connect-termux.sh <termux-user> ~/.ssh/termux_key 8022 hardik-phone.local
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
