#!/usr/bin/env bash
# All Apple/build tools are stubs; the copied project cannot source user credentials.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/fa-dmg-tests.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT/project/Scripts" "$TEST_ROOT/bin" "$TEST_ROOT/App With Spaces.app/Contents"
cp "$ROOT/Scripts/build-dmg.sh" "$ROOT/Scripts/release.sh" "$TEST_ROOT/project/Scripts/"
cat > "$TEST_ROOT/App With Spaces.app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>CFBundleShortVersionString</key><string>1.0.0</string><key>CFBundleVersion</key><string>1</string></dict></plist>
PLIST
cat > "$TEST_ROOT/bin/stub" <<'STUB'
#!/bin/bash
set -euo pipefail
name="$(basename "$0")"
echo "$name $*" >> "$CALLS"
case "$name" in
security)
  [[ "$CASE" != no_identity && "$CASE" != local ]] && echo '1) FAKE "Developer ID Application: Synthetic Test"'
  exit 0;;
create-dmg)
  args=("$@"); count=${#args[@]}; touch "${args[$((count-2))]}"
  [[ "$CASE" != partial ]] ;;
codesign)
  [[ "$CASE" != codesign ]] || exit 1
  echo 'flags=runtime'; echo 'Timestamp=test';;
xcrun)
  if [[ "$1 $2" == 'notarytool history' ]]; then [[ "$CASE" != no_profile ]];
  elif [[ "$1 $2" == 'notarytool submit' ]]; then
    if [[ "$3" == *.dmg ]]; then
      [[ "$CASE" != submit ]] || exit 1
      case "$CASE" in rejected) echo '{"status":"Invalid"}';; missing) echo '{}';; malformed) echo 'broken';; *) echo '{"status":"Accepted"}';; esac
    else echo '{"status":"Accepted","id":"synthetic"}'; fi
  elif [[ "$1 $2" == 'stapler staple' ]]; then [[ "$CASE" != staple || "$4" != *.dmg ]];
  elif [[ "$1 $2" == 'stapler validate' ]]; then [[ "$CASE" != validate || "$4" != *.dmg ]];
  else exit 1; fi;;
plutil)
  /usr/bin/python3 - "$2" "${@: -1}" <<'PY'
import json,sys
print(json.load(open(sys.argv[2]))[sys.argv[1]])
PY
  ;;
spctl) [[ "$CASE" != gatekeeper || "${@: -1}" != *.dmg ]];;
xcodebuild)
  if [[ "$1" == -exportArchive ]]; then
    while [[ "$1" != -exportPath ]]; do shift; done
    mkdir -p "$2/FinderActions.app/Contents/PlugIns/FAFinderSync.appex" "$2/FinderActions.app/Contents/Helpers/FinderActionsSettings.app"
    cp "$FIXTURE" "$2/FinderActions.app/Contents/Info.plist"
  fi;;
ditto) touch "${@: -1}";;
xcodegen|otool) :;;
*) exit 1;;
esac
STUB
chmod +x "$TEST_ROOT/bin/stub"
for tool in security create-dmg codesign xcrun plutil spctl xcodegen xcodebuild ditto otool; do ln -s stub "$TEST_ROOT/bin/$tool"; done
export PATH="$TEST_ROOT/bin:$PATH" CALLS="$TEST_ROOT/calls" FIXTURE="$TEST_ROOT/App With Spaces.app/Contents/Info.plist"
for CASE in accepted rejected missing malformed submit no_profile no_identity skip partial codesign staple validate gatekeeper local; do
  export CASE
  OUT="$TEST_ROOT/$CASE.dmg"
  MODE=--release
  [[ "$CASE" != local ]] || MODE=--local
  SKIP_NOTARIZATION=false
  [[ "$CASE" != skip ]] || SKIP_NOTARIZATION=true
  export SKIP_NOTARIZATION
  if bash "$TEST_ROOT/project/Scripts/build-dmg.sh" "$MODE" "$TEST_ROOT/App With Spaces.app" "$OUT" >"$TEST_ROOT/output" 2>&1; then result=0; else result=$?; fi
  case "$CASE" in
    accepted) [[ "$result" == 0 && -f "$OUT.sha256" ]]; grep -q 'DMG Packaging Complete' "$TEST_ROOT/output";;
    local) [[ "$result" == 0 && -f "$OUT.sha256" ]]; grep -q 'UNVERIFIED' "$TEST_ROOT/output"; ! grep -q 'DMG Packaging Complete' "$TEST_ROOT/output";;
    *) [[ "$result" != 0 && ! -f "$OUT.sha256" ]]; ! grep -q 'DMG Packaging Complete' "$TEST_ROOT/output";;
  esac
  echo "PASS helper: $CASE"
done
# Run the real release orchestration with harmless build/archive/Apple stubs.
for relative in Apps/Host/Resources Apps/Settings/Resources Extensions/FinderSync; do
  mkdir -p "$TEST_ROOT/project/$relative"
  cp "$FIXTURE" "$TEST_ROOT/project/$relative/Info.plist"
done
printf '#!/bin/bash\nexit 0\n' > "$TEST_ROOT/project/Scripts/test.sh"
printf '#!/bin/bash\nexit 0\n' > "$TEST_ROOT/project/Scripts/check-host-dependencies.sh"
chmod +x "$TEST_ROOT/project/Scripts/test.sh"
export CASE=gatekeeper DEVELOPMENT_TEAM=TESTTEAM01 SKIP_NOTARIZATION=false
if bash "$TEST_ROOT/project/Scripts/release.sh" >"$TEST_ROOT/release-output" 2>&1; then
  echo 'Release incorrectly accepted failed DMG gate' >&2; exit 1
fi
! grep -q 'Release Complete' "$TEST_ROOT/release-output"
grep -q '\[8/8\] Building, signing, and notarizing' "$TEST_ROOT/release-output"
grep -q '\[3/4\] Submitting DMG' "$TEST_ROOT/release-output"
grep -q 'build-dmg' "$TEST_ROOT/project/Scripts/release.sh"
grep -q 'spctl --assess --type open' "$CALLS"
echo 'PASS orchestration: failed DMG gate prevents Release Complete'
