# Plan 001: Action type picker can no longer delete actions or create always-failing ones

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 2e59370..HEAD -- Apps/Settings/Sources/Features/SettingsRootView.swift Packages/FinderActionsCore/Sources/Models/Action.swift Packages/FinderActionsCore/Sources/OpenWith/OpenWithConfiguration.swift Tests/FinderActionsCoreTests/OpenWithActionsTests.swift`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: bug
- **Planned at**: commit `2e59370`, 2026-10-02

## Why this matters

In Settings → Actions, the "Action Type" picker offers **Terminal** and **Built-in**. Picking **Terminal** for a custom action instantly and silently deletes that action (including any inline script the user wrote), because every save strips all `.terminal`-type actions from the manifest. Picking **Built-in** produces an action that appears in Finder but always fails with "not implemented in P0". After this plan, the picker only offers types that the save path preserves and the executor can run, and a unit test pins the invariant so it can't regress.

## Current state

Files:
- `Apps/Settings/Sources/Features/SettingsRootView.swift` — SwiftUI settings (1,389 lines). The picker is at lines 432–438; the binding that saves on every edit is at lines 212–220.
- `Packages/FinderActionsCore/Sources/Models/Action.swift` — `ActionType` enum (lines 5–11).
- `Packages/FinderActionsCore/Sources/OpenWith/OpenWithConfiguration.swift` — `OpenWithActions.baseManifest` (lines 156–165) strips terminal actions.
- `Tests/FinderActionsCoreTests/OpenWithActionsTests.swift` — existing tests for `OpenWithActions`; add the regression test here.

Picker (`SettingsRootView.swift:432-438`):
```swift
Picker("", selection: $action.type) {
    Text("Shell Script").tag(ActionType.shell)
    Text("Application").tag(ActionType.application)
    Text("Terminal").tag(ActionType.terminal)
    Text("AppleScript").tag(ActionType.appleScript)
    Text("Built-in").tag(ActionType.builtin)
}
```

Every edit saves immediately (`SettingsRootView.swift:212-220`):
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

`AppState.saveManifest()` (`Apps/Settings/Sources/App/AppState.swift:104-108`) calls `OpenWithActions.baseManifest(from:)`, which does (`OpenWithConfiguration.swift:156-165`):
```swift
public static func baseManifest(from manifest: ActionManifest) -> ActionManifest {
    var result = manifest
    result.version = 2
    result.actions.removeAll { action in
        action.type == .terminal
            || obsoleteBuiltInIds.contains(action.id)
            || action.id.hasPrefix("open-with.")
    }
    return result
}
```
Terminal actions are intentionally generated from Settings → Applications (one "Open in Terminal" item), so manifest actions must never be `.terminal`. That design is correct; only the picker is wrong.

`.builtin` in the executor (`Apps/Shared/Sources/Execution/ActionExecutor.swift:82-87`) always returns failure "not implemented in P0".

`ActionType` (`Action.swift:5-11`):
```swift
public enum ActionType: String, Codable, Sendable, CaseIterable {
    case application
    case shell
    case terminal
    case appleScript
    case builtin
}
```

Conventions: Core uses Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`). Pattern: `Tests/FinderActionsCoreTests/OpenWithActionsTests.swift`. Doc comments use `///`.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Core tests | `./Scripts/test.sh` | last line `Test run with N tests in M suites passed` |
| App build (Debug) | `./Scripts/dev.sh` | ends with `Dependency boundary verified: …` then `Debug app: …` |

Note: `dev.sh` runs `xcodegen`, which regenerates `FinderActions.xcodeproj/project.pbxproj`. This plan adds no files under `Apps/` or `Extensions/`, so if `git status` shows the pbxproj modified afterwards, restore it: `git checkout -- FinderActions.xcodeproj/project.pbxproj`.

## Scope

**In scope**:
- `Packages/FinderActionsCore/Sources/Models/Action.swift`
- `Apps/Settings/Sources/Features/SettingsRootView.swift` (picker only, lines ~432–438)
- `Tests/FinderActionsCoreTests/OpenWithActionsTests.swift`

