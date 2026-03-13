# Termux-SSH — small repo to automate SSH between laptop and Termux

This repository contains two simple scripts you can clone to both devices and use to quickly set up and connect:

- **Termux (mobile)**: `termux-setup.sh` — installs `openssh`, ensures `~/.ssh/authorized_keys` exists with secure permissions, starts `sshd`, and prints connection info. Do NOT generate client private keys on the mobile device; instead copy your laptop public key into `authorized_keys`.
- **Laptop**: `connect-termux.sh` — attempts to connect using mDNS (`hostname.local`) or scans the local subnet for port `8022` (requires `nmap`).

Project purpose

This project is intentionally one-way: it provides a secure, repeatable workflow for a laptop (client) to connect to a Termux instance on an Android device (server). The repo assumes you want to control and run code on the mobile device from your laptop. It is not for creating a two-way, peer-to-peer remote shell; the laptop initiates all connections to Termux.

Use case: you have a laptop and one or more Android phones/tablets running Termux. You want to connect from the laptop to Termux to edit, run, test or manage code on the phone.

Security model: generate and keep private keys on the laptop (client). Copy only public keys to Termux's `~/.ssh/authorized_keys`.

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

**Secure setup & testing**

Below are explicit commands and best practices to securely set up, test and operate the connection between your laptop and Termux device.

**1) Generate a laptop SSH keypair (recommended)**
Create a dedicated key for Termux access on your laptop (keeps separation from other keys):

```bash
ssh-keygen -t ed25519 -f ~/.ssh/termux_client_id -N "" -C "termux-client@$(hostname)"
chmod 600 ~/.ssh/termux_client_id
```

**2) Prepare Termux (mobile)**
From the repo clone on Termux:

```bash
cd ~/Termux-SSH
chmod +x termux-setup.sh termux-watcher.sh termux-test.sh report-error.sh
./termux-setup.sh
# optionally enable watcher
./termux-setup.sh --enable-watcher
# or start watcher manually:
nohup ./termux-watcher.sh >/dev/null 2>&1 &
```

**3) Copy laptop public key to Termux (choose one)**

- Using secure copy (network):

```bash
scp -P 8022 ~/.ssh/termux_client_id.pub <termux-user>@<termux-ip>:/tmp/termux_key.pub
ssh -p 8022 <termux-user>@<termux-ip> 'mkdir -p ~/.ssh && cat /tmp/termux_key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm /tmp/termux_key.pub'
```

- Using `ssh-copy-id` (if available):

```bash
ssh-copy-id -i ~/.ssh/termux_client_id.pub -p 8022 <termux-user>@<termux-ip>
```

- Manual paste (offline or via clipboard):

```bash
cat ~/.ssh/termux_client_id.pub
# paste into Termux shell:
mkdir -p ~/.ssh
echo 'PASTED_PUBLIC_KEY' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

**4) Connect from laptop (examples)**

Direct SSH with key file:

```bash
ssh -i ~/.ssh/termux_client_id -p 8022 <termux-user>@<termux-ip-or-hostname>
```

Using the helper `connect-termux.sh` (key file):

```bash
./connect-termux.sh <termux-user> ~/.ssh/termux_client_id 8022 hardik-phone.local
```

Using `ssh-agent` (safer: private key stays in agent memory):

```bash
ssh-add ~/.ssh/termux_client_id
./connect-termux.sh <termux-user> - 8022 hardik-phone.local
```

**5) Run tests & collect diagnostics**

Termux health check and diagnostics (run on mobile):

```bash
cd ~/Termux-SSH
chmod +x termux-test.sh report-error.sh
./termux-test.sh
ls -la ~/termux-ssh-logs
```

Laptop pre-checks:

```bash
./laptop-test.sh ~/.ssh/termux_client_id
# or using agent
./laptop-test.sh -
```

If tests fail, `report-error.sh` saves diagnostics to `termux-ssh-logs` (on Termux) or `~/.termux-ssh-logs` (on laptop). Check those files for `ps`, network status and disk usage snapshots.

**6) Install & update helpers**

Use the included helpers:

```bash
./install.sh termux --enable-watcher   # run on device
./install.sh laptop ~/.ssh/termux_client_id.pub  # run on laptop to install public key file
./update-repo.sh                        # pulls repo and restarts watcher on Termux
```

**7) CI and local safety checks**

This repo includes a GitHub Action that scans commits/PRs for private-key patterns and fails the run if found (`.github/workflows/no-private-keys.yml`). There's also `ci/check-no-keys.sh` which you can run locally before committing.

To add a local pre-commit hook (optional):

```bash
cat > .git/hooks/pre-commit <<'HOOK'
#!/usr/bin/env bash
./ci/check-no-keys.sh || exit 1
HOOK
chmod +x .git/hooks/pre-commit
```

**8) Security best practices (summary)**

- Generate SSH keys on your laptop (client) and never commit private keys to the repo.
- Use `ssh-agent` where possible; it avoids storing the private key on disk for long periods.
- Keep `~/.ssh/authorized_keys` on Termux with `chmod 600` and `~/.ssh` with `chmod 700`.
- Keep the repo's log directories out of version control (`.gitignore` already configured).

If you'd like, I can add an example pre-commit hook into the repo, or create a `CONTRIBUTING.md` describing this workflow in more detail.

**Quickstart wrapper & diagram**

This repo now includes a `quickstart.sh` helper that runs minimal, non-destructive steps on the machine where it is executed. It auto-detects Termux vs laptop (or you can pass `termux` or `laptop`).

Examples:

```bash
# Auto-detect (runs termux or laptop minimal flow)v
./quickstart.sh auto

