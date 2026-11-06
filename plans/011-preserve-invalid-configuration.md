# Plan 011: Preserve configuration on read/write failure

> **Executor instructions:** Read the entire plan; implement only its scope. Run
> each step's verification and compare the stated result. Stop on the conditions
> below rather than silently expanding the task. Update this plan's status row in
> `plans/README.md` when verified, unless your reviewer owns that index.
>
> **Drift check first:** `git diff --stat 9898180..HEAD -- Packages/FinderActionsCore/Sources/Manifest/ManifestStore.swift Apps/Shared/Sources/Configuration/SharedConfiguration.swift Apps/Shared/Sources/Configuration/AppPreferences.swift Apps/Settings/Sources/App/AppState.swift Apps/Settings/Sources/App/SettingsAppDelegate.swift Apps/Settings/Sources/Features/SettingsRootView.swift Apps/Host/Sources/App/HostRuntimeState.swift Apps/Host/Resources/Localizable.xcstrings Package.swift Tests/FinderActionsCoreTests/ManifestTests.swift Tests/AppIntegrationTests/ConfigurationPersistenceTests.swift .github/workflows/ci.yml`.
> Also inspect `git status --short` and existing uncommitted changes. Compare live
> code with the excerpts below. Unexplained differences require stopping; changes
> from listed prerequisites require re-reading and documenting the adapted baseline.

## Status

- **Priority:** P1
- **Effort:** M
- **Risk:** MED
- **Category:** bug + tests
- **Depends on:** none
- **Planned at:** commit `9898180`, 2026-11-06
- **Status:** DONE (reviewed in isolated integration branch; see index verification)

## Why this matters

An existing malformed manifest currently becomes an apparently valid empty state.
Adding an action in Settings then overwrites the original bytes. Write failures
are swallowed as well, so edits disappear on restart. Preserve recoverable data,
report errors, and retain automated coverage of the real application state.

## Current state and conventions

`ManifestStore.swift:62`: `(try? load()) ?? ActionManifest()` is `loadOrEmpty`.
`SharedConfiguration.swift:16-22` checks existence, calls `store.loadOrEmpty()`,
then returns the resulting base manifest. `HostRuntimeState.swift:42` repeats this
fallback on reload. `AppState.swift:56-61` currently does:

```swift
pendingSave?.cancel()
pendingSave = nil
manifest = OpenWithActions.baseManifest(from: manifest)
try? store.save(manifest)
onManifestChanged?()
```

`SettingsAppDelegate.applicationWillTerminate` flushes pending saves but cannot
cancel termination on failure. `AppPreferences` writes the production Host's
CFPreferences domain; tests MUST NOT bootstrap against that domain.
The existing `ManifestError: Error, LocalizedError, Equatable` is the error-style
exemplar. `ManifestTests.manifestStoreSaveAndLoad` uses a UUID temporary directory
and `defer { try? FileManager.default.removeItem(at: root) }`; match this isolation.
Keep the 400 ms debounce, generated Open With stripping, and missing-script seeding.

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
- `Packages/FinderActionsCore/Sources/Manifest/ManifestStore.swift`
- `Apps/Shared/Sources/Configuration/SharedConfiguration.swift`
- `Apps/Shared/Sources/Configuration/AppPreferences.swift`
- `Apps/Settings/Sources/App/AppState.swift`
- `Apps/Settings/Sources/App/SettingsAppDelegate.swift`
- `Apps/Settings/Sources/Features/SettingsRootView.swift`
- `Apps/Host/Sources/App/HostRuntimeState.swift`
- `Apps/Host/Resources/Localizable.xcstrings`
- `Package.swift`
- `Tests/FinderActionsCoreTests/ManifestTests.swift`
- `Tests/AppIntegrationTests/ConfigurationPersistenceTests.swift`
- `.github/workflows/ci.yml`

Also update only this plan's status/evidence in `plans/README.md`.
All other files, the installed app, user configuration, user scripts, signing
credentials, and live deployment are out of scope. A generated
`FinderActions.xcodeproj/project.pbxproj` change is allowed only where explicitly
listed and must contain only the source membership changes required by this plan.

## Git workflow

Use an isolated branch `codex/011-preserve-invalid-configuration` when dispatched to implement.
Match conventional commit style (e.g. `fix(host): validate execute requests against action filters`).
Do not merge, push, publish, or commit to the user's branch without separate instructions.

## Steps

### Step 1: Establish a durable, isolated application-state test target

