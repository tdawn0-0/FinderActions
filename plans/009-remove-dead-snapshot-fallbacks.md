# Plan 009: Remove the unreachable App Group / Host-file snapshot fallbacks and fix the docs

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 2e59370..HEAD -- Apps/Host/Sources/IPC/IPCServer.swift Extensions/FinderSync Packages/FinderActionsCore/Sources/Models/Snapshot.swift docs/ipc.md docs/architecture.md README.md project.yml`
> Plans 003/005 change `IPCServer.processJSON` (not touched here). Other changes in the regions below → compare; mismatch → STOP.

## Status

- **Priority**: P3
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none (if plan 006's ADR decides to adopt an App Group, re-scope this plan first — see STOP conditions)
- **Category**: tech-debt / docs
- **Planned at**: commit `2e59370`, 2026-10-02

## Why this matters

The code and docs describe a cold-start path where the Host writes `menu-snapshot.json` to Application Support and an App Group container, and the Finder extension reads it before any live snapshot arrives. None of that works:
- No target has the `com.apple.security.application-groups` entitlement (`Extensions/FinderSync/FinderSync.entitlements` contains only `com.apple.security.app-sandbox`; the Host's entitlements only `com.apple.security.automation.apple-events`), so `containerURL(forSecurityApplicationGroupIdentifier:)` is not usable by the sandboxed extension, and the group ID isn't team-prefixed as macOS requires.
- The extension is sandboxed, so `FileManager.urls(for: .applicationSupportDirectory, …)` resolves to **its own container** (`~/Library/Containers/com.finderactions.host.FinderSync/Data/Library/Application Support`). Its "Host path" fallback (`ManifestStore.applicationSupportLayout().root`) is therefore the *same* file as its own `cacheURL`, never the Host's file.

What actually works: the extension caches the last live snapshot in its own container (`cacheURL`) and asks the Host for a fresh one on start (`snapshotRequestNotification`). The menu is gated on the Host process running anyway. Removing the dead paths deletes misleading code, stops the Host from writing a file nothing reads on every publish, and makes the docs true.

## Current state

- `Apps/Host/Sources/IPC/IPCServer.swift:114-161` — `SnapshotPublisher.publish` calls `writeFallback(json:)` first:
```swift
private static func writeFallback(json: String) {
    let support = ManifestStore.applicationSupportLayout().root
        .appendingPathComponent(IPCConstants.snapshotFileName)
    try? json.write(to: support, atomically: true, encoding: .utf8)

    if let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: IPCConstants.appGroupId
    ) {
        let url = container.appendingPathComponent(IPCConstants.snapshotFileName)
        try? json.write(to: url, atomically: true, encoding: .utf8)
    }
}
```
- `Extensions/FinderSync/IPCClient.swift:29-34` (init) and `60-81` (`loadCachedSnapshot`):
```swift
init() {
    let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        .appendingPathComponent("FinderActions", isDirectory: true)
    try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
    cacheURL = support.appendingPathComponent(IPCConstants.snapshotFileName)
}
...
func loadCachedSnapshot() -> MenuSnapshot? {
    if let data = try? Data(contentsOf: cacheURL),
       let snap = try? JSONCoding.decode(MenuSnapshot.self, from: data) {
        return snap
    }
    let hostPath = ManifestStore.applicationSupportLayout().root
        .appendingPathComponent(IPCConstants.snapshotFileName)
    if let data = try? Data(contentsOf: hostPath),
       let snap = try? JSONCoding.decode(MenuSnapshot.self, from: data) {
        return snap
    }
    if let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: IPCConstants.appGroupId
    ) {
        let url = container.appendingPathComponent(IPCConstants.snapshotFileName)
        if let data = try? Data(contentsOf: url),
           let snap = try? JSONCoding.decode(MenuSnapshot.self, from: data) {
            return snap
        }
    }
    return nil
}
```
- `Packages/FinderActionsCore/Sources/Models/Snapshot.swift:107-109`:
```swift
/// UserDefaults / App Group suite (optional cold-start fallback)
public static let appGroupId = "group.com.finderactions.shared"
public static let snapshotFileName = "menu-snapshot.json"
```
- Docs that describe the fallback:
  - `docs/ipc.md:66-68` — section `## Cold-start cache`: "Host also writes `menu-snapshot.json` under Application Support (and App Group if available). Extension reads this when no live snapshot has arrived yet."
  - `docs/architecture.md:38` — `(+ Application Support cache)` in the data-flow diagram; `docs/architecture.md:52` — `menu-snapshot.json   # cold-start fallback for extension` in the Storage tree.
  - `README.md:163` — "Optional App Group / Application Support file caches the last snapshot for cold start."

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Core tests | `./Scripts/test.sh` | all pass |
| App build | `./Scripts/dev.sh` | `Debug app: …`; restore pbxproj if modified: `git checkout -- FinderActions.xcodeproj/project.pbxproj` |

