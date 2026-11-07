# Product workflow verification — 2026-11-06

Reviewed implementation: `caad1b6`, branch `codex/product-workflows`, worktree `/private/tmp/finder-menu-product-workflows`. Baseline `7f501db`. All six product capabilities implemented. Branch is committed and clean, not merged/pushed. Original checkout source and existing plan files preserved.

## Authoritative verification

- Reviewer independently ran `./Scripts/test.sh` after final source changes: **84 Core tests in 13 suites + 26 application tests in 5 suites = 110 passed**, exit 0. Log `build/reviewer-final-test.log` in implementation worktree.
- Reviewer independently ran `./Scripts/dev.sh`: Debug application build and Host-without-SwiftUI boundary passed, exit 0 (`build/reviewer-build.log`). Last scoped revision also rebuilt successfully (`build/revision2-build.log`).
- Reviewer confirmed final clean git status and `git diff --check 7f501db` exit 0. Generated worktree-name changes normalized by executor; genuine new source membership retained.

## Requirement coverage

| Requirement | Production evidence | Automated evidence | Actual GUI observation |
|---|---|---|---|
| Real-input test and preview | Settings Actions/LiveTestSession.swift, LiveTestConsole.swift | LiveTestSessionTests: exact production argv/environment, real executor Unicode/spaces/multiple files, container fallback, missing files/scripts, stale input/action rejection, stale validation generations | Created template, chose JPEG and PNG with Chinese/spaces, ran successfully; log displayed 2 paths. Chooser/removal controls and preview entry observed. |
| Matching rules | ActionInspectorView displaySection/ruleSummary, ActionAuthoring normalization/validation, existing shared matcher | Existing ShowWhenTests plus authoring tests cover normalization, conflicting rules and preview visibility | Entered `png, jpg`, enabled action, summary showed `.jpg, .png`, both selected images described as visible. |
| Templates and script source | ActionTemplate, ActionAuthoring, AppState and ActionInspectorView | Draft/default/duplicate disabled, incomplete application blocked, legacy dual-source round trip and switching, actual template execution | New-action template sheet and default-disabled per-file action observed; resolved external-script path and source chooser observed. |
| Verified onboarding | WorkflowFeedback, HostRuntimeState recording Finder source, OnboardingView, structured registration | ExecutionFeedbackTests: registration states, skip distinct from verification, Settings tests/unrelated/failed runs excluded, successful Host Finder copy-path accepted | Isolated onboarding displayed tool selectors, enabled-but-unverified status, waiting label and disabled Finish; Skip dismissed onboarding. |
| Execution feedback | HostRuntimeState active runs, StatusMenuController, IPCServer, log additions, navigation, notification modes | Independent concurrent lifetimes, saturation rejection/resumption, rejected request cleanup, legacy logs, all/failures/off migration, local routing notification | Logs showed readable names, path counts, duration and test source; notification menu all/failures/off and selected failures-only observed. |
| Single-action sharing | PortableActionPackage, ActionTransferView, ActionsSettingsView | PortableActionPackageTests: inline/file/AppleScript round trips, disabled imports, new IDs/conflict suffixes, invalid versions/references/sizes, symlinks, incomplete actions, no execution and rollback | Exported `.faaction` with Chinese dependency notes; first-import preview displayed script and notes; confirmed import created `(2)` suffix with both originals/import disabled. |

## Review corrections

- Fixed first-import empty-sheet race found through actual GUI; item-bound presentation retested successfully.
- Fixed save-panel duplicate default extension, editing delimiters, stale preview execution, source-picker cancellation, incompatible rules, close/quit while testing, and cross-process preferences refresh.
- Kept local navigation working in isolated QA while suppressing distributed writes to live sessions.
- Added bilingual strings and checked compiled/runtime Chinese lookup for new rule-summary and visibility messages.

## Limits of verification

GUI checks used disposable `build/qa-ui` and `build/qa-onboarding` roots and memory preferences. They do not prove live Finder extension registration/delivery, real protected-folder permission prompts, or system notification delivery/click behavior. These platform scenarios have executable instructions in implementation `docs/troubleshooting.md`; automated tests verify the production state/IPC handlers and notification policy, not macOS permission decisions. No signed release, installation, publication or authenticated-IPC claim is part of this change. Process descendant cancellation remains unsupported and is not offered by the UI.

The advisor reviewed the complete functional changes, test assertions, package boundaries, source membership and generated project diff. Verdict: APPROVE for the implemented scope, with platform verification limits above retained explicitly.
