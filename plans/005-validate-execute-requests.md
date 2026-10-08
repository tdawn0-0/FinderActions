# Plan 005: The Host re-validates every execute request before running it

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 2e59370..HEAD -- Apps/Host/Sources/IPC/IPCServer.swift Packages/FinderActionsCore/Sources/IPC Packages/FinderActionsCore/Sources/Matching Tests/FinderActionsCoreTests`
> Plan 003 is expected to have rewritten `IPCServer.processJSON` (shown below in its post-003 form). Anything else → compare; mismatch → STOP.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: MED
- **Depends on**: plans/003-process-runner-off-main.md
- **Category**: security
- **Planned at**: commit `2e59370`, 2026-10-02

## Why this matters

The Finder extension sends clicks to the Host as JSON over `DistributedNotificationCenter` (`com.finderactions.extension.execute`). Distributed notifications carry **no sender identity**: any process in the user session can post one. The Host is not sandboxed and the onboarding asks users to grant it **Full Disk Access**, and it runs any *enabled* action against whatever `paths` the JSON names — without checking that the paths exist, are absolute, or match the action's own `showWhen`/`extRules` filters. That makes the Host a confused deputy: a process without Full Disk Access can have the Host run the user's scripts (which may move, delete, or upload files) on paths of its choosing, including paths beginning with `-` that user scripts may parse as options.

This plan is the **short-term hardening**: it does not authenticate the sender (that requires a transport change — see plan 006), but it limits requests to what a genuine Finder click could have produced. A request is rejected unless: version is 1; path count is bounded; every path is absolute and exists; the action exists, is enabled, and its `showWhen`/`extRules` accept the selection.

## Current state

- `Apps/Host/Sources/IPC/IPCServer.swift` — after plan 003, `processJSON` looks like:
```swift
private func processJSON(_ json: String) {
    let request: ExecuteRequest
    do {
        request = try JSONCoding.decode(ExecuteRequest.self, from: json)
    } catch {
        appState.recordLog(ExecLogEntry(actionId: "?", success: false,
            summary: "Bad execute payload: \(error.localizedDescription)", paths: []))
        return
    }
    guard requestDedupe.accept(request.requestId) else { return }

    let executor = appState.executor
    let manifest = appState.effectiveManifest
    // A user script can run for minutes; never block the resident main thread.
    Task.detached(priority: .userInitiated) { [weak self] in
        let result = executor.execute(request: request, manifest: manifest)
        await self?.finish(request: request, result: result)
    }
}
```
- `Packages/FinderActionsCore/Sources/Models/Snapshot.swift:69-92` — `ExecuteRequest { v: Int; requestId: String; actionId: String; paths: [String]; containerPath: String?; menuKind: MenuKind? }`.
- `Packages/FinderActionsCore/Sources/Matching/ShowWhenMatcher.swift` — `SelectionContext(paths:isDirectory:)` and `ShowWhenMatcher.shouldShow(showWhen:extRules:context:) -> Bool`. This is exactly what the extension uses to build the menu (`SnapshotBuilder.filter`).
- How the extension builds requests (`Extensions/FinderSync/FinderSync.swift:87-98`): `paths` = selected item paths, or `[containerPath]` when nothing is selected (right-click on folder background). The menu itself was filtered with an **empty** selection context in that case. Check (already reasoned through; the test in step 2 pins it): for every `ShowWhen` and `ExtRules`, an action visible for an empty selection is also accepted for `[containerPath]` where the container is a directory, except `.single`/`.multiple` which compare counts (0→1 still passes `.single`; `.multiple` is hidden for both). So validating against the request's actual paths is consistent with what the menu showed.
- `ActionExecutor.execute(request:manifest:)` (Apps/Shared) already rejects unknown/disabled actions; keep that, the validator duplicates it intentionally so rejection happens before any work.
- Conventions: Core is Foundation-only; pure policy types live as `public enum` with static functions (exemplar: `ExecuteDelivery` in `Packages/FinderActionsCore/Sources/IPC/ExecuteDelivery.swift`). Tests use Swift Testing (exemplar `Tests/FinderActionsCoreTests/ExecuteDeliveryTests.swift`).

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Core tests | `./Scripts/test.sh` | all pass |
| Filtered | `swift test --package-path . --scratch-path build/SwiftPM --filter ExecuteRequestValidation` | all pass |
| App build | `./Scripts/dev.sh` | ends with `Debug app: …` (restore pbxproj if modified: `git checkout -- FinderActions.xcodeproj/project.pbxproj`) |

## Scope

**In scope**:
- `Packages/FinderActionsCore/Sources/IPC/ExecuteRequestValidator.swift` (create)
- `Tests/FinderActionsCoreTests/ExecuteRequestValidationTests.swift` (create)
- `Apps/Host/Sources/IPC/IPCServer.swift` (`processJSON` only)
- `docs/ipc.md` (add a short "Request validation" section)

**Out of scope**: the transport (`DistributedNotificationCenter`) — plan 006; `FinderSync.swift`; `ExecuteRequest` shape (no new fields); `ActionExecutor`.

## Git workflow

- Branch `advisor/005-validate-execute-requests`; commit e.g. `fix(host): validate execute requests against action filters`. Do not push.

## Steps

### Step 1: Create the validator

`ExecuteRequestValidator.swift`:
```swift
import Foundation

public enum ExecuteRejection: Error, Equatable, Sendable {
    case unsupportedVersion(Int)
    case tooManyPaths(Int)
    case pathNotAbsolute(String)
    case pathMissing(String)
    case unknownAction(String)
    case actionDisabled(String)
    case selectionNotAllowed(String)

