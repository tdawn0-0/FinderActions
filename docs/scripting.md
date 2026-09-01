# Scripting API

Shell actions run under the **Host** process via `Process` with **argv arrays** — paths are never unquoted-joined into a single shell string.

## Environment

| Name | Description |
|------|-------------|
| `"$@"` / `$1`… | Selected absolute paths (one argv element each) |
| `FA_CWD` | Working directory (Finder container when available) |
| `FA_PATHS` | Same paths, newline-separated |
| `FA_PATH_COUNT` | Number of paths |
| `FA_CONTAINER` | Finder container path |
| `FA_ACTION_ID` | Action id from the manifest |

Working directory of the process is `FA_CWD`.

## Rules

1. Always quote: `"$f"`, `"$@"`.  
2. Prefer looping `"$@"` over splitting `FA_PATHS` unless you need multiline-safe iteration in pure env form.  
3. No implicit `sudo`.  
4. Exit `0` on success; first stdout line may show in the notification.  
5. Non-zero exit → failure notification; stderr is logged.

## Examples

### Copy paths

```bash
#!/bin/zsh
set -euo pipefail
print -r -- "$@" | pbcopy
print -r -- "Copied $# path(s)"
```

### ffmpeg batch

```bash
#!/bin/zsh
set -euo pipefail
for f in "$@"; do
  ffmpeg -i "$f" -c:v libx264 -crf 23 "${f%.*}_out.mp4"
done
```

### cd and run CLI

```bash
#!/bin/zsh
set -euo pipefail
cd "$FA_CWD"
exec your-tool "$@"
```

## Terminal actions

Terminal launch is configured in **Settings → Applications**, not as separate
manifest actions. Finder exposes one `Open in Terminal` command; the Host opens
the selected terminal at the resolved working directory. Editors use the same
settings page and may be enabled individually or in combination.

## AppleScript actions

Inline or file-based `osascript`. Host prefixes:

```applescript
set faPaths to {"/a", "/b"}
set faContainer to "/container"
set faActionId to "my-id"
-- your script
```