## Scope

**In scope**: `Apps/Host/Sources/IPC/IPCServer.swift` (`SnapshotPublisher` only), `Extensions/FinderSync/IPCClient.swift` (`loadCachedSnapshot` only), `Packages/FinderActionsCore/Sources/Models/Snapshot.swift` (`appGroupId` only), `docs/ipc.md`, `docs/architecture.md`, `README.md`.

**Out of scope**: the extension's own `cacheURL` cache and its write in `applySnapshotJSONUnlocked` (that one works — keep it); entitlements; `snapshotFileName` (still used by the extension cache); chunking logic.

## Git workflow
Branch `advisor/009-remove-dead-snapshot-fallbacks`; commit `refactor(ipc): drop unreachable App Group snapshot fallbacks`. Do not push.

## Steps

### Step 1: Host — stop writing the fallback file
Delete `writeFallback(json:)` and its call in `publish`. Keep the rest of `publish` unchanged.
**Verify**: `grep -n "writeFallback\|appGroupId" Apps/Host` → no output.

### Step 2: Extension — read only its own cache
Reduce `loadCachedSnapshot()` to:
```swift
/// Last live snapshot, cached in this sandboxed extension's own container.
func loadCachedSnapshot() -> MenuSnapshot? {
    guard let data = try? Data(contentsOf: cacheURL) else { return nil }
    return try? JSONCoding.decode(MenuSnapshot.self, from: data)
}
```
**Verify**: `grep -n "hostPath\|appGroupId\|applicationSupportLayout" Extensions/FinderSync` → no output.

### Step 3: Core — remove the constant
Delete the `appGroupId` line and its doc comment from `IPCConstants`.
**Verify**: `grep -rn "appGroupId" Apps Extensions Packages Tests Tools` → no output; `./Scripts/test.sh` passes; `./Scripts/dev.sh` succeeds.

### Step 4: Docs
- `docs/ipc.md`: replace the `## Cold-start cache` section body with: "The extension caches the last live snapshot in its own sandbox container and, on start, posts `com.finderactions.extension.snapshot-request` so a running Host republishes. There is no shared file between Host and extension."
- `docs/ipc.md` notifications table: add the row `| com.finderactions.extension.snapshot-request | Ext → Host | empty (ask Host to republish) |` if not already present (`grep -n "snapshot-request" docs/ipc.md`).
- `docs/architecture.md`: remove `(+ Application Support cache)` from the diagram line; remove the `menu-snapshot.json` line from the Storage tree.
- `README.md:163`: replace the second sentence with "The extension keeps its own cached copy of the last snapshot."
**Verify**: `rg -n "App Group" README.md docs/ipc.md docs/architecture.md` → no output.
The new plan 006 ADR intentionally discusses possible future App Groups; exclude
that design record from this current-behavior documentation check.

## Test plan
Manual: run the Debug app, right-click in Finder → menu appears. Quit and relaunch Finder (`killall Finder`) while the Host runs → menu still appears (live snapshot via snapshot-request).

## Done criteria
- [ ] `./Scripts/test.sh`, `./Scripts/dev.sh` succeed
- [ ] All grep checks above return no output
- [ ] Only in-scope files changed; `plans/README.md` updated

## STOP conditions
- Any target's entitlements now include `com.apple.security.application-groups` (`grep -rn "application-groups" Apps Extensions`) — someone adopted App Groups (possibly via plan 006); STOP, the premise is gone.
- The extension's `Info.plist` or entitlements show it is no longer sandboxed — STOP.

## Maintenance notes
- Users upgrading will have a stale `~/Library/Application Support/FinderActions/menu-snapshot.json` left by old builds; harmless. Optionally a later release can delete it once at Host startup (deferred: not worth the code now).
- If plan 006 adopts an App Group for XPC, a shared snapshot file becomes possible again — design it then, with the team-prefixed group ID.
