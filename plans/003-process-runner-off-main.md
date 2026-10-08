# Plan 003: Actions run off the Host main thread through a deadlock-free, tested ProcessRunner

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 2e59370..HEAD -- Apps/Shared/Sources/Execution/ActionExecutor.swift Apps/Host/Sources/IPC/IPCServer.swift Packages/FinderActionsCore/Sources Tests/FinderActionsCoreTests`
> If any in-scope file changed, compare against the excerpts below; mismatch → STOP.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED
- **Depends on**: none
- **Category**: bug / perf
- **Planned at**: commit `2e59370`, 2026-10-02

## Why this matters

Two compounding defects in the core feature:

1. **Pipe deadlock.** `ActionExecutor.runProcess` calls `process.waitUntilExit()` *before* reading stdout/stderr. A script that writes more than the pipe buffer (~64 KB — e.g. `ls -R`, verbose `ffmpeg`, `find`) blocks writing forever while the Host blocks waiting for exit. Neither ever finishes.
2. **Main-thread execution.** The Host's IPC handler is `@MainActor` and calls the executor synchronously. Every shell action — including long ones like the batch `ffmpeg` example in `docs/scripting.md` — freezes the Host's menu bar for its full duration, and later Finder clicks queue behind it. Combined with (1), one noisy script permanently hangs the Host.

After this plan: process execution lives in a Foundation-only `ProcessRunner` in the `FinderActionsCore` package (so `swift test` covers it), it drains output concurrently, caps captured bytes, supports an optional timeout, and the Host runs each request on a detached task.

## Current state

Files:
- `Apps/Shared/Sources/Execution/ActionExecutor.swift` — the executor, compiled into both the Host and Settings app targets (not part of SwiftPM; not unit-tested). `runProcess` at lines 328–359, `runOsascript` at 313–316.
- `Apps/Host/Sources/IPC/IPCServer.swift` — `@MainActor final class IPCServer`; `processJSON` at lines 66–88 runs execution synchronously.
- `Packages/FinderActionsCore/Sources/` — SwiftPM library `FinderActionsCore` (Foundation only, Swift 6 language mode, strict concurrency). Folders by concern: `IPC/`, `Quoting/`, `Manifest/`, etc.
- `Tests/FinderActionsCoreTests/` — Swift Testing suites.

`ActionExecutor.swift:328-359` today:
```swift
public func runProcess(argv: [String], env: [String: String], cwd: String) -> ExecResult {
    guard let exe = argv.first else {
        return ExecResult(success: false, summary: "Empty argv", exitCode: 1)
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: exe)
    process.arguments = Array(argv.dropFirst())
    process.environment = env
    process.currentDirectoryURL = URL(fileURLWithPath: cwd)

    let outPipe = Pipe()
    let errPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errPipe

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        return ExecResult(success: false, summary: error.localizedDescription, exitCode: 1)
    }

    let stdout = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let stderr = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let code = process.terminationStatus
    let success = code == 0
    let firstLine = stdout.split(separator: "\n", omittingEmptySubsequences: true).first.map(String.init)
    let summary = success
        ? (firstLine ?? "OK")
        : (stderr.split(separator: "\n").first.map(String.init) ?? "Exit \(code)")
    return ExecResult(success: success, summary: summary, exitCode: code, stdout: stdout, stderr: stderr)
}
```
`ActionExecutor.swift:313-316`:
```swift
private func runOsascript(_ source: String) -> ExecResult {
    let argv = ["/usr/bin/osascript", "-e", source]
    return runProcess(argv: argv, env: ProcessInfo.processInfo.environment, cwd: FileManager.default.currentDirectoryPath)
}
```
`IPCServer.swift:66-88`:
```swift
private func processJSON(_ json: String) {
    do {
        let request = try JSONCoding.decode(ExecuteRequest.self, from: json)
        guard requestDedupe.accept(request.requestId) else { return }
        let result = appState.executor.execute(request: request, manifest: appState.effectiveManifest)
        let entry = ExecLogEntry(
            actionId: request.actionId,
            success: result.success,
            summary: result.summary,
            paths: request.paths
        )
        appState.recordLog(entry)
        notify(result: result, actionId: request.actionId)
    } catch {
        let entry = ExecLogEntry(
            actionId: "?",
            success: false,
            summary: "Bad execute payload: \(error.localizedDescription)",
            paths: []
        )
        appState.recordLog(entry)
    }
}
```
`ActionExecutor` is `public final class ActionExecutor: @unchecked Sendable`; `ExecResult`, `ExecuteRequest`, `ActionManifest` are `Sendable`. `appState` is a `@MainActor` `HostRuntimeState`.

Existing lock-box convention to match (`ActionExecutor.swift:5-20`):
```swift
private final class LockedErrorBox: @unchecked Sendable {
    private let lock = NSLock()
    private var storedError: Error?
    ...
}
```
Test convention (`Tests/FinderActionsCoreTests/ExecuteDeliveryTests.swift`): `import Foundation`, `import Testing`, `@testable import FinderActionsCore`, `@Suite("…") struct …Tests { @Test func … { #expect(…) } }`.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Core tests | `./Scripts/test.sh` | `Test run with N tests in M suites passed` |
| Filtered tests | `swift test --package-path . --scratch-path build/SwiftPM --filter ProcessRunner` | all pass |
| App build | `./Scripts/dev.sh` | ends with `Debug app: …` |

`dev.sh` regenerates `FinderActions.xcodeproj/project.pbxproj`. This plan adds files only under `Packages/` and `Tests/` (SwiftPM), not under `Apps/`, so restore the pbxproj if modified: `git checkout -- FinderActions.xcodeproj/project.pbxproj`.

## Scope

**In scope**:
- `Packages/FinderActionsCore/Sources/Execution/ProcessRunner.swift` (create; new folder `Execution`)
- `Tests/FinderActionsCoreTests/ProcessRunnerTests.swift` (create)
- `Apps/Shared/Sources/Execution/ActionExecutor.swift` (`runProcess`, `runOsascript` only)
- `Apps/Host/Sources/IPC/IPCServer.swift` (`processJSON` + new `finish` method only)

**Out of scope**:
- `Apps/Settings/**` — Settings' "Test Run" already uses `Task.detached`; it benefits automatically.
- `AppState.runCapture` in Settings (short `pluginkit`/`killall` calls; separate concern).
- `ExecLogEntry` fields — plan 007 changes those.
- `ShellEnvironment`, IPC notification names, `ExecuteDelivery`.

## Git workflow

- Branch `advisor/003-process-runner-off-main`. Suggested commits: `feat(core): add ProcessRunner with concurrent pipe draining`, `fix(host): run actions off the main actor`. Do not push.

## Steps

### Step 1: Create `ProcessRunner` in Core

Create `Packages/FinderActionsCore/Sources/Execution/ProcessRunner.swift`:

```swift
import Foundation

/// Output of a child process run to completion.
public struct ProcessOutput: Sendable, Equatable {
    public var exitCode: Int32
    public var stdout: String
    public var stderr: String
    /// True when the process was terminated because `timeout` elapsed.
    public var timedOut: Bool

    public init(exitCode: Int32, stdout: String, stderr: String, timedOut: Bool) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
        self.timedOut = timedOut
    }
}

public enum ProcessRunnerError: Error, Equatable {
    case emptyArgv
}

/// Runs a process from an already-split argv (paths are never joined into a
/// shell string). Drains stdout/stderr while the child runs so large output
/// cannot fill the pipe buffer and deadlock. Blocks the calling thread until
/// the process exits — never call it on the main thread.
public enum ProcessRunner {
    /// Bytes kept per stream. Output beyond this is still read (so the child
    /// never blocks) but discarded.
    public static let maxCapturedBytes = 256 * 1024
    /// How long to keep reading after exit; a background grandchild that
    /// inherited the pipe would otherwise hold it open indefinitely.
    static let postExitDrainSeconds: TimeInterval = 2

    public static func run(
        argv: [String],
        environment: [String: String],
        workingDirectory: String,
        timeout: TimeInterval? = nil
    ) throws -> ProcessOutput {
        guard let executable = argv.first else { throw ProcessRunnerError.emptyArgv }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = Array(argv.dropFirst())
        process.environment = environment
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()

        let stdout = StreamCapture(limit: maxCapturedBytes)
        let stderr = StreamCapture(limit: maxCapturedBytes)
        let drained = DispatchGroup()
        stdout.drain(outPipe.fileHandleForReading, group: drained)
        stderr.drain(errPipe.fileHandleForReading, group: drained)

        let timedOut = TimeoutFlag()
        var timer: DispatchWorkItem?
        if let timeout {
            let item = DispatchWorkItem { [process] in
                guard process.isRunning else { return }
                timedOut.set()
                process.terminate()
            }
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout, execute: item)
            timer = item
        }

        process.waitUntilExit()
        timer?.cancel()

        if drained.wait(timeout: .now() + postExitDrainSeconds) == .timedOut {
            outPipe.fileHandleForReading.readabilityHandler = nil
            errPipe.fileHandleForReading.readabilityHandler = nil
        }

        return ProcessOutput(
            exitCode: process.terminationStatus,
            stdout: stdout.text,
            stderr: stderr.text,
            timedOut: timedOut.value
        )
    }
}

/// Accumulates one pipe's bytes up to `limit`; thread-safe because
/// `readabilityHandler` fires on a background queue.
private final class StreamCapture: @unchecked Sendable {
    private let lock = NSLock()
    private let limit: Int
    private var data = Data()
    private var finished = false

    init(limit: Int) {
        self.limit = limit
    }

    var text: String {
        lock.lock()
        defer { lock.unlock() }
        return String(decoding: data, as: UTF8.self)
    }

    func drain(_ handle: FileHandle, group: DispatchGroup) {
        group.enter()
        handle.readabilityHandler = { [self] handle in
            let chunk = handle.availableData
            if chunk.isEmpty {
                handle.readabilityHandler = nil
                if markFinished() { group.leave() }
            } else {
                append(chunk)
            }
        }
    }

    private func append(_ chunk: Data) {
        lock.lock()
        defer { lock.unlock() }
        let room = limit - data.count
        if room > 0 { data.append(chunk.prefix(room)) }
    }

    /// Returns true only the first time, so the group is left exactly once.
    private func markFinished() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if finished { return false }
        finished = true
        return true
    }
}

private final class TimeoutFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var flag = false

    var value: Bool {
        lock.lock()
        defer { lock.unlock() }
        return flag
    }

    func set() {
        lock.lock()
        flag = true
        lock.unlock()
    }
}
```

If Swift 6 rejects capturing `process` in the `DispatchWorkItem` closure (non-Sendable capture), wrap it: `nonisolated(unsafe) let runningProcess = process` immediately before creating the work item and capture `runningProcess` instead. This is the **only** permitted `nonisolated(unsafe)` in this plan.

**Verify**: `./Scripts/test.sh` → compiles; existing tests pass.

### Step 2: Write `ProcessRunnerTests`

Create `Tests/FinderActionsCoreTests/ProcessRunnerTests.swift` with `@Suite("Process runner")` and these tests (use `/bin/sh -c` scripts; bounds are generous to avoid CI flakiness). Unless a test says otherwise, pass environment `["PATH": "/usr/bin:/bin"]` so `head`, `tr` and `sleep` resolve:

1. `capturesStdoutStderrAndExitCode` — argv `["/bin/sh", "-c", "echo out; echo err >&2; exit 3"]`, cwd `"/"` → `exitCode == 3`, `stdout == "out\n"`, `stderr == "err\n"`, `timedOut == false`.
2. `largeOutputDoesNotDeadlock` — `["/bin/sh", "-c", "head -c 1000000 /dev/zero | tr '\\\\0' a; head -c 1000000 /dev/zero | tr '\\\\0' b >&2"]` → returns; `stdout.utf8.count == ProcessRunner.maxCapturedBytes`, `stderr.utf8.count == ProcessRunner.maxCapturedBytes`, `exitCode == 0`. (Check the escaping produces the shell text `tr '\0' a`; use a Swift raw string `#"…"#` if simpler.)
3. `passesEnvironmentAndWorkingDirectory` — `["/bin/sh", "-c", #"printf '%s|' "$FA_TEST"; /bin/pwd -P"#]`, env `["FA_TEST": "a b"]`, cwd `"/usr/bin"` → `stdout == "a b|/usr/bin\n"`.
4. `timeoutTerminatesProcess` — `["/bin/sleep", "10"]`, timeout `0.5` → `timedOut == true`; elapsed (measure with `Date()`) `< 5` seconds.
5. `backgroundChildHoldingPipeDoesNotHang` — `["/bin/sh", "-c", "sleep 5 & echo started"]` → elapsed `< 4.5` seconds; `stdout.hasPrefix("started")`.
6. `emptyArgvThrows` — `#expect(throws: ProcessRunnerError.emptyArgv) { try ProcessRunner.run(argv: [], environment: [:], workingDirectory: "/") }`.
7. `missingExecutableThrows` — `#expect(throws: (any Error).self) { try ProcessRunner.run(argv: ["/nonexistent/fa-missing"], environment: [:], workingDirectory: "/") }`.

**Verify**: `swift test --package-path . --scratch-path build/SwiftPM --filter ProcessRunner` → 7 tests pass. Then `./Scripts/test.sh` → all pass.

### Step 3: Make `ActionExecutor.runProcess` delegate to `ProcessRunner`

Replace the body of `runProcess` (keep it `public`, add an optional `timeout` parameter with default `nil` so existing callers compile):
```swift
/// Shared Process runner — argv is already split (no shell string concat of paths).
public func runProcess(
    argv: [String],
    env: [String: String],
    cwd: String,
    timeout: TimeInterval? = nil
) -> ExecResult {
    let output: ProcessOutput
    do {
        output = try ProcessRunner.run(argv: argv, environment: env, workingDirectory: cwd, timeout: timeout)
    } catch ProcessRunnerError.emptyArgv {
        return ExecResult(success: false, summary: "Empty argv", exitCode: 1)
    } catch {
        return ExecResult(success: false, summary: error.localizedDescription, exitCode: 1)
    }
    if output.timedOut {
        return ExecResult(
            success: false,
            summary: "Timed out after \(Int(timeout ?? 0))s",
            exitCode: output.exitCode,
            stdout: output.stdout,
            stderr: output.stderr
        )
    }
    let success = output.exitCode == 0
    let firstLine = output.stdout.split(separator: "\n", omittingEmptySubsequences: true).first.map(String.init)
    let summary = success
        ? (firstLine ?? "OK")
        : (output.stderr.split(separator: "\n").first.map(String.init) ?? "Exit \(output.exitCode)")
    return ExecResult(success: success, summary: summary, exitCode: output.exitCode, stdout: output.stdout, stderr: output.stderr)
}
```
In `runOsascript`, pass `timeout: 120` (AppleScript terminal launches can wait on a one-time Automation consent prompt; 120 s bounds a hung `osascript`). Shell actions keep **no** timeout — user scripts may legitimately run for a long time.

**Verify**: `./Scripts/dev.sh` builds.

### Step 4: Move Host execution off the main actor

Rewrite `IPCServer.processJSON` and add `finish`:
```swift
private func processJSON(_ json: String) {
    let request: ExecuteRequest
    do {
        request = try JSONCoding.decode(ExecuteRequest.self, from: json)
    } catch {
        appState.recordLog(ExecLogEntry(
            actionId: "?",
            success: false,
            summary: "Bad execute payload: \(error.localizedDescription)",
            paths: []
        ))
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

private func finish(request: ExecuteRequest, result: ExecResult) {
    appState.recordLog(ExecLogEntry(
        actionId: request.actionId,
        success: result.success,
        summary: result.summary,
        paths: request.paths
    ))
    notify(result: result, actionId: request.actionId)
}
```
Requests now run concurrently (a long script no longer delays the next click). That is intended.

**Verify**: `./Scripts/dev.sh` builds with no new warnings in `IPCServer.swift` (inspect the xcodebuild output: `./Scripts/dev.sh 2>&1 | grep -n "IPCServer.swift.*warning"` → no output).

### Step 5: Manual smoke test

1. Quit any running FinderActions. Launch `./build/DerivedData/Debug/Build/Products/Debug/FinderActions.app`.
2. Create `~/Library/Application Support/FinderActions/Actions/fa-noisy.zsh` containing `#!/bin/zsh` and `head -c 500000 /dev/zero | tr '\0' x; echo; echo done` and add a manifest entry via Settings (Shell Script, script file `fa-noisy.zsh`) — or edit `manifest.json` following the README example.
3. Right-click any file in Finder → run it. Expected: a notification/log entry appears within a few seconds; the menu-bar hammer menu opens immediately while it runs.
4. Remove the test action and script afterwards.

Report the result; if Finder setup isn't possible in your environment, say so — do not skip silently.

## Test plan

- 7 new unit tests in `ProcessRunnerTests.swift` (step 2): exit code/streams, >64 KB both streams, env + cwd, timeout, background grandchild, empty argv, missing executable.
- Manual smoke test (step 5) for the Host threading change.

## Done criteria

- [ ] `./Scripts/test.sh` passes with 7 more tests than before
- [ ] `./Scripts/dev.sh` succeeds
- [ ] `grep -n "waitUntilExit" Apps/Shared/Sources/Execution/ActionExecutor.swift` → no output
- [ ] `grep -n "Task.detached" Apps/Host/Sources/IPC/IPCServer.swift` → 1 match
- [ ] Only in-scope files changed (`git status`); pbxproj restored if untouched by design
- [ ] `plans/README.md` row updated

## STOP conditions

- `largeOutputDoesNotDeadlock` or `backgroundChildHoldingPipeDoesNotHang` hangs or fails twice after a fix attempt — report with output; do not switch to an unbounded `readDataToEndOfFile` approach.
- Fixing Swift 6 concurrency errors would need `nonisolated(unsafe)` beyond the one sanctioned in step 1, or `@preconcurrency` imports — report.
- `ActionExecutor` is no longer compiled into both Host and Settings targets (check `project.yml` `Apps/Shared/Sources`) — report.

## Maintenance notes

- Concurrency: requests now run in parallel. `ExecLogStore.append` serializes via its own queue and is called on the main actor in `finish`, so log writes stay ordered per completion.
- `NSWorkspace` calls in `runApplication`/`openDirectory` now run off-main; they use semaphores with 10 s timeouts and are thread-safe.
- Plan 007 will extend `finish` to log stderr; plan 005 will insert validation before `Task.detached`.
- Deferred: a user-configurable per-action timeout (would need a manifest field + Settings UI).
