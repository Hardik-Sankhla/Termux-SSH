#!/usr/bin/env bash
set -euo pipefail

# Fail if any file contains a private key header (simple grep scan)
echo "Scanning for private keys..."
set +o pipefail
matches=0
while IFS= read -r -d '' file; do
  if grep -Iq "-----BEGIN .*PRIVATE KEY-----" "$file"; then
    echo "ERROR: Private key-like content found in: $file"
    matches=$((matches+1))
  fi
done < <(git ls-files -z)
set -o pipefail

if [ "$matches" -ne 0 ]; then
  echo "Found $matches potential private key files. Remove them before committing."
  exit 1
fi

echo "No private-key patterns found."
exit 0
