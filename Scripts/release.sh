#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RELEASE_CONFIG="$PROJECT_ROOT/.release.env"
EXPORT_OPTIONS="$PROJECT_ROOT/Config/DeveloperIDExportOptions.plist"
INFO_PLIST="$PROJECT_ROOT/Apps/Host/Resources/Info.plist"
EXTENSION_INFO_PLIST="$PROJECT_ROOT/Extensions/FinderSync/Info.plist"

if [[ -f "$RELEASE_CONFIG" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$RELEASE_CONFIG"
  set +a
fi

DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-FinderActions-notary}"

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required tool not found: $1" >&2
    exit 1
  fi
}

json_value() {
  plutil -extract "$1" raw -o - "$2" 2>/dev/null || true
}

assert_hardened_signature() {
  local bundle_path="$1"
  local signature_details
  signature_details="$(codesign -d --verbose=4 "$bundle_path" 2>&1)"

  if ! grep -Eq 'flags=.*runtime' <<<"$signature_details"; then
    echo "Hardened Runtime is missing from: $bundle_path" >&2
    exit 1
  fi

  if ! grep -q '^Timestamp=' <<<"$signature_details"; then
    echo "Secure timestamp is missing from: $bundle_path" >&2
    exit 1
  fi
}

for tool in xcodegen xcodebuild xcrun security codesign ditto plutil shasum spctl; do
  require_tool "$tool"
done

if [[ ! "$DEVELOPMENT_TEAM" =~ ^[A-Z0-9]{10}$ ]]; then
  echo "DEVELOPMENT_TEAM must be a 10-character Apple Developer Team ID." >&2
  echo "Run Scripts/setup-signing.sh first." >&2
  exit 1
fi

if [[ ! "$NOTARY_PROFILE" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "NOTARY_PROFILE may contain only letters, numbers, dot, underscore, and hyphen." >&2
  exit 1
fi

if ! security find-identity -v -p codesigning | grep -q 'Developer ID Application'; then
  echo "No Developer ID Application certificate was found in the Keychain." >&2
  echo "Run Scripts/setup-signing.sh first." >&2
  exit 1
fi

if ! xcrun notarytool history \
  --keychain-profile "$NOTARY_PROFILE" \
  --output-format json >/dev/null; then
  echo "The notarization Keychain profile '$NOTARY_PROFILE' is unavailable or invalid." >&2
  echo "Run Scripts/setup-signing.sh first." >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST")"
EXTENSION_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$EXTENSION_INFO_PLIST")"
EXTENSION_BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$EXTENSION_INFO_PLIST")"
if [[ "$VERSION" != "$EXTENSION_VERSION" || "$BUILD_NUMBER" != "$EXTENSION_BUILD_NUMBER" ]]; then
  echo "Host and FinderSync versions must match before release." >&2
  echo "Host: $VERSION ($BUILD_NUMBER); FinderSync: $EXTENSION_VERSION ($EXTENSION_BUILD_NUMBER)" >&2
  exit 1
fi
RELEASE_STAMP="$(date -u '+%Y%m%dT%H%M%SZ')"
RELEASE_DIR="$PROJECT_ROOT/build/releases/$VERSION-$BUILD_NUMBER-$RELEASE_STAMP"
ARCHIVE_PATH="$RELEASE_DIR/FinderActions.xcarchive"
EXPORT_PATH="$RELEASE_DIR/export"
APP_PATH="$EXPORT_PATH/FinderActions.app"
EXTENSION_PATH="$APP_PATH/Contents/PlugIns/FAFinderSync.appex"
NOTARY_JSON="$RELEASE_DIR/notarization.json"
NOTARY_LOG="$RELEASE_DIR/notarization-log.json"
FINAL_ZIP="$RELEASE_DIR/FinderActions-$VERSION-$BUILD_NUMBER.zip"
RELEASE_TEMP_DIR="$(mktemp -d /tmp/finderactions-release.XXXXXX)"
SUBMISSION_ZIP="$RELEASE_TEMP_DIR/FinderActions-submission.zip"

trap 'rm -rf "$RELEASE_TEMP_DIR"' EXIT
if [[ -e "$RELEASE_DIR" ]]; then
  echo "Release directory already exists: $RELEASE_DIR" >&2
  exit 1
fi
mkdir -p "$RELEASE_DIR"

echo "[1/7] Running tests"
"$SCRIPT_DIR/test.sh"

echo "[2/7] Generating the Xcode project"
xcodegen generate \
  --spec "$PROJECT_ROOT/project.yml" \
  --project "$PROJECT_ROOT"

echo "[3/7] Creating the release archive"
xcodebuild \
  -project "$PROJECT_ROOT/FinderActions.xcodeproj" \
  -scheme FinderActions \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  OTHER_CODE_SIGN_FLAGS=--timestamp \
  archive

echo "[4/7] Exporting with Developer ID"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS"

if [[ ! -d "$APP_PATH" || ! -d "$EXTENSION_PATH" ]]; then
  echo "The exported app or embedded FinderSync extension is missing." >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
assert_hardened_signature "$APP_PATH"
assert_hardened_signature "$EXTENSION_PATH"
codesign -d --entitlements :- "$APP_PATH" >"$RELEASE_DIR/FinderActions.entitlements.plist" 2>/dev/null
codesign -d --entitlements :- "$EXTENSION_PATH" >"$RELEASE_DIR/FAFinderSync.entitlements.plist" 2>/dev/null

echo "[5/7] Submitting to Apple's notary service"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$SUBMISSION_ZIP"

if ! xcrun notarytool submit "$SUBMISSION_ZIP" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait \
  --timeout 30m \
  --output-format json >"$NOTARY_JSON"; then
  NOTARY_ID="$(json_value id "$NOTARY_JSON")"
  if [[ -n "$NOTARY_ID" ]]; then
    xcrun notarytool log --keychain-profile "$NOTARY_PROFILE" \
      "$NOTARY_ID" "$NOTARY_LOG" || true
  fi
  echo "Notarization failed. See: $NOTARY_JSON" >&2
  exit 1
fi

NOTARY_STATUS="$(json_value status "$NOTARY_JSON")"
NOTARY_ID="$(json_value id "$NOTARY_JSON")"
if [[ "$NOTARY_STATUS" != "Accepted" ]]; then
  if [[ -n "$NOTARY_ID" ]]; then
    xcrun notarytool log --keychain-profile "$NOTARY_PROFILE" \
      "$NOTARY_ID" "$NOTARY_LOG" || true
  fi
  echo "Notarization status is '$NOTARY_STATUS', not 'Accepted'." >&2
  exit 1
fi

echo "[6/7] Stapling and validating the notarization ticket"
xcrun stapler staple -v "$APP_PATH"
xcrun stapler validate -v "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH"

echo "[7/7] Creating the final distribution archive"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$FINAL_ZIP"
(
  cd "$RELEASE_DIR"
  shasum -a 256 "$(basename "$FINAL_ZIP")" >"$(basename "$FINAL_ZIP").sha256"
)

echo
echo "Release complete"
echo "App:      $APP_PATH"
echo "Archive:  $FINAL_ZIP"
echo "Checksum: $FINAL_ZIP.sha256"
echo "Notary:   $NOTARY_ID ($NOTARY_STATUS)"
