#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DERIVED_DATA_PATH="$PROJECT_ROOT/build/DerivedData/Debug"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install it with: brew install xcodegen" >&2
  exit 1
fi

xcodegen generate \
  --spec "$PROJECT_ROOT/project.yml" \
  --project "$PROJECT_ROOT"

xcodebuild \
  -project "$PROJECT_ROOT/FinderActions.xcodeproj" \
  -scheme FinderActions \
  -configuration Debug \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=NO \
  build

echo "Debug app: $DERIVED_DATA_PATH/Build/Products/Debug/FinderActions.app"
