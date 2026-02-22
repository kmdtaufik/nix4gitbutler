#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_NIX="$SCRIPT_DIR/cli.nix"

# Options
DRY_RUN=false
FORCE=false

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -n, --dry-run    Show what would be updated without making changes"
  echo "  -f, --force      Force update even if version is the same"
  echo "  -h, --help       Show this help message"
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -n|--dry-run) DRY_RUN=true; shift ;;
    -f|--force) FORCE=true; shift ;;
    -h|--help) usage ;;
    *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
  esac
done

cleanup() {
  [[ -n "${TMP_DIR:-}" ]] && rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "🕵️  Intercepting true binary URL from the installer..."

TMP_DIR=$(mktemp -d)
if ! curl -fsSL https://gitbutler.com/install.sh | sh >"$TMP_DIR/out.log" 2>&1 & then
  echo -e "${RED}❌ Failed to fetch installer script${NC}"
  exit 1
fi
PID=$!

TRUE_URL=""
# Poll the output file for the URL, then instantly kill the installer to save bandwidth
for i in {1..50}; do
  if grep -q "Download URL:" "$TMP_DIR/out.log"; then
    TRUE_URL=$(awk '/Download URL:/ {print $3}' "$TMP_DIR/out.log" | tr -d '\r')
    kill -9 $PID 2>/dev/null || true
    break
  fi
  sleep 0.2
done

if [[ -z "$TRUE_URL" ]]; then
  echo -e "${RED}❌ Failed to extract binary URL. Installer output:${NC}"
  cat "$TMP_DIR/out.log"
  exit 1
fi

# Extract version dynamically (e.g., 0.19.3-2869)
NEW_VERSION=$(echo "$TRUE_URL" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+-[0-9]+' | head -n 1)

if [[ -z "$NEW_VERSION" ]]; then
  echo -e "${RED}❌ Failed to extract version from URL${NC}"
  exit 1
fi

# Get current version from cli.nix
CURRENT_VERSION=$(grep -oP 'version = "\K[^"]+' "$CLI_NIX" || echo "unknown")

echo -e "${GREEN}✅ Found Target URL:${NC} $TRUE_URL"
echo -e "📦 Current Version: ${YELLOW}$CURRENT_VERSION${NC}"
echo -e "📦 Latest Version:  ${GREEN}$NEW_VERSION${NC}"

# Version comparison
if [[ "$CURRENT_VERSION" == "$NEW_VERSION" ]] && [[ "$FORCE" == false ]]; then
  echo -e "${GREEN}✅ Already up to date! Use --force to update anyway.${NC}"
  exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
  echo -e "${YELLOW}🔍 Dry run mode - no changes will be made${NC}"
  echo ""
  echo "Would update:"
  echo "  version: $CURRENT_VERSION → $NEW_VERSION"
  echo "  url: $TRUE_URL"
  exit 0
fi

echo "🧮 Calculating Nix SRI hash (this will download the full binary to the Nix store)..."

if ! NEW_HASH=$(nix store prefetch-file --json "$TRUE_URL" 2>/dev/null | grep '"hash"' | cut -d '"' -f 4); then
  echo -e "${RED}❌ Failed to calculate hash. Check your network connection.${NC}"
  exit 1
fi

if [[ -z "$NEW_HASH" ]]; then
  echo -e "${RED}❌ Hash calculation returned empty result${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Calculated Hash:${NC} $NEW_HASH"
echo "📝 Updating cli.nix..."

# Inject the newly discovered URL, Version, and Hash into cli.nix
sed -i.bak -e "s|version = \".*\";|version = \"$NEW_VERSION\";|" \
  -e "s|url = \".*\";|url = \"$TRUE_URL\";|" \
  -e "s|hash = \".*\";|hash = \"$NEW_HASH\";|" "$CLI_NIX"

rm -f "$CLI_NIX.bak"

echo -e "${GREEN}🎉 Success!${NC} Updated $CURRENT_VERSION → $NEW_VERSION"
echo "Run 'nix build .#' to compile."
