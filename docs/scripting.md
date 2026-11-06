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
2. Loop over `"$@"` instead of splitting `FA_PATHS`. macOS filenames can contain newlines, so newline-separated `FA_PATHS` is a convenience format, not a lossless path list.
3. No implicit `sudo`.
4. Exit `0` on success; first stdout line may show in the notification.
5. Non-zero exit → failure notification; the last 4,000 characters of stderr are kept in Settings → Logs.

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


## Create, match, and test an action

In **Settings → Actions**, choose **Add New Action** and start with **Process Each
Selected File**, **Run a Command in Current Directory**, **Open with an
Application**, or **Blank Script**. New actions are disabled drafts. Set the name,
script/application and matching rules before enabling them for Finder.

For Shell and AppleScript, choose inline source or **Use External Script File**.
External files take priority; switching back to inline removes the file reference
and restores the retained inline draft. **Choose Script File…** and **Open in
Editor** avoid manually locating files. Applications can be selected with the
application chooser instead of entering their bundle identifier.

**File Extensions** accepts comma/space-separated extensions, ignoring leading
dots and letter case. **Input Kind** controls files/folders; **Show When** can
restrict selection count. Every selected path must match an extension filter:
selecting `image.png` together with `notes.txt` hides a PNG-only action. Use the
visibility explanation in Live Test to check the combination. Contradictory
file/folder rules must be corrected before enabling an action.

In **Live Test Console**, choose or drop files/folders, remove inputs individually,
and optionally choose a separate working directory. **Use Selection Context**
removes that override. Clearing selected inputs while retaining a working
directory tests that directory as the effective input. Clearing both requires a
new input before Run Test becomes available.

The execution preview uses the production path/argument helpers. Shell preview
shows exact argv as JSON, the working directory and only `FA_*` variables; it does
not expose the inherited environment. Non-shell previews describe their launcher.
A Finder-hidden action can still be tested explicitly. **Run Test executes the
real action and can change files.** Inputs and the action are captured for that
run. Keep Settings open until completion; controls that could change the running
action are disabled. There is no promised stop/rollback of script side effects or
descendant processes. Results include stdout/stderr and a local Test Run log.

## Portable action packages

Select an action and choose **Export Action…**. Add a note listing tools or
applications it needs (for example `ffmpeg`), then save a `.faaction` file. The
versioned JSON package contains the action metadata, dependency note and embedded
script files. It does not include arbitrary files that your script reads, command
line tools or applications. Application fallback paths are omitted; the receiving
Mac resolves the application by bundle identifier.

Choose **Import Action…** or drop the package on the import/export controls to
preview its source and dependency note. Nothing runs during preview or import.
Confirm **Import Disabled Action**, review dependencies, test, then explicitly
enable it. Every import receives a fresh identifier. Existing actions and script
files are preserved; conflicting names receive a numbered suffix. Embedded scripts
are installed in a new private subdirectory under the Actions folder.

Version 1 packages are limited to 2 MB, each embedded UTF-8 script to 500 KB, and
dependency notes to 16 KB. Missing assets, unsafe asset paths, unexpected assets,
symbolic-link package/script files and unsupported versions are rejected. A failed
manifest save rolls back the newly installed assets. Keep the original package
when moving an action to another Mac. Do not hand-edit file references to absolute
paths inside a package; export embeds them as portable asset names.
