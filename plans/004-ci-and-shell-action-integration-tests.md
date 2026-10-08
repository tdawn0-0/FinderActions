# Plan 004: CI runs tests + app build on every push, and the shell-action path has end-to-end tests

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 2e59370..HEAD -- .github Scripts/test.sh Scripts/dev.sh Package.swift Tests/FinderActionsCoreTests`
> Plan 003 is expected to have added `ProcessRunnerTests.swift`. Any other change → compare with excerpts; mismatch → STOP.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: plans/003-process-runner-off-main.md (integration tests use `ProcessRunner`)
- **Category**: tests / dx
- **Planned at**: commit `2e59370`, 2026-10-02

## Why this matters

The repo has a good local test script (35 Swift Testing tests) and a build script that verifies the Host does not link SwiftUI, but nothing runs them automatically — there is no `.github/` directory. The release script runs tests, so regressions are only caught at release time. Also, the code path the product exists for — "run a user's shell script with the selected Finder paths" — has unit tests for its pieces (`ShellEnvironment` argv/env) but none that actually executes a script and checks what it receives. After this plan, every push/PR runs `swift test`, `swift build` and the Debug app build + dependency check, and two integration tests prove that paths with spaces, quotes, `$` and Unicode reach the script intact.

## Current state

- No `.github/` directory exists.
- `Scripts/test.sh`:
```bash
swift test --package-path "$PROJECT_ROOT" --scratch-path "$PROJECT_ROOT/build/SwiftPM"
```
- `Scripts/dev.sh` requires `xcodegen` (`brew install xcodegen`), runs `xcodegen generate`, then `xcodebuild … -configuration Debug -destination "generic/platform=macOS" … CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=NO build`, then `Scripts/check-host-dependencies.sh` which prints `Dependency boundary verified: Host excludes SwiftUI; Settings owns SwiftUI.`
- No `DEVELOPMENT_TEAM` is set in `project.yml` or `project.pbxproj`, so ad-hoc signing works without credentials.
- Requirements (README): macOS 15+, Xcode 16+, Swift tools 6.0 (`Package.swift`).
- `Package.swift` targets: `FinderActionsCore` (library), `FinderActionsCoreTests`, `ShellExecHarness` (executable in `Tools/ShellExecHarness`).
- Relevant Core APIs (in `Packages/FinderActionsCore/Sources/Quoting/ShellEnvironment.swift`):
  - `ShellEnvironment.makeEnvironment(paths:containerPath:actionId:base:) -> [String: String]` — sets `FA_CWD`, `FA_CONTAINER`, `FA_PATHS` (newline-joined), `FA_PATH_COUNT`, `FA_ACTION_ID`.
  - `ShellEnvironment.argvForScriptFile(interpreter:scriptPath:paths:) -> [String]` → `[interpreter, scriptPath] + paths`.
  - `ShellEnvironment.argvForInlineScript(interpreter:script:paths:) -> [String]` → `[interpreter, "-c", script, "fa-action"] + paths`.
  - `ShellEnvironment.resolvedWorkingDirectory(paths:containerPath:)`.
- From plan 003: `ProcessRunner.run(argv:environment:workingDirectory:timeout:) throws -> ProcessOutput` (`exitCode`, `stdout`, `stderr`, `timedOut`) in `Packages/FinderActionsCore/Sources/Execution/ProcessRunner.swift`.
- Test convention: see `Tests/FinderActionsCoreTests/ShellEnvironmentTests.swift` (Swift Testing, `@Suite`, `@Test`, `#expect`; uses awkward paths like `"/Users/me/proj/it's_$weird.txt"`, `"/tmp/中文.swift"`).

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Core tests | `./Scripts/test.sh` | `Test run with N tests … passed` |
| Filtered | `swift test --package-path . --scratch-path build/SwiftPM --filter ShellActionIntegration` | 2 pass |
| Build all SwiftPM products | `swift build --package-path . --scratch-path build/SwiftPM` | `Build complete!` |
| Validate workflow YAML | `ruby -ryaml -e 'YAML.load_file(".github/workflows/ci.yml"); puts "ok"'` | `ok` |

## Scope

**In scope**:
- `Tests/FinderActionsCoreTests/ShellActionIntegrationTests.swift` (create)
- `.github/workflows/ci.yml` (create)

**Out of scope**: `Scripts/*.sh` (do not change), `project.yml`, release workflow/notarization (needs secrets — never add signing credentials to CI), the `web/` project.