**Out of scope**:
- `OpenWithActions.baseManifest` — stripping `.terminal` is the intended invariant; do not change it.
- `ActionExecutor`'s `.builtin` case and the `ActionType` enum cases — existing manifests may contain `builtin`; decoding must keep working.
- The binding at `SettingsRootView.swift:212-220` — plan 002 changes it.

## Git workflow

- Branch: `advisor/001-safe-action-type-picker`
- Conventional commits, matching history (e.g. `fix(settings): resolve titlebar toolbar layout and sidebar truncation`). Suggested: `fix(settings): stop action type picker from deleting actions`.
- Do NOT push or open a PR unless instructed.

## Steps

### Step 1: Add the user-assignable type list to Core

In `Action.swift`, directly after the `ActionType` enum, add:
```swift
public extension ActionType {
    /// Types a user may assign to a manifest action in Settings.
    /// `.terminal` actions are generated from Open With settings and are stripped
    /// from the manifest on save; `.builtin` has no executor yet.
    static let userAssignable: [ActionType] = [.shell, .application, .appleScript]
}
```
**Verify**: `./Scripts/test.sh` → all existing tests pass.

### Step 2: Add the regression test

In `OpenWithActionsTests.swift`, add a test inside the existing suite:
```swift
@Test func baseManifestKeepsEveryUserAssignableType() {
    let actions = ActionType.userAssignable.enumerated().map { index, type in
        ActionDefinition(id: "user.action.\(index)", name: "A\(index)", type: type)
    }
    let result = OpenWithActions.baseManifest(from: ActionManifest(actions: actions))
    #expect(result.actions.map(\.id) == actions.map(\.id))
    #expect(!ActionType.userAssignable.contains(.terminal))
    #expect(!ActionType.userAssignable.contains(.builtin))
}
```
**Verify**: `./Scripts/test.sh` → passes, test count is one higher than before.

### Step 3: Restrict the picker

Replace the picker body in `SettingsRootView.swift` so that:
- Terminal is never offered.
- Built-in is offered **only** when the action is already `.builtin` (so an existing manifest entry still renders a valid selection).

Target shape:
```swift
Picker("", selection: $action.type) {
    Text("Shell Script").tag(ActionType.shell)
    Text("Application").tag(ActionType.application)
    Text("AppleScript").tag(ActionType.appleScript)
    if action.type == .builtin {
        Text("Built-in").tag(ActionType.builtin)
    }
}
```
Leave the `switch action.type { … case .terminal: terminalConfigEditor … }` below it untouched (it must stay exhaustive).

**Verify**:
- `grep -n 'tag(ActionType.terminal)' Apps/Settings/Sources/Features/SettingsRootView.swift` → no output.
- `./Scripts/dev.sh` → ends with `Debug app: …`.

## Test plan

- New: `baseManifestKeepsEveryUserAssignableType` (step 2) — guards the deletion bug.
- Manual (record result in report): launch the Debug app, open Settings → Actions, select a custom action, open the Action Type menu → only Shell Script / Application / AppleScript appear.

## Done criteria

- [ ] `./Scripts/test.sh` passes with one more test than before
- [ ] `./Scripts/dev.sh` succeeds
- [ ] `grep -n 'tag(ActionType.terminal)' Apps/Settings/Sources/Features/SettingsRootView.swift` returns nothing
- [ ] `grep -n 'userAssignable' Packages/FinderActionsCore/Sources/Models/Action.swift` returns a match
- [ ] `git status` shows only in-scope files modified
- [ ] `plans/README.md` status row updated

## STOP conditions

- The picker excerpt doesn't match (e.g. it already iterates a list) — report.
- `baseManifest` no longer strips `.terminal` — the premise changed; report.
- Swift reports the picker selection as invalid at runtime for `.builtin` actions despite the conditional tag — report instead of redesigning.

## Maintenance notes

- When a built-in action is actually implemented (see direction notes in `plans/README.md`), add `.builtin` to `userAssignable` and give it an editor.
- Any new `ActionType` must make a conscious decision about `userAssignable`; the test only covers the current list.
