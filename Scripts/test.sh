#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

swift test --package-path "$PROJECT_ROOT" --scratch-path "$PROJECT_ROOT/build/SwiftPM"
