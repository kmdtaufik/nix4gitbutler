#!/usr/bin/env bash
# Enforce strict error handling: fail on error, fail on unset variables, fail on pipe errors.
set -euo pipefail

# -----------------------------------------------------------------------------
# 1. Fetch Data: Sole responsibility is getting the payload or crashing cleanly.
# -----------------------------------------------------------------------------
fetch_json() {
  local api_url="https://app.gitbutler.com/releases"
  local response

  response=$(curl -s "$api_url")

  if [[ -z "$response" || "$response" == "null" ]]; then
    echo "❌ Failed to fetch release data from API." >&2
    exit 1
  fi

  # Return the payload via stdout
  echo "$response"
}

# -----------------------------------------------------------------------------
# 2. Parse Data: Sole responsibility is extracting the exact strings we need.
# -----------------------------------------------------------------------------
parse_json() {
  local raw_json="$1"
  local appimage_url

  # Extract the version
  VERSION=$(echo "$raw_json" | jq -r '.version')

  if [[ -z "$VERSION" ]]; then
    echo "❌ Failed to parse version from JSON payload." >&2
    exit 1
  fi

  # Extract AppImage URL and mutate it into our CLI and GUI targets
  CLI_URL=$(echo "$raw_json" | jq -r '.platforms."linux-x86_64".url')
  # CLI_URL=$(echo "$appimage_url" | sed 's|[^/]*$|but|')
  GUI_URL=$(echo "$CLI_URL" | sed "s|[^/]*$|GitButler_${VERSION}_amd64.deb|")
}

# -----------------------------------------------------------------------------
# 3. Write Data: Sole responsibility is safely writing the nested state.
# -----------------------------------------------------------------------------
write_json() {
  jq -n \
    --arg v "$VERSION" \
    --arg cli_u "$CLI_URL" \
    --arg gui_u "$GUI_URL" \
    --arg cli_h "$CLI_HASH" \
    --arg gui_h "$GUI_HASH" \
    '{
      version: $v,
      "x86_64-linux": {
        url: {
          cli: $cli_u,
          gui: $gui_u
        },
        hash: {
          cli: $cli_h,
          gui: $gui_h
        }
      }
    }' >sources.json
}

# -----------------------------------------------------------------------------
# 4. Orchestration
# -----------------------------------------------------------------------------
main() {
  echo "🕵️  Fetching release data from GitButler API..."
  local raw_data
  raw_data=$(fetch_json)

  echo "🔍 Parsing payload..."
  # Globals are mutated here intentionally
  parse_json "$raw_data"

  echo "📦 Latest Version: $VERSION"

  echo "🧮 Calculating CLI hash for Nix store..."
  CLI_HASH=$(nix store prefetch-file --json "$CLI_URL" 2>/dev/null | jq -r '.hash')

  echo "🧮 Calculating GUI hash for Nix store..."
  GUI_HASH=$(nix store prefetch-file --json "$GUI_URL" 2>/dev/null | jq -r '.hash')

  # Sanity check before we write to disk
  if [[ -z "$CLI_HASH" || -z "$GUI_HASH" ]]; then
    echo "❌ Hash calculation failed. Check network or URLs." >&2
    exit 1
  fi

  echo "📝 Updating sources.json..."
  write_json

  echo "🎉 Success! The sources file has been updated securely."
}

# Execute
main
