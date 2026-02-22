#!/usr/bin/env bash
set -e

TMP_DIR=$(mktemp -d)
echo "🕵️  Intercepting true binary URL from the installer..."
curl -fsSL https://gitbutler.com/install.sh | sh >"$TMP_DIR/out.log" 2>&1 &
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

if [ -z "$TRUE_URL" ]; then
  echo "❌ Failed to extract binary URL. Installer output:"
  cat "$TMP_DIR/out.log"
  exit 1
fi

# Extract version dynamically (e.g., 0.19.3-2869)
VERSION=$(echo "$TRUE_URL" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+-[0-9]+' | head -n 1)

echo "✅ Found Target URL: $TRUE_URL"
echo "📦 Detected Version: $VERSION"

echo "🧮 Calculating Nix SRI hash (this will download the full binary to the Nix store)..."
# 5. Let Nix calculate the hash automatically
NEW_HASH=$(nix store prefetch-file --json "$TRUE_URL" | grep '"hash"' | cut -d '"' -f 4)

echo "✅ Calculated Hash: $NEW_HASH"
echo "📝 Updating cli.nix..."

# 6. Inject the newly discovered URL, Version, and Hash into your cli.nix
sed -i.bak -e "s|version = \".*\";|version = \"$VERSION\";|" \
  -e "s|url = \".*\";|url = \"$TRUE_URL\";|" \
  -e "s|hash = \".*\";|hash = \"$NEW_HASH\";|" cli.nix

rm -f cli.nix.bak

echo "🎉 Success! cli.nix is perfectly updated. Run 'nix build .#' to compile."
