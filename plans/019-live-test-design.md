# Live Test inputs and preview — design proposal

Status: design complete; feature not implemented. Baseline 9898180, 2026-11-06.

## Problem

Home-only testing cannot exercise file-only actions, multi-selection, or a Finder
container different from the selected file's parent. Users must switch to Finder
to validate scripts they are editing.

## Current behavior

ActionInspectorView.runLiveTest captures the action and calls execute(action:)
with the user's home as the only path and container. This is real execution.
ActionExecutor falls back to a nonempty container when selection is empty.
ShellEnvironment chooses container first, otherwise the first folder or file's
parent. Inline argv is `[interpreter, "-c", source, "fa-action"] + resolvedPaths`;
file argv is `[interpreter, scriptPath] + resolvedPaths`. Preview must show these
actual values, including the dummy argv zero. Settings intentionally bypasses
Finder showWhen eligibility when testing directly.

## Proposed controls

Keep the grouped Form and localized labels. Add a Home preset (default for migration),
Choose Files or Folders (NSOpenPanel, multiple selection, explicit order display),
Clear Selection, and separate Use Selection Context / Choose Container controls.
Cancel in an open panel leaves prior inputs intact. Display selected inputs in a
scrollable list with a Remove button per row. A container override must be an
existing directory. Changing inputs refreshes preview only, never starts execution.
The Run Test button remains an explicit real-action trigger.

## Execution semantics

Preview shows the captured action ID/type, resolved ordered selection, effective
working directory, exact argv, and FA_CWD/FA_PATHS/FA_PATH_COUNT/FA_CONTAINER/
FA_ACTION_ID only. Do not show the inherited environment, which may contain secrets.
For shell actions use production ShellEnvironment helpers; AppleScript/application/
terminal previews describe their actual launcher instead of inventing shell argv.
No selection plus a valid container resolves to that container, matching the executor.
No selection and no container is blocked in this proposed UI. File status checks and
preview building run off the main actor, publishing only the latest input generation.
A showWhen eligibility hint explains Finder visibility, but does not block deliberate
Settings testing of an otherwise valid action. Snapshot action and inputs on Run.

State transitions: idle → validating → ready or invalid; ready → running after Run;
running → success/failure after completion. Input edits invalidate the previous preview
and result, except the running capture stays immutable. During running disable Run,
input changes, duplicate/delete of this action, and preset changes. Repeated Run after
completion is allowed and creates a new log row. Do not auto-retry a failed operation.

## Failure states

Missing/unreadable paths show a path-level error and disable Run until revalidated.
Unsupported builtin action shows unsupported status and disables Run. A missing script
shows the same error as execution; no silent inline fallback. Empty selection/container
shows an instruction to choose input. Closing a panel cancels selection only.
ProcessRunner cannot reliably cancel descendants, so no Stop/Cancel execution control
is promised. Switching action leaves the captured run associated with its original ID;
a session-level run record must own it so the result cannot appear on another action.
Closing Settings during a run offers Keep Open / Close and explains that close may
interrupt the test without rolling back side effects. Do not claim background completion
or cancellation. Existing configuration save recovery remains authoritative on close.
Never request or grant Full Disk Access automatically; explain permission failure.

## Accessibility/localization

All controls need stable localized English/Chinese labels, keyboard focus order,
VoiceOver descriptions for real execution and working-directory override, and text
selection/copy in the preview. Distinguish validation progress from script progress.
Do not rely on green/red alone for success/failure. Long paths wrap/truncate with
accessible full text; preserve Unicode and whitespace in copying.

## Alternatives

Using current Finder selection requires extra integration and is deferred. An entire
script debugger, sandbox, dry-run interpreter, or automatic script execution on edit
would expand the product and is rejected for this feature. A preset-only UI is smaller
but does not address files/multi-selection and is insufficient.

## Implementation boundaries

Future files: Apps/Settings/Sources/Features/Actions/ActionInspectorView.swift,
a small Apps/Settings/Sources/Features/Actions/LiveTestSession.swift owning captured
inputs/results, Apps/Host/Resources/Localizable.xcstrings, and
Tests/AppIntegrationTests/LiveTestSessionTests.swift. Add explicit test target membership
in Package.swift. Reuse AppState executor/logging and the real ShellEnvironment helpers;
do not copy their path resolution. Inject temporary file fixtures and in-memory
preferences. Test generation cancellation, captured inputs and outcome ownership.
No Finder IPC, Host launch policy or production script-format changes are required.

## Open decisions

Recommended defaults awaiting implementation review: preserve Home as default; block
no selection/no container; allow eligibility-mismatched explicit tests with a hint;
keep one active test per Settings session; do not promise process cancellation.
Decide whether Close warning should offer only Keep Open initially; a safe first
implementation may refuse close until the run finishes, but must label that behavior.

## Recommendation

Implement the session/preview model first with temporary filesystem fixtures, then
wire controls to the existing Form. Complete configuration recovery and log refresh
plans first. The scenario matrix records the proposed semantics; its checker verifies
this document contract only. A future implementation must test the production helpers
and must not treat document-check success as proof the UI exists.
