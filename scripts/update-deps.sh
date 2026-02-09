#!/usr/bin/env bash
# Update the fixed-output derivation hash for nannuo-bot-deps.
# Called via: nix run .#update-deps
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  update-deps              Update deps hash for the current system only
  update-deps --all        Update deps hashes for all supported systems
  update-deps <system...>  Update deps hashes for specific Nix systems

Examples:
  nix run .#update-deps
  nix run .#update-deps -- --all
  nix run .#update-deps -- aarch64-linux x86_64-linux
EOF
}

# Resolve current system (works on nix >= 2.4)
CURRENT_SYSTEM=$(nix eval --raw --impure --expr builtins.currentSystem)

SUPPORTED_SYSTEMS=(
  "x86_64-linux"
  "aarch64-linux"
  "x86_64-darwin"
  "aarch64-darwin"
)

TARGET_SYSTEMS=()

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
elif [[ ${1:-} == "--all" ]]; then
  TARGET_SYSTEMS=("${SUPPORTED_SYSTEMS[@]}")
  shift
elif [[ $# -gt 0 ]]; then
  TARGET_SYSTEMS=("$@")
else
  TARGET_SYSTEMS=("$CURRENT_SYSTEM")
fi

mkdir -p deployments/deps-hash

update_one() {
  local system="$1"
  local out new_hash hash_file

  echo "[..] Calculating new dependency hash for ${system}"
  echo "     (This may take a few minutes as it downloads dependencies)"

  # Capture output; allow failure since hash mismatch is expected
  out=$(nix build .#nannuo-bot-deps --system "${system}" --no-link 2>&1) && {
    echo "[OK] ${system}: dependencies are already up to date. No hash change needed."
    return 0
  }

  # Extract new hash from "got: sha256-..." line
  new_hash=$(grep -oE 'got:[[:space:]]*sha256-[^[:space:]]+' <<<"$out" | sed 's/got:[[:space:]]*//' || true)

  if [[ -z "$new_hash" ]]; then
    echo "[FAIL] ${system}: could not automatically determine the new hash."
    echo "Error output was:"
    echo "$out"
    return 1
  fi

  echo "[OK] ${system}: new hash found: $new_hash"

  hash_file="deployments/deps-hash/${system}.nix"
  echo "\"$new_hash\"" >"${hash_file}"
  echo "[OK] Wrote ${hash_file}"

  # Automatically stage the change if in a git repo
  [[ -d .git ]] && git add "${hash_file}" >/dev/null 2>&1 || true
}

fail=0
for sys in "${TARGET_SYSTEMS[@]}"; do
  if ! update_one "$sys"; then
    fail=1
  fi
done

[[ -d .git ]] && echo "[OK] Staged updated deps-hash files (if any)"

exit "$fail"
