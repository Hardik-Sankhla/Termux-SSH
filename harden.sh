#!/usr/bin/env bash
set -euo pipefail

# Harden SSH and repository permissions where possible.
# Usage:
#   ./harden.sh termux [--user username] [--port 8022]
#   ./harden.sh laptop [--user username]
#   ./harden.sh all --user username

MODE="${1:-auto}"
shift || true
TARGET_USER="${TARGET_USER:-}"
TARGET_PORT="${TARGET_PORT:-}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --user) TARGET_USER="$2"; shift 2;;
    --port) TARGET_PORT="$2"; shift 2;;
    -h|--help) echo "Usage: $0 [termux|laptop|all] [--user username] [--port port]"; exit 0;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

is_termux() { command -v termux-info >/dev/null 2>&1 || false; }

if [ "$MODE" = "auto" ]; then
  if is_termux; then MODE=termux; else MODE=laptop; fi
fi

echo "[harden] Mode: $MODE"

ensure_ssh_dir() {
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
}

fix_private_keys() {
  for f in "$HOME/.ssh"/*; do
    [ -f "$f" ] || continue
    # heuristics: treat files without .pub as private keys
    case "${f}" in
      *.pub) continue;;
      *id_*.pub) continue;;
    esac
    chmod 600 "$f" || true
  done
}

backup_file() {
  src="$1"
  if [ -f "$src" ]; then
    cp -a "$src" "$src.harden.bak.$(date -u +%Y%m%dT%H%M%SZ)" || true
    echo "Backed up $src"
  fi
}

apply_sshd_hardening() {
  # Try common sshd_config locations
  candidates=("/etc/ssh/sshd_config" "$PREFIX/etc/ssh/sshd_config" "/data/data/com.termux/files/usr/etc/ssh/sshd_config")
  for cfg in "${candidates[@]}"; do
    if [ -f "$cfg" ]; then
      echo "Found sshd_config: $cfg"
      backup_file "$cfg"
      # Use sed to enforce secure options; keep a simple, safe set
      sed -i.bak -E \
        -e 's/^#?\s*PasswordAuthentication\s+.*/PasswordAuthentication no/' \
        -e 's/^#?\s*PermitRootLogin\s+.*/PermitRootLogin no/' \
        -e 's/^#?\s*ChallengeResponseAuthentication\s+.*/ChallengeResponseAuthentication no/' \
        -e 's/^#?\s*UsePAM\s+.*/UsePAM no/' \
        -e 's/^#?\s*PermitEmptyPasswords\s+.*/PermitEmptyPasswords no/' "$cfg" || true

      if [ -n "$TARGET_PORT" ]; then
        if grep -q -E '^\s*Port\s+' "$cfg"; then
          sed -i -E "s/^\s*Port\s+.*/Port $TARGET_PORT/" "$cfg" || true
        else
          echo "Port $TARGET_PORT" >> "$cfg"
        fi
      fi

      if [ -n "$TARGET_USER" ]; then
        # add AllowUsers if not present
        if grep -q -E '^\s*AllowUsers\s+' "$cfg"; then
          sed -i -E "s/^\s*AllowUsers\s+.*/AllowUsers $TARGET_USER/" "$cfg" || true
        else
          echo "AllowUsers $TARGET_USER" >> "$cfg"
        fi
      fi

      echo "Applied hardening edits to $cfg (a backup was created)."

      # Try to restart sshd safely
      if command -v systemctl >/dev/null 2>&1; then
        echo "Restarting sshd via systemctl"
        sudo systemctl restart sshd || sudo systemctl restart ssh || true
      else
        echo "Restarting sshd via process signal"
        pkill -f sshd >/dev/null 2>&1 || true
        sleep 1
        if command -v sshd >/dev/null 2>&1; then
          sshd || true
        fi
      fi
      return 0
    fi
  done
  echo "No sshd_config found in common locations; manual hardening may be required."
}

if [ "$MODE" = "termux" ] || [ "$MODE" = "all" ]; then
  if is_termux || [ "$MODE" = "all" ]; then
    echo "[harden] Applying Termux-side hardening..."
    ensure_ssh_dir
    fix_private_keys
    apply_sshd_hardening
  else
    echo "[harden] Not running on Termux; skipping termux hardening."
  fi
fi

if [ "$MODE" = "laptop" ] || [ "$MODE" = "all" ]; then
  echo "[harden] Applying laptop-side hardening..."
  ensure_ssh_dir
  fix_private_keys
  # recommend ssh-agent usage by creating a sample ~/.ssh/config for Termux hosts
  mkdir -p "$HOME/.ssh"
  CFG="$HOME/.ssh/config"
  backup_file "$CFG"
  cat > "$CFG" <<'EOF'
# Example SSH config entry for Termux devices (edit hostname and user)
Host termux-*
  Protocol 2
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
  ServerAliveInterval 60
  ServerAliveCountMax 3
EOF
  chmod 600 "$CFG" || true
  echo "Created sample ~/.ssh/config (permissions 600)."
fi

echo "[harden] Completed. Review changes and verify you can still connect."
echo "If you cannot connect, restore backups with *.harden.bak timestamps or check backups created by this script."

exit 0
