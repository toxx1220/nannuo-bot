#!/usr/bin/env bash
# Update jar-source.nix with the URL and hash of a tagged GitHub Release JAR.
#
# Usage:
#   nix run .#update-jar -- <tag>
#   nix run .#update-jar -- v1.0.0
set -euo pipefail

REPO="toxx1220/nannuo-bot"
JAR_NAME="nannuo-bot.jar"

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  echo "Usage: update-jar <tag>  (e.g. v1.0.0)"
  exit 0
fi

TAG=${1:?"Error: missing tag argument. Usage: update-jar <tag> (e.g., v1.0.0)"}
URL="https://github.com/${REPO}/releases/download/${TAG}/${JAR_NAME}"

echo "[..] Prefetching ${URL}"

HASH=$(nix store prefetch-file --json "$URL" | jq -r '.hash')

if [[ -z $HASH || $HASH == "null" ]]; then
  echo "[FAIL] Could not compute hash. Is the release/tag correct?"
  exit 1
fi

echo "[OK] Hash: ${HASH}"

cat >jar-source.nix <<EOF
# Auto-updated by GitHub Actions on each tagged release.
# To update manually, run: nix run .#update-jar -- <tag>
{
  version = "${TAG}";
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
echo "Done! Review and commit:"
echo "  git commit -m \"chore: update JAR to ${TAG}\""
