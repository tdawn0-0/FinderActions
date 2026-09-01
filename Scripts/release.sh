#!/bin/zsh
set -euo pipefail
# Optional release helper: build Release configuration.
# Signing/notarization require a Developer ID — set DEVELOPMENT_TEAM and
# CODE_SIGN_IDENTITY in the environment or Xcode before shipping.
cd "$(dirname "$0")/.."
./Scripts/gen.sh
xcodebuild \
  -project FinderActions.xcodeproj \
  -scheme FinderActions \
  -configuration Release \
  -derivedDataPath build/DerivedDataRelease \
  build
echo "Release build at build/DerivedDataRelease/Build/Products/Release/FinderActions.app"
