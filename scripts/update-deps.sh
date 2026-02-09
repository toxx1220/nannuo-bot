#!/usr/bin/env bash
# Update the fixed-output derivation hash for nannuo-bot-deps.
# Called via: nix run .#update-deps
set -euo pipefail

echo "[..] Calculating new dependency hash"
echo "     (This may take a few minutes as it downloads dependencies)"

# Capture output; allow failure since hash mismatch is expected
OUT=$(nix build .#nannuo-bot-deps --no-link 2>&1) && {
  echo "[OK] Dependencies are already up to date. No hash change needed."
  exit 0
}

# Extract new hash from "got: sha256-..." line
NEW_HASH=$(grep -oE 'got:[[:space:]]*sha256-[^[:space:]]+' <<< "$OUT" | sed 's/got:[[:space:]]*//' || true)

if [[ -z "$NEW_HASH" ]]; then
  echo "[FAIL] Could not automatically determine the new hash."
  echo "Error output was:"
  echo "$OUT"
  exit 1
fi

echo "[OK] New hash found: $NEW_HASH"
echo "\"$NEW_HASH\"" > deployments/deps-hash.nix
echo "[OK] deployments/deps-hash.nix updated!"

# Automatically stage the change if in a git repo
[[ -d .git ]] && git add deployments/deps-hash.nix && echo "[OK] Staged deployments/deps-hash.nix"

