#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
./Scripts/gen.sh
xcodebuild \
  -project FinderActions.xcodeproj \
  -scheme FinderActions \
  -configuration Debug \
  -derivedDataPath build/DerivedData \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=NO \
  build
echo "Build OK"
