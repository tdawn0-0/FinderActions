# Plan 010: Host and Settings share one configuration bootstrap; dead state removed

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 2e59370..HEAD -- Apps/Host/Sources/App/HostRuntimeState.swift Apps/Host/Sources/App/AppDelegate.swift Apps/Settings/Sources/App/AppState.swift Apps/Shared/Sources/Configuration`
> Plans 002 and 007 are expected to have touched `AppState.swift` (debounced save; `executeForTesting` log field). Re-read the file and confirm the excerpts below for the regions this plan edits; mismatch → STOP.

## Status

- **Priority**: P3
- **Effort**: M
- **Risk**: MED
- **Depends on**: plans/002-debounce-manifest-saves.md, plans/007-log-script-output.md (both edit `AppState.swift`; land them first to avoid conflicts)
- **Category**: tech-debt
- **Planned at**: commit `2e59370`, 2026-10-02

## Why this matters

The Host (`HostRuntimeState`) and the Settings helper (`AppState`) each carry their own copy of: first-launch seeding, manifest migration to its "base" form, Open With settings load/save (same preferences key string duplicated), and bundled-script seeding (~80 duplicated lines). Both processes run this on launch against the same files, so any drift (e.g. a migration added to one copy only) silently produces different manifests depending on which process starts first. There is also dead state: `launchAtLogin`, `didStart`, `lastSnapshot` and the unused `executeForTesting` in Settings; `lastSnapshot`/`setLastSnapshot` in the Host are written but never read. After this plan one shared type owns configuration persistence and both apps call it.

## Current state

Shared code that compiles into **both** app targets lives in `Apps/Shared/Sources/` (see `project.yml`: both `FinderActions` and `FinderActionsSettings` list `- path: Apps/Shared/Sources`). Exemplar: `Apps/Shared/Sources/Configuration/AppPreferences.swift`:
```swift
/// Reads and writes the Host's preferences domain explicitly so the nested
/// Settings app shares values without requiring an App Group or migration.
@MainActor
enum AppPreferences {
    private static let applicationID = IPCConstants.hostBundleId as CFString
    static func bool(forKey key: String) -> Bool { … }
    static func data(forKey key: String) -> Data? { … }
    static func object(forKey key: String) -> Any? { … }
    static func set(_ value: Any, forKey key: String) { … }
}
```

Host — `Apps/Host/Sources/App/HostRuntimeState.swift`:
```swift
// line 9
private let openWithDefaultsKey = "openWithSettings.v2"
// line 14
private(set) var lastSnapshot: MenuSnapshot?
// lines 37-54
func bootstrap() {
    try? store.ensureDirectories()
    if FileManager.default.fileExists(atPath: store.fileURL.path) {
        let storedManifest = store.loadOrEmpty()
        manifest = OpenWithActions.baseManifest(from: storedManifest)
        if manifest != storedManifest {
            try? store.save(manifest)
        }
        openWithSettings = loadOpenWithSettings()
    } else {
        manifest = DefaultActions.manifest()
        openWithSettings = .defaults
        try? store.save(manifest)
        saveOpenWithSettings()
    }
    seedMissingScripts()
    loadPreferences()
}
// lines 58-62: reloadConfiguration() uses baseManifest(from: store.loadOrEmpty()) + loadOpenWithSettings() + loadPreferences()
// lines 81-83: func setLastSnapshot(_ snapshot: MenuSnapshot) { lastSnapshot = snapshot }
// lines 89-95: loadOpenWithSettings() — AppPreferences.data(forKey:) + JSONDecoder, fallback .defaults
// lines 97-100: saveOpenWithSettings() — JSONEncoder + AppPreferences.set
// lines 102-122: seedMissingScripts() — writes DefaultActions.bundledScripts() files that don't exist (0o755), then copies Bundle.main "BundledActions/*.zsh" that don't exist (0o755)
```
`Apps/Host/Sources/App/AppDelegate.swift:91` calls `appState.setLastSnapshot(snapshot)` inside `publishSnapshot()`.

Settings — `Apps/Settings/Sources/App/AppState.swift` (line numbers at `2e59370`; plan 002 adds a few lines near `didStart`):
```swift
// line 11: var lastSnapshot: MenuSnapshot?          (never read anywhere)
// line 19: var launchAtLogin: Bool = false           (never read anywhere)
// line 26: private(set) var didStart = false         (never read anywhere)
// line 27: private let openWithDefaultsKey = "openWithSettings.v2"
// lines 42-65: bootstrap() — loads openWith first, then: if manifest exists → load, baseManifest, save if changed; else seedDefaults(); then seedMissingScripts(); logs; refreshExtensionStatus(); onboarding flag; notificationsEnabled
// lines 67-74: seedDefaults() — DefaultActions.manifest(), openWith = .defaults, save both, seedMissingScripts(), onManifestChanged?()   (also called by a "reset" button at SettingsRootView.swift:1202)
// lines 76-102: seedMissingScripts() — identical logic to the Host's
// lines 201-215: executeForTesting(...) — no callers (grep confirms)
// lines 326-332: loadOpenWithSettings() — identical to Host's
// lines 334-339: saveOpenWithSettings() — identical to Host's, plus onManifestChanged?()
```
Behavioral equivalence note: when `manifest.json` is missing, both processes reset Open With settings to `.defaults` and save them. When it exists, both load Open With settings from preferences. The shared version must preserve exactly this.

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Core tests | `./Scripts/test.sh` | all pass |
| App build | `./Scripts/dev.sh` | `Debug app: …` and `Dependency boundary verified…` |

This plan **adds a file under `Apps/Shared/Sources/`**, so `xcodegen` will legitimately modify `FinderActions.xcodeproj/project.pbxproj` — commit that change (verify the diff only adds the new file to both app targets: `git diff FinderActions.xcodeproj/project.pbxproj | grep "^+" | grep -c SharedConfiguration` → ≥ 2).

## Scope

**In scope**:
- `Apps/Shared/Sources/Configuration/SharedConfiguration.swift` (create)
- `Apps/Host/Sources/App/HostRuntimeState.swift`
- `Apps/Host/Sources/App/AppDelegate.swift` (remove the `setLastSnapshot` call only)
- `Apps/Settings/Sources/App/AppState.swift`
- `FinderActions.xcodeproj/project.pbxproj` (regenerated by xcodegen)

**Out of scope**: `FinderActionsCore` (do not move this into the package — it depends on `AppPreferences`, which is app-side); `SettingsRootView.swift`; the bundled-script *contents* (note: `DefaultActions.bundledScripts()` and `BundledActions/*.zsh` define the same two filenames with slightly different bodies; the Swift strings are written first and therefore win — preserve that order, do not "fix" it here).

## Git workflow
Branch `advisor/010-shared-configuration`; commits `refactor(config): share configuration bootstrap between Host and Settings`, `chore: remove unused app state`. Do not push.

## Steps

### Step 1: Create `SharedConfiguration`
`Apps/Shared/Sources/Configuration/SharedConfiguration.swift`:
```swift
import Foundation
import FinderActionsCore

/// Configuration persistence shared by the Host and the Settings helper, so both
/// processes seed, migrate and read the same files identically.
@MainActor
enum SharedConfiguration {
    static let openWithDefaultsKey = "openWithSettings.v2"

    /// Seeds defaults on first launch; otherwise migrates the stored manifest to
    /// its base form (Open With actions are generated, never stored). Always
    /// restores missing bundled scripts.
    static func bootstrap(store: ManifestStore) -> (manifest: ActionManifest, openWith: OpenWithSettings) {
        try? store.ensureDirectories()
        let result: (manifest: ActionManifest, openWith: OpenWithSettings)
        if FileManager.default.fileExists(atPath: store.fileURL.path) {
            let stored = store.loadOrEmpty()
            let base = OpenWithActions.baseManifest(from: stored)
            if base != stored {
                try? store.save(base)
            }
            result = (base, loadOpenWithSettings())
        } else {
            result = resetToDefaults(store: store)
        }
        seedMissingScripts(store: store)
        return result
    }

    /// Writes factory defaults for both the manifest and Open With settings.
    @discardableResult
    static func resetToDefaults(store: ManifestStore) -> (manifest: ActionManifest, openWith: OpenWithSettings) {
        let manifest = DefaultActions.manifest()
        try? store.save(manifest)
        saveOpenWithSettings(.defaults)
        return (manifest, .defaults)
    }

    static func loadOpenWithSettings() -> OpenWithSettings { /* move body from HostRuntimeState */ }
    static func saveOpenWithSettings(_ settings: OpenWithSettings) { /* move body */ }
    static func seedMissingScripts(store: ManifestStore) { /* move body from HostRuntimeState.seedMissingScripts, using store.actionsDirectoryURL */ }
}
```
Fill the three bodies by moving the Host versions verbatim (replace `openWithSettings` with the parameter, `store` with the parameter).

**Verify**: `./Scripts/dev.sh` builds (both copies still exist at this point; that's fine).

### Step 2: Switch the Host
In `HostRuntimeState`:
- `bootstrap()` becomes:
```swift
func bootstrap() {
    (manifest, openWithSettings) = SharedConfiguration.bootstrap(store: store)
    loadPreferences()
}
```
- `reloadConfiguration()`: replace `loadOpenWithSettings()` with `SharedConfiguration.loadOpenWithSettings()`.
- Delete `openWithDefaultsKey`, `loadOpenWithSettings`, `saveOpenWithSettings`, `seedMissingScripts`, `lastSnapshot`, `setLastSnapshot`.
- In `AppDelegate.publishSnapshot()` delete `appState.setLastSnapshot(snapshot)`.

**Verify**: `./Scripts/dev.sh` builds; `grep -n "seedMissingScripts\|openWithDefaultsKey\|lastSnapshot" Apps/Host -r` → no output.

### Step 3: Switch Settings
In `AppState`:
- `bootstrap()`: replace the manifest/openWith block (from `try? store.ensureDirectories()` through `seedMissingScripts()`) with `(manifest, openWithSettings) = SharedConfiguration.bootstrap(store: store)`. Keep the remaining lines (logs, `refreshExtensionStatus()`, onboarding, `notificationsEnabled`) unchanged and in the same order.
- `seedDefaults()` becomes:
```swift
func seedDefaults() {
    (manifest, openWithSettings) = SharedConfiguration.resetToDefaults(store: store)
    SharedConfiguration.seedMissingScripts(store: store)
    onManifestChanged?()
}
```
- `saveOpenWithSettings()` becomes:
```swift
private func saveOpenWithSettings() {
    SharedConfiguration.saveOpenWithSettings(openWithSettings)
    onManifestChanged?()
}
```
- Delete `loadOpenWithSettings()`, `seedMissingScripts()`, `openWithDefaultsKey`, `lastSnapshot`, `launchAtLogin`, `didStart` (and its doc comment), and `executeForTesting(...)`.

**Verify**: `./Scripts/dev.sh` builds; `grep -rn "launchAtLogin\|didStart\|executeForTesting\|openWithDefaultsKey" Apps/Settings` → no output; `grep -rn '"openWithSettings.v2"' Apps` → exactly 1 match (in `SharedConfiguration.swift`).

### Step 4: Behavior check (manual, report results)
Back up then test both paths:
1. `cp -R ~/Library/Application\ Support/FinderActions /tmp/fa-backup` (if it exists).
2. Fresh install path: `mv ~/Library/Application\ Support/FinderActions /tmp/fa-moved`, launch the Debug app → `manifest.json` recreated with `copy-path`/`copy-name`, `Actions/` contains both scripts with mode 755 (`ls -l`). `--dump-actions` check: `./build/DerivedData/Debug/Build/Products/Debug/FinderActions.app/Contents/MacOS/FinderActions --dump-actions` prints `ENABLED_ACTIONS=` including `copy-path,copy-name,open-with.terminal,open-with.editor.vscode` (order may vary).
3. Restore: quit app, `rm -rf ~/Library/Application\ Support/FinderActions && mv /tmp/fa-moved ~/Library/Application\ Support/FinderActions` (or from `/tmp/fa-backup`).
4. Settings → General "reset to defaults" button (the one calling `state.seedDefaults()`) still resets actions and Open With settings.

## Test plan
No unit tests (app-side `@MainActor` code using `CFPreferences`). Verification is the build plus the manual behavior check above, including `--dump-actions`.

## Done criteria
- [ ] `./Scripts/test.sh` and `./Scripts/dev.sh` succeed
- [ ] grep checks in steps 2–3 pass
- [ ] `wc -l Apps/Host/Sources/App/HostRuntimeState.swift Apps/Settings/Sources/App/AppState.swift` shows both files shorter than at `2e59370` (122 and 363 lines respectively)
- [ ] Manual behavior check reported; user data restored
- [ ] Only in-scope files changed; `plans/README.md` updated

## STOP conditions
- The two bootstrap copies differ in behavior beyond what "Current state" describes (e.g. a migration exists in only one) — STOP and report which; don't pick one silently.
- `AppPreferences` is no longer in `Apps/Shared` or is no longer `@MainActor` — report.
- The pbxproj diff touches anything besides adding `SharedConfiguration.swift` — revert it and report.
- You cannot back up/restore `~/Library/Application Support/FinderActions` safely — skip step 4 and report; do not delete user data without a backup.

## Maintenance notes
- All future manifest migrations go in `SharedConfiguration.bootstrap` only.
- Plan 009/006 may later change IPC; unaffected.
- Follow-up (deferred): decide whether `BundledActions/*.zsh` or `DefaultActions.bundledScripts()` is the single source of truth for default scripts and delete the other.