    public var summary: String { … one short English sentence per case, e.g. "Rejected request: path is not absolute" … }
}

/// Host-side check that an execute request is one a real Finder click could
/// have produced. Distributed notifications are unauthenticated, so the Host
/// must not trust the extension's filtering.
public enum ExecuteRequestValidator {
    public static let maxPaths = 10_000

    /// `fileInfo` returns nil when the path does not exist, else whether it is a directory.
    public static func validate(
        _ request: ExecuteRequest,
        manifest: ActionManifest,
        fileInfo: (String) -> Bool? = ExecuteRequestValidator.diskFileInfo
    ) -> Result<ActionDefinition, ExecuteRejection>

    public static func diskFileInfo(_ path: String) -> Bool? {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) else { return nil }
        return isDir.boolValue
    }
}
```
Rules, checked in this order:
1. `request.v == 1` else `.unsupportedVersion`.
2. `request.paths.count <= maxPaths` else `.tooManyPaths`.
3. For each of `request.paths` plus `request.containerPath` (if non-nil and non-empty): must start with `"/"` else `.pathNotAbsolute`; `fileInfo(path)` must be non-nil else `.pathMissing`. (Paths starting with `/` cannot start with `-`, which closes option-injection into scripts.)
4. Action with `id == request.actionId` in `manifest.actions` else `.unknownAction`; must be `enabled` else `.actionDisabled`.
5. Build `SelectionContext(paths: request.paths, isDirectory: request.paths.map { fileInfo($0) ?? false })` and require `ShowWhenMatcher.shouldShow(showWhen: action.showWhen, extRules: action.extRules, context:)` else `.selectionNotAllowed`.
6. Return `.success(action)`.

Do not include the offending path in `summary` strings beyond what the log already stores (logs record `paths` separately).

**Verify**: `./Scripts/test.sh` compiles and passes.

### Step 2: Tests

`ExecuteRequestValidationTests.swift`, `@Suite("Execute request validation")`. Use an injected `fileInfo` closure backed by a dictionary (`["/d": true, "/d/a.txt": false, "/d/b.png": false]`) — no disk access. Manifest with actions: `always` (enabled, `.always`), `files` (`.filesOnly`), `png` (`extRules: ExtRules(pathExtensions: ["png"])`), `off` (enabled: false). Cases:
- accepts a genuine request (`always`, paths `["/d/a.txt"]`, container `/d`)
- rejects `v: 2`
- rejects relative path `"a.txt"` and a path starting with `-`
- rejects a missing path `"/d/nope"`
- rejects missing container path
- rejects unknown action id and disabled action
- rejects `files` for a folder selection `["/d"]`; accepts it for `["/d/a.txt"]`
- rejects `png` for `["/d/a.txt"]`; accepts for `["/d/b.png"]`
- container right-click: `always` with `paths: ["/d"], containerPath: "/d"` is accepted (mirrors `FinderSync.runAction` sending `[container]` for empty selection)
- rejects `maxPaths + 1` paths (generate `"/d/a.txt"` repeated)

**Verify**: filtered command → all pass.

### Step 3: Use it in the Host

In `processJSON`, after the dedupe guard and after reading `manifest`, before `Task.detached`:
```swift
if case .failure(let rejection) = ExecuteRequestValidator.validate(request, manifest: manifest) {
    appState.recordLog(ExecLogEntry(
        actionId: request.actionId,
        success: false,
        summary: rejection.summary,
        paths: request.paths
    ))
    return
}
```
Do not post a user notification for rejections (avoid a notification-spam channel for other processes).

Note: `fileExists` runs on the main actor here; it is a metadata call and acceptable for ≤ a few thousand paths. Do not move validation into the detached task (keeps rejection logging simple).

**Verify**: `./Scripts/dev.sh` builds.

### Step 4: Document

Append to `docs/ipc.md` (after the "Offline Host" section):
```markdown
## Request validation

Distributed notifications do not identify the sender, so the Host re-checks every
`ExecuteRequest` before running it (`ExecuteRequestValidator`): version 1, at most
10,000 paths, every path (and `containerPath`) absolute and existing, the action
enabled, and its `showWhen` / `extRules` accepting the selection. Rejected requests
are logged, not executed, and produce no notification.
```
**Verify**: `grep -n "Request validation" docs/ipc.md` → 1 match.

## Test plan

~12 cases in step 2. Manual: run the Debug app; right-click a file → Copy Path still works; right-click empty Finder background → Open in Terminal still works (container case).

## Done criteria

- [ ] `./Scripts/test.sh` passes; new suite present
- [ ] `./Scripts/dev.sh` succeeds
- [ ] `grep -n "ExecuteRequestValidator.validate" Apps/Host/Sources/IPC/IPCServer.swift` → 1 match
- [ ] Only in-scope files changed; `plans/README.md` updated

## STOP conditions

- The container-right-click case fails validation for an action that the extension shows on empty background (i.e. the consistency reasoning above is wrong for some `ShowWhen`) — STOP and report which; do not loosen rules ad hoc.
- Plan 003 not applied (`processJSON` still runs the executor synchronously) — STOP.
- You find the extension sends relative or non-existent paths in some legitimate flow (e.g. sidebar or toolbar menus) — report.

## Maintenance notes

- This is defense in depth, **not** authentication. A same-user process can still trigger enabled actions on real paths that pass filters. Plan 006 evaluates authenticated transport.
- Any new `ShowWhen` case or `ExtRules` field automatically flows through `ShowWhenMatcher.shouldShow`; keep the Host and extension using the same function.
- Reviewer focus: rejection must happen before `Task.detached`; no rejection path posts a notification.
