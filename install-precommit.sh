#!/usr/bin/env bash
set -euo pipefail

# Install a local pre-commit hook that runs the private-key scan
HOOK_FILE=".git/hooks/pre-commit"
cat > "$HOOK_FILE" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
echo "Running local private-key scan..."
./ci/check-no-keys.sh || { echo "Private key pattern found - aborting commit."; exit 1; }
HOOK
chmod +x "$HOOK_FILE"
echo "Installed local pre-commit hook at $HOOK_FILE"

exit 0
