# Plan 013: Fail production DMG packaging on verification failure

> **Executor instructions:** Read the entire plan; implement only its scope. Run
> each step's verification and compare the stated result. Stop on the conditions
> below rather than silently expanding the task. Update this plan's status row in
> `plans/README.md` when verified, unless your reviewer owns that index.
>
> **Drift check first:** `git diff --stat 9898180..HEAD -- Scripts/build-dmg.sh Scripts/release.sh Scripts/test-dmg-release.sh Tests/ReleaseFixtures docs/releasing.md docs/releasing.zh-Hans.md .github/workflows/ci.yml`.
> Also inspect `git status --short` and existing uncommitted changes. Compare live
> code with the excerpts below. Unexplained differences require stopping; changes
> from listed prerequisites require re-reading and documenting the adapted baseline.

## Status

- **Priority:** P1
- **Effort:** S
- **Risk:** LOW
- **Category:** security + dx
- **Depends on:** none
- **Planned at:** commit `9898180`, 2026-11-06
- **Status:** DONE (reviewed in isolated integration branch; see index verification)

## Why this matters

DMG notarization and Gatekeeper failures can return success to release.sh.
The app ZIP already has strict gates, but the DMG helper can still print Packaging
Complete for an unverified image. Distinguish explicitly local packaging from a
production release and test negative branches without credentials or Apple requests.

## Current state and conventions

`build-dmg.sh:129`: `NOTARY_STATUS="$(plutil -extract status raw -o - "$DMG_NOTARY_JSON" 2>/dev/null || echo "Accepted")"`.
At line 134 Gatekeeper is followed by `|| true`; rejected/submission/profile
failures at lines 136-142 merely warn/skip. At line 102 create-dmg failure is also
ignored if an output file exists. `release.sh:197` invokes the helper before
printing Release Complete. Match release.sh's stricter exemplar:

```bash
if [[ "$NOTARY_STATUS" != "Accepted" ]]; then
  echo "Notarization status is '$NOTARY_STATUS', not 'Accepted'." >&2
  exit 1
fi
```

Both scripts use `set -euo pipefail`, quoted paths and a keychain profile. Never
print or commit .release.env contents or credential values.

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
- `Scripts/build-dmg.sh`
- `Scripts/release.sh`
- `Scripts/test-dmg-release.sh`
- `Tests/ReleaseFixtures`
- `docs/releasing.md`
- `docs/releasing.zh-Hans.md`
- `.github/workflows/ci.yml`

Also update only this plan's status/evidence in `plans/README.md`.
All other files, the installed app, user configuration, user scripts, signing
credentials, and live deployment are out of scope. A generated
`FinderActions.xcodeproj/project.pbxproj` change is allowed only where explicitly
listed and must contain only the source membership changes required by this plan.

## Git workflow

Use an isolated branch `codex/013-strict-dmg-release` when dispatched to implement.
Match conventional commit style (e.g. `fix(host): validate execute requests against action filters`).
Do not merge, push, publish, or commit to the user's branch without separate instructions.

## Steps

### Step 1: Add strict production mode

Give build-dmg.sh an explicit `--release` mode while preserving positional app/output
arguments and an explicitly documented local packaging mode. release.sh must pass
--release. In release mode require signing identity, valid profile and notarization;
reject SKIP_NOTARIZATION=true rather than silently weakening release gates.
Require successful create-dmg, sign/verify, status parse with exact Accepted,
staple/validate and spctl. Missing/malformed status is failure. Emit completion and
checksums only after every applicable gate succeeds. Local unsigned output must be
labelled unverified, not release-ready. Keep release.sh's already strict ZIP checks.

**Verify:** `bash -n Scripts/build-dmg.sh Scripts/release.sh` → exit 0.

### Step 2: Add isolated branch tests and CI

Create Scripts/test-dmg-release.sh (new), with temporary fake app/plist and stub tools
on PATH. Copy the two scripts to a disposable test root so they cannot source the
real .release.env. Keep real filesystem utilities; stub create-dmg, security,
codesign, xcrun, plutil and spctl. A harmless real PlistBuddy may read the synthetic
plist; no installed app, keychain or network access is permitted. Have stubs log
invocations to a temporary file and return controlled statuses. Exercise the release
helper and stubbed release orchestration so a failed DMG cannot produce Release
Complete. Add this inexpensive command to the macOS CI job. Document mode semantics
in both release guides.

**Verify:** `bash Scripts/test-dmg-release.sh` → all matrix cases pass, no real
signing/notarization command invoked. `bash -n Scripts/test-dmg-release.sh` → exit 0.

## Test plan

Test Accepted success; rejected status; missing/malformed status; submit timeout/
failure; absent profile; absent identity; forbidden skip flag; create-dmg exits
nonzero after leaving a partial image; codesign/staple/validate/spctl failures;
explicit local unsigned mode; paths with spaces. Assert exit codes, absence of
success banner/checksum on failure, and propagation through release.sh. Fixtures
contain no identifiers/credentials copied from the user's machine.

## Done criteria

- [ ] `bash Scripts/test-dmg-release.sh` exits 0 for the full success/failure matrix.
- [ ] `bash -n Scripts/build-dmg.sh Scripts/release.sh Scripts/test-dmg-release.sh` exits 0.
- [ ] CI invokes the new hermetic test script.
- [ ] No Accepted fallback or ignored Gatekeeper failure remains in the release path.
- [ ] No real release, signature, notarization submission or deployment was performed.
- [ ] `git diff --check` exits 0.
- [ ] `git diff --name-only` and `git status --short` contain only in-scope changes.
- [ ] The index row records results and any explicitly unverified manual gates.

## STOP conditions

- Unexplained drift from the excerpts or conflicting user changes.
- A verification gate fails twice after a reasonable repair attempt.
- Completion requires an out-of-scope file or a live user-data mutation.
- Existing create-dmg versions require a nonzero success exception: identify and
  document the exact status before accepting it; never restore blanket `|| true`.
- Tests would source real .release.env or execute real security/notarytool calls.
- Strict mode needs changes to signing ownership or credential provisioning.

## Maintenance notes

Add tests whenever new packaging gates are added. Distinguish an app's notarization
from the outer DMG's verification. Real signed-release validation remains a later
release operation; mock success is not evidence of Apple acceptance.

