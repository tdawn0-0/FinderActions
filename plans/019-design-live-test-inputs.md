# Plan 019: Design selectable Live Test inputs and execution preview

> **Executor instructions:** Read the entire plan, follow its steps and verification
> gates, and stop instead of expanding scope when a STOP condition applies. Update
> this plan's row in `plans/README.md` unless the dispatching reviewer owns the index.
>
> **Drift check first:** `git diff --stat 9898180..HEAD -- plans/019-live-test-design.md plans/019-live-test-scenarios.json plans/check-019-design.py`.
> Inspect `git status --short` too. Compare excerpts to live sources. Unexplained
> drift is a STOP condition; re-read and document adaptations from named prerequisites.

## Status

- **Priority:** P3
- **Effort:** M (design/spike only)
- **Risk:** MED
- **Category:** direction
- **Depends on:** none for design; implementation should follow 011/014
- **Planned at:** commit `9898180`, 2026-11-06
- **Status:** DONE (reviewed in isolated integration branch; see index verification)

## Why this matters

Live Test always passes the user's home directory as both selection and container.
That cannot exercise file-only, multi-selection or distinct working-directory scripts.
Specify a small, honest testing interface before implementation; do not build a
full debugger or execute user scripts as part of this design work.

## Current state and conventions

ActionInspectorView.swift:308-312 captures currentAction, then:

```swift
let homePath = FileManager.default.homeDirectoryForCurrentUser.path
let result = await Task.detached {
    executor.execute(action: currentAction, paths: [homePath], containerPath: homePath)
}.value
```

Its footer says `Runs against user home directory.` Execution is real, not dry-run.
ShellEnvironment supplies argv and FA_CWD/FA_PATHS/FA_PATH_COUNT/FA_CONTAINER/FA_ACTION_ID;
ActionExecutor resolves an empty selection to a nonempty container. Finder visibility
uses ShowWhenMatcher, but Settings tests currently call execute(action:) directly.
The UI uses grouped Forms, localized Label/Button controls and AppState; retain them.
This plan delivers a design decision and scenario matrix only.

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
- `plans/019-live-test-design.md`
- `plans/019-live-test-scenarios.json`
- `plans/check-019-design.py`

Also update this plan's row/evidence in `plans/README.md`. All other production
files, installed apps, user preferences/configuration, signing credentials and live
deployments are out of scope. Do not regenerate a tracked Xcode project unless it
is listed; if listed, retain only membership changes required by this plan.

## Git workflow

Use isolated branch `codex/019-design-live-test-inputs` for execution. Match conventional commits
(e.g. `fix(host): validate execute requests against action filters`). Do not merge,
push, publish, or commit to the user's branch without separate instructions.

## Read-only input drift check

Before design, run `git diff --stat 9898180..HEAD -- Apps/Settings/Sources/Features/Actions/ActionInspectorView.swift Apps/Shared/Sources/Execution/ActionExecutor.swift Packages/FinderActionsCore/Sources/Quoting/ShellEnvironment.swift`; re-read changed inputs and update the specification assumptions. These files remain read-only in this plan.

## Steps

### Step 1: Write the current/target behavior specification

Create plans/019-live-test-design.md with sections Problem, Current behavior,
Proposed controls, Execution semantics, Failure states, Accessibility/localization,
Alternatives, Implementation boundaries, Open decisions, and Recommendation.
Propose explicit file/folder multi-select, a separate container/working-directory
choice, and a preview of exact ordered argv plus only FA_* context (never the entire
process environment). Preserve a clearly labelled Home preset for compatibility.
Keep Run as an explicit real-action button; selection/preview must never execute.
Specify whether the preview explains showWhen eligibility while allowing an explicit
Settings test; do not silently change existing execution semantics. Include cancel,
missing path, no selection, unsupported action and repeated-run states. State how
switching/deleting actions and closing the helper interact with a running test;
if cancellation cannot terminate descendants safely, label it unavailable rather
than promising it. Do not grant Full Disk Access to Settings automatically.

**Verify:** `test -s plans/019-live-test-design.md` → exit 0; review every required
section against the existing ActionExecutor and ShellEnvironment source.

### Step 2: Add an executable scenario-contract check

Create plans/019-live-test-scenarios.json with named cases: home preset, one file,
one folder, multi-select, explicit container distinct from selected-path parent,
empty selection with container, paths containing spaces/quotes/Unicode, missing
path, action changed during run, close during run. Each has inputs, expected preview,
allowed controls and execution side-effect expectations. Use synthetic /tmp paths,
not personal paths. Create plans/check-019-design.py to validate required sections,
unique case IDs and complete fields, plus expected FA_PATH_COUNT/argv ordering for
static scenarios. This is a document consistency checker, not production validation.

**Verify:** `python3 plans/check-019-design.py` → exit 0 with every required case
present; malformed scenario data must be rejected (self-test mode or unit assertions).

### Step 3: Conclude with a bounded implementation handoff

In the design, name exact future files (ActionInspectorView, a small preview model,
its tests, localization), reuse the production ShellEnvironment implementation,
and describe temporary-file test isolation. List open product choices with a
recommended default. Explain migration from home-only behavior and explicitly
separate approved design from future implementation. No production code changes.

**Verify:** `python3 plans/check-019-design.py` → all sections and scenarios valid;
`git diff --name-only` → only this plan's allowed plans/ artifacts and index.

## Test plan

Validate the scenario JSON and section contract; manually review consistency with
ShellEnvironment.resolvedWorkingDirectory and ActionExecutor's empty-selection
fallback. Future implementation tests must call real helpers, not reimplement path
rules. No live destructive scripts, browser mockup or Figma work is needed.

## Done criteria

- [ ] Design contains every named section, precise state transitions and explicit real-run wording.
- [ ] Scenario checker exits 0 and covers all ten named scenarios.
- [ ] Recommendation lists implementation scope and unresolved choices.
- [ ] Only plans/ files changed; no feature is described as already shipped.
- [ ] `git diff --check` exits 0.
- [ ] `git diff --name-only` and `git status --short` contain only scoped changes.
- [ ] The index records verification results and outstanding manual gates.

## STOP conditions

- Unexplained drift, conflicting user edits, or need to change an out-of-scope file.
- A verification gate fails twice after a reasonable repair attempt.
- The proposal requires executing arbitrary scripts or altering real user preferences to validate.
- Required cancellation guarantees are not supported by ProcessRunner; record a design limitation.
- Scope expands into a debugger, script sandbox or general workflow engine.

## Maintenance notes

The design may be marked DONE once reviewed as a design artifact, even when the
feature remains unimplemented. Keep that distinction in the index. Input previews
must continue to use the same production argv/environment builder when implemented.
