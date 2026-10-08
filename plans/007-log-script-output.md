# Plan 007: Execution logs keep the tail of stderr, as the scripting docs promise

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 2e59370..HEAD -- Apps/Shared/Sources/Execution Apps/Host/Sources/IPC/IPCServer.swift Apps/Settings/Sources/App/AppState.swift Apps/Settings/Sources/Features/SettingsRootView.swift docs/scripting.md Packages/FinderActionsCore/Sources Tests/FinderActionsCoreTests`
> Plans 001–005 touch some of these files; verify the specific excerpts below still match.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: plans/003-process-runner-off-main.md (`IPCServer.finish` exists)
- **Category**: bug / docs
- **Planned at**: commit `2e59370`, 2026-10-02

## Why this matters

`docs/scripting.md` tells script authors: "Non-zero exit → failure notification; stderr is logged." In reality only `summary` (the first stderr line) is persisted; the rest of stderr is discarded after the notification. Scripts run from Finder have no terminal, so the log is the only debugging surface — a `set -e` failure in a multi-step script typically prints the useful line last. After this plan each log entry stores up to the last 4,000 characters of stderr, the Logs view shows it, and the doc states the limit precisely.

## Current state

- `Apps/Shared/Sources/Execution/ActionExecutor.swift:38-54` — the log model (shared by Host and Settings):
```swift
public struct ExecLogEntry: Codable, Identifiable, Sendable, Equatable {
    public var id: String
    public var timestamp: String
    public var actionId: String
    public var success: Bool
    public var summary: String
    public var paths: [String]

    public init(id: String = UUID().uuidString, timestamp: String = ISO8601DateFormatter().string(from: Date()), actionId: String, success: Bool, summary: String, paths: [String]) { … }
}
```
- `ExecResult` (same file, lines 22–36) has `stdout` and `stderr` strings.
- Log file: `~/Library/Application Support/FinderActions/logs/exec.jsonl`, one JSON object per line, max 200 entries (`Apps/Shared/Sources/Execution/ExecLogStore.swift`). Decoding uses synthesized `Codable`; an added **optional** property decodes as `nil` from old lines (backward compatible).
- Places that build `ExecLogEntry` from an `ExecResult`:
  - `Apps/Host/Sources/IPC/IPCServer.swift` — `finish(request:result:)` (added by plan 003).
  - `Apps/Settings/Sources/Features/SettingsRootView.swift` — `runLiveTest()` (≈ line 706–730) records `"Test Run: \(res.summary)"`.
  - `Apps/Settings/Sources/App/AppState.swift:201-215` — `executeForTesting` (currently unused; plan 010 deletes it — update it anyway if it still exists).
- Logs UI: `SettingsRootView.swift`, `struct LogsSettingsView` (≈ lines 1029–1132); each row shows `log.summary` with `.font(.system(size: 11))` then paths in monospaced 10 pt, `.lineLimit(2)`.
- `docs/scripting.md` "Rules" item 5: `Non-zero exit → failure notification; stderr is logged.`; README "Write a shell action" ends with `Non-zero = failure (stderr in logs).`

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Core tests | `./Scripts/test.sh` | all pass |
| App build | `./Scripts/dev.sh` | `Debug app: …` (restore pbxproj if modified and no new `Apps/` files) |

## Scope

**In scope**:
- `Packages/FinderActionsCore/Sources/Execution/OutputTail.swift` (create; `Execution/` folder exists after plan 003)
- `Tests/FinderActionsCoreTests/OutputTailTests.swift` (create)
- `Apps/Shared/Sources/Execution/ActionExecutor.swift` (`ExecLogEntry` only)
- `Apps/Host/Sources/IPC/IPCServer.swift` (`finish` only)
- `Apps/Settings/Sources/Features/SettingsRootView.swift` (`runLiveTest` and `LogsSettingsView` row only)
- `Apps/Settings/Sources/App/AppState.swift` (`executeForTesting`, only if it still exists)
- `docs/scripting.md`, `README.md`, `README.zh-Hans.md` (the one sentence each)

**Out of scope**: stdout persistence (keep logs small; summary already carries stdout's first line), `ExecLogStore` storage format beyond the new optional field, notification content.

## Git workflow

Branch `advisor/007-log-script-output`; commit e.g. `fix(logs): keep stderr tail in execution log`. Do not push.

## Steps

### Step 1: Pure helper in Core
`OutputTail.swift`:
```swift
import Foundation

