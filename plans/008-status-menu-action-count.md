# Plan 008: The menu bar's "N actions ready" count matches what Finder shows

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 2e59370..HEAD -- Apps/Host/Sources/App/StatusMenuController.swift Apps/Host/Sources/App/HostRuntimeState.swift`
> Any change → compare with the excerpts; mismatch → STOP.

## Status

- **Priority**: P3
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: bug
- **Planned at**: commit `2e59370`, 2026-10-02

## Why this matters

On a fresh install Finder shows four FinderActions items (Open in Terminal, Open in Visual Studio Code, Copy Path, Copy Filename), but the menu bar summary says "2 actions ready in Finder". The count reads the *base* manifest, which deliberately excludes the generated Open With actions (terminal + editors). Small, but it is the first number a new user sees and it contradicts the README's defaults table.

## Current state

- `Apps/Host/Sources/App/StatusMenuController.swift:22-28`:
```swift
func menuWillOpen(_ menu: NSMenu) {
    let enabledCount = Int64(appState.manifest.actions.lazy.filter(\.enabled).count)
    summaryItem.title = String.localizedStringWithFormat(
        NSLocalizedString("%lld actions ready in Finder", comment: "Enabled action count"),
        enabledCount
    )
}
```
- `Apps/Host/Sources/App/HostRuntimeState.swift:20-22` — the composed manifest (what `SnapshotBuilder` publishes to Finder in `AppDelegate.publishSnapshot`):
```swift
var effectiveManifest: ActionManifest {
    OpenWithActions.compose(baseManifest: manifest, settings: openWithSettings)
}
```

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| App build | `./Scripts/dev.sh` | `Debug app: …`; restore pbxproj if modified: `git checkout -- FinderActions.xcodeproj/project.pbxproj` |
| Core tests | `./Scripts/test.sh` | all pass |

## Scope

**In scope**: `Apps/Host/Sources/App/StatusMenuController.swift` (line 23 only).
**Out of scope**: localization strings (`Localizable.xcstrings` — the format key is unchanged), `HostRuntimeState`.

## Git workflow
Branch `advisor/008-status-menu-count`; commit `fix(host): count Open With actions in status menu summary`. Do not push.

## Steps

### Step 1: Count the effective manifest
Change line 23 to:
```swift
let enabledCount = Int64(appState.effectiveManifest.actions.lazy.filter(\.enabled).count)
```
**Verify**: `grep -n "effectiveManifest" Apps/Host/Sources/App/StatusMenuController.swift` → 1 match; `./Scripts/dev.sh` succeeds.

## Test plan
Manual: run the Debug app with default settings, click the hammer icon → "4 actions ready in Finder" (2 shell actions + 1 terminal + 1 editor). If you have customized settings, expected = enabled custom/default actions + 1 + number of selected editors.

## Done criteria
- [ ] `./Scripts/dev.sh` succeeds
- [ ] Only `StatusMenuController.swift` modified; `plans/README.md` updated

## STOP conditions
- `effectiveManifest` no longer exists on `HostRuntimeState` (e.g. renamed by plan 010) — use the equivalent composed-manifest accessor only if it is obviously the same thing; otherwise report.

## Maintenance notes
- Any other UI that counts "actions in Finder" should use the composed manifest, never the base one.
