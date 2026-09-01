#!/bin/zsh
set -euo pipefail
names=()
for p in "$@"; do
  names+=("${p:t}")
done
print -r -- "${(j:\n:)names}" | pbcopy
print -r -- "Copied ${#names} name(s)"
