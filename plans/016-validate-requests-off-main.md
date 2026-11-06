# Plan 016: Validate selection metadata off the Host main actor

> **Executor instructions:** Read the entire plan, follow its steps and verification
> gates, and stop instead of expanding scope when a STOP condition applies. Update
> this plan's row in `plans/README.md` unless the dispatching reviewer owns the index.
>
> **Drift check first:** `git diff --stat 9898180..HEAD -- Apps/Host/Sources/IPC/IPCServer.swift Packages/FinderActionsCore/Sources/IPC/ExecuteRequestValidator.swift Tests/FinderActionsCoreTests/ExecuteRequestValidationTests.swift Tests/AppIntegrationTests/IPCResponsivenessTests.swift Package.swift`.
> Inspect `git status --short` too. Compare excerpts to live sources. Unexplained
> drift is a STOP condition; re-read and document adaptations from named prerequisites.

## Status

- **Priority:** P2
- **Effort:** M
- **Risk:** MED
- **Category:** perf + tests
- **Depends on:** 011 (reuses durable application test target)
- **Planned at:** commit `9898180`, 2026-11-06
- **Status:** DONE (reviewed in isolated integration branch; see index verification)

## Why this matters

Process execution is detached, but validation still synchronously queries the
filesystem on the Host's main actor. Up to 10,000 selected paths are each inspected
twice plus the container. Slow volumes can block the menu and configuration IPC.
Move the complete filesystem stage off-main without weakening validation/deduplication.

## Current state and conventions

IPCServer is `@MainActor`; processJSON currently runs:

```swift
let executor = appState.executor
let manifest = appState.effectiveManifest
if case .failure(let rejection) = ExecuteRequestValidator.validate(request, manifest: manifest) {
    appState.recordLog(/* rejection */)
    return
}
Task.detached(priority: .userInitiated) { [weak self] in
    let result = executor.execute(request: request, manifest: manifest)
    await self?.finish(request: request, result: result)
}
```

ExecuteRequestValidator:44-55 calls injected fileInfo once for existence and again
for selected-path directory flags; default diskFileInfo uses FileManager.fileExists.
Keep version/count/absolute-path checks, enabled action/filter checks, immutable
manifest capture, dedupe-before-dispatch and main-actor logging. The ADR explicitly
says validation is not sender authentication; do not claim to fix authentication.
Prerequisite 011 supplies `FinderActionsAppTests`: a root-path SwiftPM test target
with explicit actual AppState, HostRuntimeState, SharedConfiguration, AppPreferences,
ActionExecutor and ExecLogStore sources, plus in-memory preferences injection.
Extend its source list rather than creating a copied server/test implementation.
Match `ExecuteRequestValidationTests` using an injected fileInfo dictionary and
Swift Testing assertions; use real server sources in the integration test.

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

**Only these paths may change** (new paths are explicit deliverables):
- `Apps/Host/Sources/IPC/IPCServer.swift`
- `Packages/FinderActionsCore/Sources/IPC/ExecuteRequestValidator.swift`
- `Tests/FinderActionsCoreTests/ExecuteRequestValidationTests.swift`
- `Tests/AppIntegrationTests/IPCResponsivenessTests.swift`
- `Package.swift`

Also update this plan's row/evidence in `plans/README.md`. All other production
files, installed apps, user preferences/configuration, signing credentials and live
deployments are out of scope. Do not regenerate a tracked Xcode project unless it
is listed; if listed, retain only membership changes required by this plan.

## Git workflow

Use isolated branch `codex/016-validate-requests-off-main` for execution. Match conventional commits
(e.g. `fix(host): validate execute requests against action filters`). Do not merge,
push, publish, or commit to the user's branch without separate instructions.

## Steps

### Step 1: Query each unique path once

Refactor validator to cache fileInfo results per request, including a container
that duplicates a selected path. Preserve input path ordering and duplicate argv
entries; caching metadata must not deduplicate what the action receives. Preserve
existing rejection semantics. Add counting tests and verify directory flags come
from the same observation used to establish existence.

**Verify:** `swift test --scratch-path build/SwiftPM --filter ExecuteRequestValidationTests`
→ all existing cases and new unique-lookup cases pass.

### Step 2: Detach validation together with execution

Capture the request, effective manifest and executor on the main actor after decode
and dedupe. Run validator and execution in a detached task; a validation failure
returns to a main-actor rejection-log method and never executes/notifies. Keep
successful finish/notify on the main actor. Add minimal injectable Sendable
validation/execution closures for tests, defaulting to production behavior. Do not
make the server unsafe Sendable or move AppKit mutable state off its actor. Preserve
the existing policy that an accepted request uses the captured manifest even if
Settings changes during execution; do not add silent replays or change transport.

**Verify:** `./Scripts/test.sh` → all pass; `./Scripts/dev.sh` → strict-concurrency
build and Host dependency boundary pass.

### Step 3: Prove responsiveness with the real server

Extend FinderActionsAppTests' explicit sources to include IPCServer.swift and the
new IPCResponsivenessTests.swift. Expose the smallest internal ingestion seam for
same-module tests; do not post real distributed execute notifications. Inject a
validator that signals entry and waits on a controllable background latch. While it
is held, schedule a MainActor heartbeat and require completion before releasing the
latch. Always release on cleanup and bound the test. Assert one execution for two
identical request IDs, rejection gives a log but no execute, and valid result logs
on completion. Use temporary Host stores and the isolated preferences seam from 011;
disable notifications in test state so authorization UI cannot appear.

**Verify:** `swift test --scratch-path build/SwiftPM --filter IPCResponsivenessTests`
→ heartbeat runs while validation is blocked; dedupe/rejection/execution assertions pass.

## Test plan

Add deterministic lookup-count assertions (including duplicate container),
file-filter behavior, and the MainActor heartbeat test. Avoid live SMB mounts and
wall-clock performance thresholds. Use a latch with timeout, cleanup release and
clear failure diagnostics. The result proves actor placement, not a measured speedup.

## Done criteria

- [ ] Core validator tests, IPCResponsivenessTests, full Swift tests and Debug build pass.
- [ ] No default diskFileInfo/validate call occurs on the server's main-actor intake path.
- [ ] A selected path is inspected once per request; argv ordering/duplicates are preserved.
- [ ] Invalid requests never execute; duplicate IDs still execute at most once within the existing window.
- [ ] `git diff --check` exits 0.
- [ ] `git diff --name-only` and `git status --short` contain only scoped changes.
- [ ] The index records verification results and outstanding manual gates.

## STOP conditions

- Unexplained drift, conflicting user edits, or need to change an out-of-scope file.
- A verification gate fails twice after a reasonable repair attempt.
- The test would post a request to the installed Host or request notification permission.
- Off-main validation appears to require bypassing filters or unsafe shared mutable state.
- Request volume control or a general queue scheduler is needed; propose it separately.

## Maintenance notes

Thread responsiveness is not filesystem cancellation. A blocking network lookup
may still occupy its worker. Preserve captured-state semantics and add bounded
concurrency only if separately measured/required. Future authenticated IPC must
retain the same validator and main-actor completion rules.
