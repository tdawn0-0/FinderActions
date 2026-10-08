# Plan 002: Settings edits are debounced instead of saving and broadcasting on every keystroke

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 2e59370..HEAD -- Apps/Settings/Sources/App/AppState.swift Apps/Settings/Sources/App/SettingsAppDelegate.swift Apps/Settings/Sources/Features/SettingsRootView.swift`
> Plan 001 is expected to have changed `SettingsRootView.swift` (picker only). Any other change: compare the excerpts below; mismatch → STOP.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: plans/001-safe-action-type-picker.md (same file region; avoid conflicts)
- **Category**: perf
- **Planned at**: commit `2e59370`, 2026-10-02

## Why this matters

The action inspector binds every field — including the inline script `TextEditor` — through a setter that calls `saveManifest()`. Each keystroke therefore (1) rewrites `manifest.json`, (2) posts a distributed notification, (3) makes the resident Host reload config and rebuild/broadcast the menu snapshot, and (4) makes the Finder extension re-decode and rewrite its cache file. The product promises a featherweight background app; typing a 200-character script costs ~800 cross-process round-trips. After this plan, edits update in-memory state immediately and persist ~0.4 s after the last change, with a guaranteed flush on quit.

## Current state

- `Apps/Settings/Sources/Features/SettingsRootView.swift:212-220` — the binding:
```swift
ActionDetailInspectorView(
    action: Binding(
        get: { state.manifest.actions[idx] },
        set: {
            state.manifest.actions[idx] = $0
            state.saveManifest()
        }
    )
)
```
- `Apps/Settings/Sources/App/AppState.swift:104-108`:
```swift
func saveManifest() {
    manifest = OpenWithActions.baseManifest(from: manifest)
    try? store.save(manifest)
    onManifestChanged?()
}
```
`AppState` is `@Observable @MainActor final class`. Other callers of `saveManifest()` (`setEnabled`, `moveAction`, `updateAction`, `addNewAction`, `duplicateAction`, `deleteAction`, and `SettingsRootView.swift:219` area list actions) are discrete clicks and should keep saving immediately.
- `Apps/Settings/Sources/App/SettingsAppDelegate.swift` — `applicationShouldTerminateAfterLastWindowClosed` returns `true`; there is no `applicationWillTerminate` yet. `onManifestChanged` (set in `applicationDidFinishLaunching`) posts `IPCConstants.configurationChangedNotification`.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Core tests | `./Scripts/test.sh` | `Test run with N tests … passed` |
| App build | `./Scripts/dev.sh` | ends with `Debug app: …` |

`dev.sh` regenerates `FinderActions.xcodeproj/project.pbxproj`; this plan adds no files, so restore it if modified: `git checkout -- FinderActions.xcodeproj/project.pbxproj`.

## Scope

**In scope**: `Apps/Settings/Sources/App/AppState.swift`, `Apps/Settings/Sources/App/SettingsAppDelegate.swift`, `Apps/Settings/Sources/Features/SettingsRootView.swift` (the binding at ~212–220 only).

**Out of scope**: Host code (`Apps/Host/**`), `ManifestStore`, the IPC notification names, other `saveManifest()` callers.

## Git workflow

- Branch `advisor/002-debounce-manifest-saves`; commit e.g. `perf(settings): debounce manifest saves from the action inspector`. Do not push.

## Steps

### Step 1: Add a debounced save to `AppState`

In `AppState.swift` add a stored property next to `didStart`:
```swift
/// Pending debounced save from continuous edits (typing in the inspector).
private var pendingSave: Task<Void, Never>?
```
Add methods after `saveManifest()`:
```swift
/// Persist after edits settle so typing does not rewrite the manifest and
/// wake the Host on every keystroke.
func scheduleManifestSave() {
    pendingSave?.cancel()
    pendingSave = Task { [weak self] in
        try? await Task.sleep(for: .milliseconds(400))
        guard !Task.isCancelled else { return }
        self?.saveManifest()
    }
}

/// Write any pending debounced edit now (e.g. before the process exits).
func flushPendingManifestSave() {
    guard pendingSave != nil else { return }
    saveManifest()
}
```
At the top of `saveManifest()` add:
```swift
pendingSave?.cancel()
pendingSave = nil
```
(so an immediate save supersedes a pending one).

**Verify**: `./Scripts/dev.sh` builds.

### Step 2: Use it from the inspector binding

In `SettingsRootView.swift` change the setter to:
```swift
set: {
    state.manifest.actions[idx] = $0
    state.scheduleManifestSave()
}
```
**Verify**: `grep -n "scheduleManifestSave" Apps/Settings/Sources/Features/SettingsRootView.swift` → exactly one match.

### Step 3: Flush on quit

In `SettingsAppDelegate.swift` add:
```swift
func applicationWillTerminate(_ notification: Notification) {
    appState.flushPendingManifestSave()
}
```
**Verify**: `./Scripts/dev.sh` builds.

## Test plan

Settings is not covered by `swift test` (it is an Xcode app target). Manual check, report results:
1. Run the Debug app, open Settings → Actions, select a shell action with an inline script.
2. In Terminal: `fswatch -1 ~/Library/Application\ Support/FinderActions/manifest.json` is optional; simpler: `stat -f %m ~/Library/Application\ Support/FinderActions/manifest.json` before and ~1 s after typing a word → modification time changes once after typing stops (not required to count writes exactly).
3. Type, then immediately close the window (app quits) → reopen Settings → edit is present.

## Done criteria

- [ ] `./Scripts/dev.sh` and `./Scripts/test.sh` succeed
- [ ] `grep -n "state.saveManifest()" Apps/Settings/Sources/Features/SettingsRootView.swift` no longer shows the inspector binding setter (other call sites may remain)
- [ ] `grep -n "applicationWillTerminate" Apps/Settings/Sources/App/SettingsAppDelegate.swift` → 1 match
- [ ] Only in-scope files modified; `plans/README.md` updated

## STOP conditions

- Plan 001 not yet applied and the picker region differs from both the old and new shapes — report.
- Swift 6 concurrency errors about capturing `self` in the `Task` that you cannot resolve by the `[weak self]` pattern shown — report rather than adding `nonisolated(unsafe)`.

## Maintenance notes

- Any new continuous-edit control (sliders, text fields) should use `scheduleManifestSave()`; discrete actions keep `saveManifest()`.
- The "Test Run" button executes the in-memory `action`, so it is unaffected by the delay.
- If Settings ever stops terminating on last-window-close, also flush on window close.
