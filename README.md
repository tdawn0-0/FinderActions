# FinderActions

Open-source **Finder right-click actions** for macOS.

**Architecture (方案 B):** non-sandbox **Host** (menu bar) is the sole executor; a **thin FinderSync** extension only renders a menu snapshot and forwards clicks. No Runner process, no security-scoped bookmark pipeline, no telemetry, no in-app purchase.

> Finder right-click script launcher — edit scripts as files, git them, share them.

## Requirements

- macOS 15+
- Xcode 16+ (to build)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Apple Developer Program membership (release only)

## Development

```bash
./Scripts/dev.sh          # generate the project and build Debug
./Scripts/test.sh         # run the Swift test suite
```

`dev.sh` generates `FinderActions.xcodeproj` from `project.yml`; treat the YAML file as the source of truth. You can then open the project in Xcode and run the **FinderActions** scheme.

## Release outside the Mac App Store

Releases use Developer ID signing, Hardened Runtime, Apple notarization, ticket stapling, and Gatekeeper validation.

```bash
./Scripts/setup-signing.sh  # once per development Mac
./Scripts/release.sh        # tested, signed, notarized release ZIP
```

Release artifacts are written to `build/releases/`. See [docs/releasing.md](docs/releasing.md) for credential setup, pipeline details, and troubleshooting.

Copy the built `FinderActions.app` to `/Applications` for everyday use (helps FinderSync registration).

On first launch, use the setup guide to add `/Applications/FinderActions.app` in
**System Settings → Privacy & Security → Full Disk Access**. This lets actions
work with protected locations without repeatedly selecting the same folders.
FinderActions can open the correct settings page and reveal its app bundle, but
macOS requires you to add and enable the app yourself.

### Headless check

```bash
# Same load path as the GUI — prints seeded action ids
open -W -a /path/to/FinderActions.app --args --dump-actions
# or after build:
./build/DerivedData/Debug/Build/Products/Debug/FinderActions.app/Contents/MacOS/FinderActions --dump-actions
```

### Core tests & shell harness

```bash
swift test
swift run ShellExecHarness /tmp/shell-exec.log
```

## Enable the Finder extension

1. Launch **FinderActions** (menu bar hammer icon).
2. Open **System Settings → Privacy & Security → Extensions → Added Extensions** (wording varies by macOS version) and enable **FinderActions**.
3. Right-click a file or folder in Finder.

### If the menu never appears (Sequoia+)

```bash
# Register the appex after installing the app
pluginkit -a "/Applications/FinderActions.app/Contents/PlugIns/FAFinderSync.appex"
pluginkit -e use -i com.finderactions.host.FinderSync
pluginkit -m -i com.finderactions.host.FinderSync

# Restart Finder
killall Finder
```

The Host **Extension** settings tab also links to System Settings and can restart Finder.

## Default actions and applications

Enabled by default (keep the menu small):

| Action | Type |
|--------|------|
| Open in Terminal | selected terminal |
| Copy Path | `shell` |
| Copy Filename | `shell` |
| Open in Visual Studio Code | selected editor |

Choose the terminal and one or more editors in **Settings → Applications**.
Finder always shows one generic **Open in Terminal** command; each selected editor
gets its own command. The built-in catalog covers common terminals and editors,
and **Choose Application…** supports any additional macOS `.app`.

## Write a shell action

Scripts live in:

```
~/Library/Application Support/FinderActions/Actions/
```

Manifest:

```
~/Library/Application Support/FinderActions/manifest.json
```

Example `compress.zsh`:

```bash
#!/bin/zsh
set -euo pipefail
# "$@"           selected paths (correct with spaces / Unicode / quotes)
# $FA_CWD        Finder container directory
# $FA_PATHS      newline-separated paths
# $FA_PATH_COUNT count
# $FA_CONTAINER  same as container
# $FA_ACTION_ID  action id

for f in "$@"; do
  # your tool here
  echo "got: $f"
done
```

Add a manifest entry:

```json
{
  "id": "compress",
  "name": "Compress",
  "type": "shell",
  "enabled": true,
  "sortIndex": 50,
  "icon": { "sfSymbol": "archivebox" },
  "showWhen": "always",
  "shell": {
    "interpreter": "/bin/zsh",
    "scriptFile": "compress.zsh"
  }
}
```

Save → Host republishes the menu snapshot. Use **Open Scripts Folder** from Settings or the menu bar menu.

Exit code `0` = success (first stdout line can appear in the notification). Non-zero = failure (stderr in logs).

## Architecture

```
Host (not sandboxed)          FinderSync (sandboxed, thin)
  config, scripts, logs   ←→    render snapshot menu only
  execute app/shell/term        forward actionId + paths
  publish menu snapshot         no Process / no script run
```

IPC uses `DistributedNotificationCenter` (JSON v1 payloads). Optional App Group / Application Support file caches the last snapshot for cold start.

See [docs/architecture.md](docs/architecture.md), [docs/ipc.md](docs/ipc.md), [docs/scripting.md](docs/scripting.md), [docs/troubleshooting.md](docs/troubleshooting.md).

## Privacy

- No telemetry, no account, no network client in Host
- Extension does not read file contents or upload paths
- Execution logs are local only (Settings → Logs → Clear)

## License

MIT — see [LICENSE](LICENSE).

## Chinese docs

[README.zh-Hans.md](README.zh-Hans.md)