Add a macOS SwiftPM test target `FinderActionsAppTests` with explicit sources under
root `path: "."`: AppState, HostRuntimeState, SharedConfiguration, AppPreferences,
ActionExecutor, ExecLogStore, and `Tests/AppIntegrationTests/ConfigurationPersistenceTests.swift`.
Depend on FinderActionsCore; do not compile either app's @main delegate or SwiftUI
views into this target. Add the minimal preferences injection seam to configuration
and AppState/HostRuntimeState initializers, defaulting to the existing production
adapter. Use an in-memory adapter in tests, not environment overrides of the live
domain. Add characterization cases for valid load, defaults, migration, script
preservation, debounce/flush and explicit reset. The existing CI test command should
discover both targets without a new workflow job.

**Verify:** `./Scripts/test.sh` → all existing 66 tests plus the new characterization
suite pass; test setup names only temporary file paths and in-memory preferences.

### Step 2: Make load/save outcomes explicit

Stop using loadOrEmpty on production configuration paths. A missing manifest may
seed defaults; an existing unreadable/invalid manifest must remain untouched.
Propagate typed failure through SharedConfiguration. Host reload retains its last
valid manifest on failure; first-start failure may use an empty in-memory manifest
but must record the error and never persist that fallback. Keep generated application
preferences usable. Settings exposes configuration error, dirty state, and a
write-blocked state after failed load. Block automatic saves/add/delete persistence
until successful explicit reload or confirmed reset; preserve the original bytes.
On save failure retain dirty state, show the error, and do not invoke reload callback.
Only mark clean/notify Host after successful save. A failed migration write is an
error, not permission to overwrite again unnoticed.

**Verify:** `swift test --scratch-path build/SwiftPM --filter ConfigurationPersistenceTests`
→ malformed input remains byte-identical, failed saves do not notify, and successful
retry clears dirty/error state. Use a parent-path-as-regular-file fixture for write
failure rather than permission bits that behave differently under privileged users.

### Step 3: Surface recovery and protect termination

Present a localized error/recovery area in SettingsRootView using the existing
SwiftUI Environment AppState pattern. Provide Reload from Disk and Retry Save where
applicable; reset remains the existing explicit destructive flow. Do not auto-reset
invalid data. In applicationShouldTerminate flush pending edits and cancel termination
on an unresolved save failure; present explicit Retry/Discard/Cancel choices.
Discard ends the session without writing invalid or unsaved state. Keep
applicationWillTerminate as a defensive no-op/flush only when no failed save remains.
Host failures go to its local log without copying raw manifest/script contents.

**Verify:** `./Scripts/test.sh` → all pass; `./Scripts/dev.sh` → build and Host
boundary check pass. Record GUI checks for invalid load recovery and close-after-
failed-save; if unavailable, mark them unverified instead of claiming coverage.

## Test plan

Use Swift Testing `@Suite`/`@Test`/`#expect`, matching ManifestTests.
Persist tests for: missing vs valid-empty vs malformed input; exact invalid-byte
preservation after attempted edit; Host reload retaining last-good state; failed
migration; failed write with no callback; retry once writable; debounce latest edit;
flush-before-close; explicit reset clearing blocked state; no production preference
writes. Prefer injectable save errors and controlled scheduling over fragile sleeps.
The test target must compile actual application sources, not copied implementations.

## Done criteria

- [ ] Both `./Scripts/test.sh` and `./Scripts/dev.sh` exit 0.
- [ ] `swift test --scratch-path build/SwiftPM --filter ConfigurationPersistenceTests` passes.
- [ ] `rg -n 'loadOrEmpty' Apps/Shared/Sources/Configuration Apps/Host/Sources/App` finds no calls.
- [ ] Regression tests assert original bytes, last-good Host state, dirty state and callback counts.
- [ ] Close failure has an explicit recovery path; GUI evidence or its absence is recorded.
- [ ] `git diff --check` exits 0.
- [ ] `git diff --name-only` and `git status --short` contain only in-scope changes.
- [ ] The index row records results and any explicitly unverified manual gates.

## STOP conditions

- Unexplained drift from the excerpts or conflicting user changes.
- A verification gate fails twice after a reasonable repair attempt.
- Completion requires an out-of-scope file or a live user-data mutation.
- The proposed test target requires launching the real app, touching live preferences,
  or granting Full Disk Access. Redesign isolation before continuing.
- Recovery would require deleting or silently replacing the malformed file.
- New target source membership requires broad Xcode project restructuring.

## Maintenance notes

Keep persistence outcomes and UI error recovery in sync. Future watchers/import
features must reuse these safeguards. Do not use the test baseline as an excuse
for an unrelated architecture rewrite. AppDelegate termination UI remains a manual
integration gate even when state transitions are unit-tested.