## Git workflow

- Branch `advisor/004-ci-and-integration-tests`; commits like `test(core): add shell action integration tests`, `ci: run swift tests and debug build on macOS`. Do not push unless instructed (CI only runs once pushed; that is the operator's call).

## Steps

### Step 1: Integration tests

Create `ShellActionIntegrationTests.swift`, `@Suite("Shell action integration")`. Each test creates a fresh temp directory (`FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)`), creates real files inside it with these names: `a b.txt`, `it's_$weird.txt`, `中文.swift`, and removes the directory in a `defer`.

1. `scriptFileReceivesPathsAndEnvironmentIntact`
   - Write `echo-args.zsh` into the temp dir with contents:
     ```
     #!/bin/zsh
     for p in "$@"; do print -r -- "ARG:$p"; done
     print -r -- "COUNT:$FA_PATH_COUNT"
     print -r -- "ID:$FA_ACTION_ID"
     print -r -- "CWD:$PWD"
     ```
   - `paths` = the three file paths; `env = ShellEnvironment.makeEnvironment(paths: paths, containerPath: tempDir.path, actionId: "it-test", base: ["PATH": "/usr/bin:/bin"])`; `argv = ShellEnvironment.argvForScriptFile(interpreter: "/bin/zsh", scriptPath: <script path>, paths: paths)`; `cwd = ShellEnvironment.resolvedWorkingDirectory(paths: paths, containerPath: tempDir.path)`.
   - Run `ProcessRunner.run(argv:environment:workingDirectory:)`.
   - Expect `exitCode == 0`; stdout lines include `"ARG:" + p` for each path, in order; `"COUNT:3"`; `"ID:it-test"`. For CWD compare against the resolved physical path: `"CWD:" + (tempDir.path as NSString).resolvingSymlinksInPath` **or** `"CWD:" + tempDir.path` (temp dirs live under `/var` → `/private/var`; accept either).
2. `inlineScriptReceivesPathsAsPositionalArgs`
   - `argv = ShellEnvironment.argvForInlineScript(interpreter: "/bin/zsh", script: #"for p in "$@"; do print -r -- "ARG:$p"; done"#, paths: paths)`; same env/cwd.
   - Expect `exitCode == 0` and exactly three `ARG:` lines equal to the paths, in order (proves `fa-action` occupies `$0`, not `$1`).

**Verify**: filtered command → 2 pass; `./Scripts/test.sh` → all pass.

### Step 2: CI workflow

Create `.github/workflows/ci.yml`:
```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  macos:
    runs-on: macos-15
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - name: Toolchain versions
        run: |
          xcodebuild -version
          swift --version

      - name: Swift package tests
        run: ./Scripts/test.sh

      - name: Build all package products
        run: swift build --package-path . --scratch-path build/SwiftPM

      - name: Install XcodeGen
        run: brew install xcodegen

      - name: Debug app build + Host dependency boundary
        run: ./Scripts/dev.sh
```
**Verify**: YAML validation command → `ok`. `swift build …` locally → `Build complete!`.

## Test plan

- 2 new integration tests (step 1).
- CI itself is verified when the operator pushes the branch: the `macos` job must be green. Record in the report that it was not run (if you could not push).

## Done criteria

- [ ] `./Scripts/test.sh` passes with 2 more tests than after plan 003
- [ ] `.github/workflows/ci.yml` exists and the YAML check prints `ok`
- [ ] `grep -n "secrets\." .github/workflows/ci.yml` → no output (no credentials in CI)
- [ ] Only in-scope files added; `plans/README.md` row updated

## STOP conditions

- `ProcessRunner` does not exist (plan 003 not applied) — STOP; do not write an ad-hoc process helper in the test.
- An integration test reveals a real argument-passing bug (e.g. a path arrives split or with `$` expanded) — STOP and report the failing output; that is a product bug, not a test to adjust.
- After push, CI fails in `dev.sh` because of code signing — report the log; do not add signing secrets.

## Maintenance notes

- Default Xcode on `macos-15` runners changes over time; if builds break after an image update, pin with `sudo xcode-select -s /Applications/Xcode_<ver>.app`.
- Consider later adding `git diff --exit-code FinderActions.xcodeproj/project.pbxproj` after `dev.sh` to catch a committed project out of sync with `project.yml` (deferred: xcodegen version differences may cause noise).
- `web/` has its own `npm run build`/`lint`; a separate job could be added if the site starts changing often.
