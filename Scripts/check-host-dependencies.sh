#!/usr/bin/env bash

set -euo pipefail

APP_PATH="${1:?Usage: check-host-dependencies.sh /path/to/FinderActions.app}"
HOST_MACOS="$APP_PATH/Contents/MacOS"
SETTINGS_MACOS="$APP_PATH/Contents/Helpers/FinderActionsSettings.app/Contents/MacOS"

if [[ ! -d "$HOST_MACOS" || ! -d "$SETTINGS_MACOS" ]]; then
  echo "Host or embedded Settings executable directory is missing: $APP_PATH" >&2
  exit 1
fi

host_has_swiftui=false
settings_has_swiftui=false

for binary in "$HOST_MACOS"/*; do
  [[ -f "$binary" ]] || continue
  if otool -L "$binary" 2>/dev/null | grep -q '/SwiftUI.framework/'; then
    echo "SwiftUI must not be linked by the always-resident Host: $binary" >&2
    host_has_swiftui=true
  fi
done

for binary in "$SETTINGS_MACOS"/*; do
  [[ -f "$binary" ]] || continue
  if otool -L "$binary" 2>/dev/null | grep -q '/SwiftUI.framework/'; then
    settings_has_swiftui=true
  fi
done

if [[ "$host_has_swiftui" == true ]]; then
  exit 1
fi

if [[ "$settings_has_swiftui" != true ]]; then
  echo "Embedded Settings app does not link SwiftUI as expected." >&2
  exit 1
fi

echo "Dependency boundary verified: Host excludes SwiftUI; Settings owns SwiftUI."
