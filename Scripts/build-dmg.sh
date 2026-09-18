#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RELEASE_CONFIG="$PROJECT_ROOT/.release.env"

if [[ -f "$RELEASE_CONFIG" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$RELEASE_CONFIG"
  set +a
fi

NOTARY_PROFILE="${NOTARY_PROFILE:-FinderActions-notary}"
APP_PATH="${1:-}"
OUTPUT_DMG="${2:-}"
SKIP_NOTARIZATION="${SKIP_NOTARIZATION:-false}"

# Check required tools
for tool in create-dmg codesign xcrun shasum; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Error: Required tool '$tool' not found." >&2
    if [[ "$tool" == "create-dmg" ]]; then
      echo "Install create-dmg with: brew install create-dmg" >&2
    fi
    exit 1
  fi
done

# Find FinderActions.app if not provided
if [[ -z "$APP_PATH" ]]; then
  # Look for latest release export
  LATEST_EXPORT="$(find "$PROJECT_ROOT/build/releases" -type d -name "export" 2>/dev/null | sort -r | head -n 1 || true)"
  if [[ -n "$LATEST_EXPORT" && -d "$LATEST_EXPORT/FinderActions.app" ]]; then
    APP_PATH="$LATEST_EXPORT/FinderActions.app"
  elif [[ -d "$PROJECT_ROOT/build/DerivedData/Debug/Build/Products/Debug/FinderActions.app" ]]; then
    APP_PATH="$PROJECT_ROOT/build/DerivedData/Debug/Build/Products/Debug/FinderActions.app"
  fi
fi

if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "Error: FinderActions.app not found." >&2
  echo "Usage: $0 [path/to/FinderActions.app] [path/to/output.dmg]" >&2
  exit 1
fi

APP_PATH="$(cd "$(dirname "$APP_PATH")" && pwd)/$(basename "$APP_PATH")"
INFO_PLIST="$APP_PATH/Contents/Info.plist"

if [[ ! -f "$INFO_PLIST" ]]; then
  echo "Error: Invalid application bundle, Info.plist missing: $APP_PATH" >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST" 2>/dev/null || echo "1.0.0")"
BUILD_NUM="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST" 2>/dev/null || echo "1")"

# Determine output DMG path
if [[ -z "$OUTPUT_DMG" ]]; then
  OUTPUT_DIR="$(dirname "$APP_PATH")"
  OUTPUT_DMG="$OUTPUT_DIR/FinderActions-$VERSION.dmg"
fi

OUTPUT_DIR="$(cd "$(dirname "$OUTPUT_DMG")" 2>/dev/null && pwd || dirname "$OUTPUT_DMG")"
mkdir -p "$OUTPUT_DIR"

# Resolve Developer ID signing identity
SIGN_IDENTITY=""
if security find-identity -v -p codesigning | grep -q 'Developer ID Application'; then
  SIGN_IDENTITY="$(security find-identity -v -p codesigning | grep 'Developer ID Application' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')"
fi

echo "=========================================="
echo " Building FinderActions Drag-and-Drop DMG "
echo "=========================================="
echo "App Path:    $APP_PATH"
echo "Version:     $VERSION ($BUILD_NUM)"
echo "Output DMG:  $OUTPUT_DMG"
if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "Identity:    $SIGN_IDENTITY"
else
  echo "Identity:    (No Developer ID found, skipping codesign)"
fi
echo "=========================================="

# Remove existing DMG if present (create-dmg fails if output exists)
rm -f "$OUTPUT_DMG"

echo "[1/4] Creating DMG with Applications shortcut..."
create-dmg \
  --volname "FinderActions" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 128 \
  --icon "FinderActions.app" 180 170 \
  --hide-extension "FinderActions.app" \
  --app-drop-link 480 170 \
  --no-internet-enable \
  "$OUTPUT_DMG" \
  "$APP_PATH" || true

if [[ ! -f "$OUTPUT_DMG" ]]; then
  echo "Error: DMG creation failed." >&2
  exit 1
fi

# Codesign DMG if Developer ID is available
if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "[2/4] Signing DMG with Developer ID..."
  codesign --force --sign "$SIGN_IDENTITY" --timestamp "$OUTPUT_DMG"
  codesign --verify --verbose=2 "$OUTPUT_DMG"
else
  echo "[2/4] Skipping DMG signing (no Developer ID certificate)."
fi

# Notarize DMG if profile is available
if [[ "$SKIP_NOTARIZATION" != "true" && -n "$SIGN_IDENTITY" ]]; then
  if xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" --output-format json >/dev/null 2>&1; then
    echo "[3/4] Submitting DMG to Apple Notary Service..."
    DMG_NOTARY_JSON="$OUTPUT_DIR/notarization-dmg.json"
    if xcrun notarytool submit "$OUTPUT_DMG" \
      --keychain-profile "$NOTARY_PROFILE" \
      --wait \
      --timeout 30m \
      --output-format json >"$DMG_NOTARY_JSON"; then
      
      NOTARY_STATUS="$(plutil -extract status raw -o - "$DMG_NOTARY_JSON" 2>/dev/null || echo "Accepted")"
      if [[ "$NOTARY_STATUS" == "Accepted" ]]; then
        echo "Stapling notarization ticket to DMG..."
        xcrun stapler staple -v "$OUTPUT_DMG"
        xcrun stapler validate -v "$OUTPUT_DMG"
        spctl --assess --type open --context context:primary-signature --verbose=4 "$OUTPUT_DMG" || true
      else
        echo "Warning: DMG notarization status: $NOTARY_STATUS" >&2
      fi
    else
      echo "Warning: DMG notarization submission failed. DMG is signed but not stapled." >&2
    fi
  else
    echo "[3/4] Keychain profile '$NOTARY_PROFILE' not found. Skipping DMG notarization."
  fi
else
  echo "[3/4] Skipping notarization."
fi

echo "[4/4] Calculating SHA-256 checksum..."
(
  cd "$OUTPUT_DIR"
  shasum -a 256 "$(basename "$OUTPUT_DMG")" >"$(basename "$OUTPUT_DMG").sha256"
)

echo
echo "✓ DMG Packaging Complete!"
echo "DMG:      $OUTPUT_DMG"
echo "Checksum: $OUTPUT_DMG.sha256"
echo "SHA256:   $(cat "$OUTPUT_DMG.sha256" | awk '{print $1}')"