# Run Termux-side minimal setup (on the phone)
./quickstart.sh termux

# Run laptop-side minimal setup (generate key with --generate-key and optionally copy)
./quickstart.sh laptop --generate-key --copy-to user@192.168.1.12
```

A simple architecture diagram is available in `DIAGRAM.mmd` (Mermaid). You can preview it in supported viewers or on GitHub.

**Guided setup & test (one-way laptop → Termux)**

Follow these steps exactly to provision a secure, one-way connection where your laptop (client) connects to Termux (server). Run the laptop commands on your laptop, Termux commands on the Android device.

1) Generate a dedicated laptop key (if you haven't already):

```bash
ssh-keygen -t ed25519 -f ~/.ssh/termux_client_id -N "" -C "termux-client@$(hostname)"
chmod 600 ~/.ssh/termux_client_id
```

2) Prepare Termux (install openssh and start sshd):

```bash
# on Termux
cd ~/Termux-SSH
chmod +x termux-setup.sh
./termux-setup.sh
# optionally enable background watcher
./termux-setup.sh --enable-watcher
```

3) Copy your laptop public key to the phone (choose one):

- Network copy (recommended):

```bash
# from laptop (replace <user> and <ip>)
scp -P 8022 ~/.ssh/termux_client_id.pub <termux-user>@<termux-ip>:/tmp/termux_key.pub
ssh -p 8022 <termux-user>@<termux-ip> 'mkdir -p ~/.ssh && cat /tmp/termux_key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm /tmp/termux_key.pub'
```

- Or manual paste on Termux (if no network):

```bash
# on laptop
cat ~/.ssh/termux_client_id.pub
# on Termux (paste contents)
mkdir -p ~/.ssh
echo 'PASTED_PUBLIC_KEY' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

4) Verify connection from laptop (quick test):

```bash
# direct
ssh -i ~/.ssh/termux_client_id -p 8022 <termux-user>@<termux-ip>

# or using helper
./connect-termux.sh <termux-user> ~/.ssh/termux_client_id 8022 <termux-ip-or-hostname>
```

5) Run sanity checks and collect diagnostics if something fails:

```bash
# on Termux:
./termux-test.sh || ./report-error.sh "termux-test failed"
ls -la ~/termux-ssh-logs

# on laptop:
./laptop-test.sh ~/.ssh/termux_client_id || ./laptop-report.sh "laptop precheck failed"
```

6) Optional: enable autostart

- On Termux (Termux:Boot app required):

```bash
./install.sh termux --enable-autostart
```

- On laptop (systemd):

```bash
sudo ./install-systemd.sh
```

7) Revoke or rotate keys

- Revoke access: remove the matching public key line from `~/.ssh/authorized_keys` on Termux.
- Rotate: generate a new client key on laptop, upload new public key to Termux, then remove the old public key.

Assistant's guided setup (what I will do with you):

- Verify your local environment (I can run `./laptop-test.sh` here to check SSH client and key presence).
- Help generate a client key on the laptop (if you want me to run that locally here).
- Provide the exact `scp`/`ssh` commands you should run to copy the public key to Termux safely.
- Help enable autostart and verify the watcher service/logs.
- Assist with rotating or revoking keys and debugging connection failures.

When you're ready, tell me which device you're on (laptop or Termux) and which step you want to run first; I can run laptop-side commands here and guide you through the Termux-side steps interactively.
