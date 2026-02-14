#!/usr/bin/env bash
# Update jar-source.nix with the URL and hash of a tagged GitHub Release JAR.
#
# Usage:
#   nix run .#update-jar -- <tag>
#   nix run .#update-jar -- v1.0.0
set -euo pipefail

REPO="toxx1220/nannuo-bot"
JAR_NAME="nannuo-bot.jar"

usage() {
  cat <<'EOF'
Usage:
  update-jar <tag>       Update jar-source.nix for the given release tag

Examples:
  nix run .#update-jar -- v1.0.0
  nix run .#update-jar -- v2.1.0
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

TAG=${1:?"Error: missing tag argument. Usage: update-jar <tag> (e.g., v1.0.0)"}
URL="https://github.com/${REPO}/releases/download/${TAG}/${JAR_NAME}"

echo "[..] Checking release URL: ${URL}"

# Verify the release asset actually exists
HTTP_CODE=$(curl -sL -o /dev/null -w "%{http_code}" "$URL")
if [[ "$HTTP_CODE" != "200" ]]; then
  echo "[FAIL] Release asset not found (HTTP ${HTTP_CODE})."
  echo "       Make sure the tag '${TAG}' exists and the release has '${JAR_NAME}' attached."
  exit 1
fi

echo "[..] Downloading and hashing JAR..."

# Use nix store prefetch-file to get the SRI hash directly
PREFETCH_JSON=$(nix store prefetch-file --json "$URL")
HASH=$(echo "$PREFETCH_JSON" | jq -r '.hash')

if [[ -z "$HASH" || "$HASH" == "null" ]]; then
  echo "[FAIL] Could not compute hash from nix store prefetch-file."
  echo "       Output was: ${PREFETCH_JSON}"
  exit 1
fi

echo "[OK] Hash: ${HASH}"

# Write updated jar-source.nix
cat > jar-source.nix << EOF
# Auto-updated by GitHub Actions on each tagged release.
# To update manually, run: nix run .#update-jar -- <tag>
{
  url = "${URL}";
  hash = "${HASH}";
}
EOF

echo "[OK] Wrote jar-source.nix"

# Stage the change if in a git repo
if [[ -d .git ]]; then
  git add jar-source.nix
  echo "[OK] Staged jar-source.nix"
fi

echo ""
echo "Done! Review the change and commit when ready:"
echo "  git commit -m \"chore: update JAR to ${TAG}\""
