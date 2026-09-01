#!/bin/zsh
set -euo pipefail
# "$@" = selected paths; also available as FA_PATHS (newline-separated)
print -r -- "$@" | pbcopy
print -r -- "Copied ${FA_PATH_COUNT:-$#} path(s)"
