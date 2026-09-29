#!/bin/zsh
set -euo pipefail
# "$@" = selected paths; also available as FA_PATHS (newline-separated)
printf '%s\n' "$@" | /usr/bin/pbcopy
print -r -- "Copied ${FA_PATH_COUNT:-$#} path(s)"
