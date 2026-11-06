# Plan 014: Refresh logs when users inspect Finder execution

> **Executor instructions:** Read the entire plan; implement only its scope. Run
> each step's verification and compare the stated result. Stop on the conditions
> below rather than silently expanding the task. Update this plan's status row in
> `plans/README.md` when verified, unless your reviewer owns that index.
>
> **Drift check first:** `git diff --stat 9898180..HEAD -- Apps/Settings/Sources/App/AppState.swift Apps/Settings/Sources/Features/Logs/LogsSettingsView.swift Apps/Host/Resources/Localizable.xcstrings Tests/AppIntegrationTests/LogsRefreshTests.swift Package.swift`.
> Also inspect `git status --short` and existing uncommitted changes. Compare live
> code with the excerpts below. Unexplained differences require stopping; changes
> from listed prerequisites require re-reading and documenting the adapted baseline.

## Status

- **Priority:** P2
- **Effort:** S
- **Risk:** LOW
- **Category:** bug
- **Depends on:** 011 (reuse isolated AppState test target)
- **Planned at:** commit `9898180`, 2026-11-06
- **Status:** DONE (reviewed in isolated integration branch; see index verification)

## Why this matters

Settings reads logs at startup and after its own test runs, but not when Host
executes Finder actions. An open Settings window therefore shows stale diagnostics.
Add explicit and lifecycle refresh without changing storage or IPC.

## Current state and conventions

`AppState.swift:41`: `logs = logStore.recent(limit: 200)` in bootstrap.
`recordLog` appends then reloads; clearLogs clears the file and array.
`LogsSettingsView.swift:36-57` has search, status filter and Clear, but no refresh
hook. `ExecLogStore.recent` returns newest-first and `append` rewrites JSONL atomically.
Use the existing `@Environment(AppState.self)` and toolbar `Label` patterns.
Prerequisite 011 supplies a SwiftPM test target named `FinderActionsAppTests`,
with root `path: "."`, explicit sources compiling AppState/HostRuntimeState plus
shared configuration/execution classes, and injectable in-memory preferences.
Extend that target; the executor need not recover any temporary historical harness.
The legacy index rejected a cross-process log-write redesign; do not include one here.

## Repository and verification baseline

Run commands from the repository root (currently `/Users/jyeu/code/finder-menu`).
The product targets macOS 15+, Swift 6 with strict concurrency. The resident Host
is AppKit-only and nonsandboxed; the SwiftUI Settings helper exits on window close;
FinderSync is sandboxed and only renders menus/forwards requests. Preserve that split.
`project.yml` is the Xcode project source of truth. Core has no third-party dependencies.

- `./Scripts/test.sh` — Swift Testing suite; 66 tests in 10 suites passed on 2026-11-06.
- `./Scripts/dev.sh` — XcodeGen, Debug app/helper/extension build and Host-no-SwiftUI
  dependency check. Requires Xcode and XcodeGen; regenerates the tracked project.
  This command was inspected, not rerun during this audit.
- `npm --prefix web run lint` — passed during the audit.
- `npm --prefix web run build` — TypeScript project build plus Vite; inspected,
  not run during the audit. Uses existing installed dependencies or `npm ci` in web.
- No Swift formatter/linter command is configured. Do not invent a lint gate.
- Commands marked **new** below are deliverables of this plan, not existing tools.

## Scope

**Only these paths may change** (new paths are intentional deliverables):
- `Apps/Settings/Sources/App/AppState.swift`
- `Apps/Settings/Sources/Features/Logs/LogsSettingsView.swift`
- `Apps/Host/Resources/Localizable.xcstrings`
- `Tests/AppIntegrationTests/LogsRefreshTests.swift`
- `Package.swift`

Also update only this plan's status/evidence in `plans/README.md`.
All other files, the installed app, user configuration, user scripts, signing
credentials, and live deployment are out of scope. A generated
`FinderActions.xcodeproj/project.pbxproj` change is allowed only where explicitly
listed and must contain only the source membership changes required by this plan.

## Git workflow

Use an isolated branch `codex/014-refresh-settings-logs` when dispatched to implement.
Match conventional commit style (e.g. `fix(host): validate execute requests against action filters`).
Do not merge, push, publish, or commit to the user's branch without separate instructions.

## Steps

### Step 1: Add one refresh operation and its behavioral tests

Add AppState.refreshLogs() to replace logs with logStore.recent(limit: 200). Reuse
it from bootstrap and recordLog. Add LogsRefreshTests to the app test target created
by 011 (include its path in explicit Package.swift sources). Instantiate AppState
with temporary ManifestStore/ExecLogStore and isolated preferences; never bootstrap
production defaults. Append via a second ExecLogStore instance to simulate Host,
then refresh and assert visibility/order. Keep log JSONL unchanged.

**Verify:** `swift test --scratch-path build/SwiftPM --filter LogsRefreshTests` → pass.

### Step 2: Wire appearance, activation and a manual control

Add a localized Refresh toolbar button. Refresh on log-page appearance and when
Settings becomes active while that page is present, using scoped SwiftUI lifecycle/
notification subscriptions that are automatically cancelled when the view leaves.
Do not create a global polling timer. Preserve current filter/search values during
refresh. Keep Clear behavior and refresh-after-clear consistent.

**Verify:** `./Scripts/test.sh` and `./Scripts/dev.sh` → exit 0. GUI check: open Logs,
execute a harmless action in Finder, reactivate Settings and see the row; while
Settings remains frontmost, Refresh must also reveal an externally appended row.
Record GUI checks separately if the environment cannot perform them.

## Test plan

Cover external append, newest-first order, 200-row cap, repeated refresh without
duplication, clear followed by refresh, and absent/empty file. Unit tests exercise
real storage with temporary directories; lifecycle wiring gets a manual GUI check.
Do not simulate Finder by executing arbitrary user scripts.

## Done criteria

- [ ] LogsRefreshTests and full Swift tests pass; Debug build passes.
- [ ] LogsSettingsView contains both manual and lifecycle refresh paths.
- [ ] No new persistent timers, IPC messages or log-format fields.
- [ ] GUI evidence is recorded honestly, not inferred from state tests.
- [ ] `git diff --check` exits 0.
- [ ] `git diff --name-only` and `git status --short` contain only in-scope changes.
- [ ] The index row records results and any explicitly unverified manual gates.

## STOP conditions

- Unexplained drift from the excerpts or conflicting user changes.
- A verification gate fails twice after a reasonable repair attempt.
- Completion requires an out-of-scope file or a live user-data mutation.
- Plan 011's app-test isolation is not available; do not create a parallel test harness.
- A proposed fix requires rewriting ExecLogStore's concurrency/storage model.

## Maintenance notes

The selected policy refreshes on appearance/activation/manual request, not
continuous streaming. If continuous updates later become a requirement, scope
subscriptions to the visible page and reuse refreshLogs rather than duplicating reads.