public enum OutputTail {
    /// Characters of stderr kept per log entry.
    public static let logLimit = 4_000

    /// Trimmed last `limit` characters of `text`, or nil when empty/whitespace.
    /// Prefixed with "…" when truncated.
    public static func tail(_ text: String, limit: Int = logLimit) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.count > limit else { return trimmed }
        return "…" + String(trimmed.suffix(limit))
    }
}
```
Tests (`@Suite("Output tail")`): empty → nil; whitespace-only → nil; short text returned trimmed; text of `limit + 10` chars → result count `limit + 1` and starts with `…` and ends with the original last char; multi-byte (e.g. repeated `"中"`) truncates by characters.

**Verify**: `./Scripts/test.sh` → pass.

### Step 2: Add the field
In `ExecLogEntry` add `public var stderrTail: String?` (after `paths`) and an init parameter `stderrTail: String? = nil` (last, defaulted so other call sites compile). Assign it.

**Verify**: `./Scripts/dev.sh` builds.

### Step 3: Populate it
- `IPCServer.finish`: pass `stderrTail: OutputTail.tail(result.stderr)`.
- `runLiveTest` and `executeForTesting` (if present): pass `stderrTail: OutputTail.tail(res.stderr)` / `result.stderr`.
Both files already `import FinderActionsCore`.

**Verify**: `grep -rn "stderrTail:" Apps | wc -l` → ≥ 2.

### Step 4: Show it
In the `LogsSettingsView` row, after the `Text(log.summary)` view, add:
```swift
if let stderrTail = log.stderrTail {
    Text(stderrTail)
        .font(.system(size: 10, design: .monospaced))
        .foregroundStyle(Color.red.opacity(0.85))
        .lineLimit(6)
        .textSelection(.enabled)
}
```
Also include it in the search filter: add `|| (log.stderrTail?.localizedCaseInsensitiveContains(searchText) ?? false)`.

**Verify**: `./Scripts/dev.sh` builds.

### Step 5: Docs
- `docs/scripting.md` rule 5 → `Non-zero exit → failure notification; the last 4,000 characters of stderr are kept in Settings → Logs.`
- `README.md` sentence `Non-zero = failure (stderr in logs).` → `Non-zero = failure (the end of stderr is kept in Settings → Logs).`
- `README.zh-Hans.md`: find the equivalent sentence (`grep -n "stderr" README.zh-Hans.md`) and update it to the same meaning in Chinese. If there is no such sentence, leave the file alone.

**Verify**: `grep -n "4,000" docs/scripting.md` → 1 match.

## Test plan
- `OutputTailTests` (step 1).
- Manual: add an inline shell action `echo one >&2; echo two >&2; exit 1`, click Test Run in Settings → Logs shows "one" in summary and "one\ntwo" in the red tail.

## Done criteria
- [ ] `./Scripts/test.sh` and `./Scripts/dev.sh` succeed
- [ ] Old `exec.jsonl` lines still load (field optional — confirm `stderrTail: String?`)
- [ ] Only in-scope files changed; `plans/README.md` updated

## STOP conditions
- `IPCServer.finish` does not exist (plan 003 not applied) — STOP.
- `ExecLogEntry` has moved or gained a custom `init(from:)` — report before editing.

## Maintenance notes
- Log size bound: 200 entries × ≤4 KB tail ≈ 800 KB worst case; `ExecLogStore` rewrites the whole file per append, so do not raise the limit much without changing the store.
- Logs are local-only (README Privacy section); stderr may contain file names — consistent with paths already being logged.
