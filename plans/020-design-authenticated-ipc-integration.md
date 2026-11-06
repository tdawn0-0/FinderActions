# Plan 020: Specify the production-shaped authenticated IPC experiment

> **Executor instructions:** Read the entire plan, follow its steps and verification
> gates, and stop instead of expanding scope when a STOP condition applies. Update
> this plan's row in `plans/README.md` unless the dispatching reviewer owns the index.
>
> **Drift check first:** `git diff --stat 9898180..HEAD -- plans/020-ipc-integration-design.md plans/020-ipc-integration-matrix.json plans/check-020-design.py`.
> Inspect `git status --short` too. Compare excerpts to live sources. Unexplained
> drift is a STOP condition; re-read and document adaptations from named prerequisites.

## Status

- **Priority:** P3
- **Effort:** L (staged spike)
- **Risk:** HIGH for later integration; LOW for this document stage
- **Category:** direction + security
- **Depends on:** 006 completed ADR; 016/017 before any later production migration
- **Planned at:** commit `9898180`, 2026-11-06
- **Status:** DONE (reviewed in isolated integration branch; see index verification)

## Why this matters

The existing XPC prototype established limited peer-check behavior but did not test
real FinderSync, release signing, SMAppService/AppKit lifecycle or minimum-OS support.
Create a concrete integration experiment and decision gate. This plan does not
replace production notifications or register an agent on the user's machine.

## Current state and conventions

docs/adr/0001-authenticated-host-ipc.md is explicitly `Recommendation, needs
maintainer sign-off`. It recommends option A: a launchd-managed AppKit Host via
SMAppService.agent, advertising a Mach service; option B adds a separate helper if
Host lifecycle proves unsuitable. Prototype commit 083ccef on spike/006-xpc-ipc was
not merged. Production uses distributed notifications, version/path/filter validation
and a five-second request-ID dedupe window.

The ADR observed the wrong-server client sending an outgoing ping before its reply
was rejected. Therefore mutual signature requirements alone do not justify sending
paths immediately: require a nonsensitive hello/reply before any path-bearing call.
Authentication must cover execute requests AND snapshots; retaining unauthenticated
fallback consumers would preserve the vulnerability. App Groups provide sandbox
reachability, not role authorization. Host must remain AppKit-only and own execution.
Use the ADR's evidence/limits style; no claims of production verification from the old spike.

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
- `plans/020-ipc-integration-design.md`
- `plans/020-ipc-integration-matrix.json`
- `plans/check-020-design.py`

Also update this plan's row/evidence in `plans/README.md`. All other production
files, installed apps, user preferences/configuration, signing credentials and live
deployments are out of scope. Do not regenerate a tracked Xcode project unless it
is listed; if listed, retain only membership changes required by this plan.

## Git workflow

Use isolated branch `codex/020-design-authenticated-ipc-integration` for execution. Match conventional commits
(e.g. `fix(host): validate execute requests against action filters`). Do not merge,
push, publish, or commit to the user's branch without separate instructions.

## Read-only input drift check

Before design, run `git diff --stat 9898180..HEAD -- docs/adr/0001-authenticated-host-ipc.md docs/ipc.md Apps/Host/Sources/IPC/IPCServer.swift Extensions/FinderSync/IPCClient.swift`; re-read changed inputs and distinguish adopted decisions from proposals. These files remain read-only in this plan.

## Steps

### Step 1: Convert unresolved choices into an explicit experiment contract

Create plans/020-ipc-integration-design.md with sections Existing evidence,
Architecture candidates, Proposed default, Trust protocol, Lifecycle decisions,
Isolated packaging, Matrix, Measurements, Cleanup, Adoption gates, Open decisions.
Recommend A as the first experiment, B only if A fails lifecycle constraints.
Define quit/login/demand-start behavior explicitly as proposed choices awaiting
maintainer acceptance; do not assume ADR sign-off. Require exact Developer ID
Team/bundle/role checks (placeholders only), reject same-team wrong bundle, set peer
requirements before resume, and gate all paths/snapshots on a harmless hello.
Settings reload permission must not imply Finder execute permission. Preserve
validation/dedupe and specify request IDs, lost reply policy, reconnect and cached
last-authenticated snapshots. No unauthenticated compatibility execute/snapshot route.

**Verify:** `test -s plans/020-ipc-integration-design.md` → exit 0; compare every
claim against the ADR and label prototype evidence versus proposed work.

### Step 2: Specify isolated signed integration and cleanup

Define unique experimental bundle/service identifiers, isolated configuration/cache
paths, and a dedicated test account or disposable VM for real Finder registration.
List macOS 15 plus the current supported macOS as separate required environments;
record actual versions at execution time. Use explicit supplied signing identity
and group entitlement placeholders; never infer paid-account permission. Plan
checks for genuine sandboxed FinderSync, same-team wrong identifier, wrong server,
unsigned peer, sandbox denied lookup, and Settings role restriction. Define
SMAppService denied approval, install/upgrade/uninstall, login, quit, manual relaunch,
crash and duplicate-instance tests. Draft cleanup steps for only experiment-owned
registrations/files; never kill/re-register the user's production Finder extension.
This document stage must not perform those system mutations.

**Verify:** `rg -n '^## ' plans/020-ipc-integration-design.md` → all required
sections present; security/cleanup review confirms no production identifier is used
as an experimental registration target.

### Step 3: Write the evidence matrix and adoption gate

Create plans/020-ipc-integration-matrix.json. Each case records id, platform, peer
role/signing class, setup, expected outcome, evidence artifact, cleanup, status
(initially NOT_RUN) and blocking reason when needed. Include both allowed/denied
peer cases, forged legacy notifications, handshake-before-paths, lost reply/no
uncontrolled replay, reconnect/stale cache, every lifecycle case, and idle/peak
aggregate process footprint (not just one artificial listener's RSS).
Create plans/check-020-design.py validating required cases/fields, evidence rules
(PASS requires an artifact), and all document sections. The adoption gate must fail
closed on NOT_RUN/BLOCKED/FAIL; the document-quality check can pass while integration
remains NOT_RUN. Document future commands as planned harness contracts, not existing
scripts. End with a recommendation and a separate concrete authorization/inputs list
for the later isolated experiment; do not request them during this planning stage.

**Verify:** `python3 plans/check-020-design.py` → design/matrix valid;
`python3 plans/check-020-design.py --require-adoption-ready` → exits nonzero now,
listing unrun gates. That expected failure proves production adoption is not implied.

## Test plan

Document checker tests must reject missing cases, PASS without evidence, unknown
statuses and an adoption-ready claim with any unrun gate. No live credentials,
launchctl calls, SMAppService registration, signing, Finder restart or network
notarization is required for this stage. Future integration must collect positive
and negative controls on both OS environments with cleanup evidence.

## Done criteria

- [ ] Design checker exits 0; adoption-ready check fails for the initial NOT_RUN matrix.
- [ ] Trust, lifecycle, real FinderSync, signing, minimum OS, footprint and cleanup gates are explicit.
- [ ] Proposed defaults and unapproved lifecycle decisions are clearly distinguished.
- [ ] No production source, entitlement, service registration or installed app changed.
- [ ] Index marks the design stage only; authenticated IPC is not described as implemented.
- [ ] `git diff --check` exits 0.
- [ ] `git diff --name-only` and `git status --short` contain only scoped changes.
- [ ] The index records verification results and outstanding manual gates.

## STOP conditions

- Unexplained drift, conflicting user edits, or need to change an out-of-scope file.
- A verification gate fails twice after a reasonable repair attempt.
- A step would register a service, change entitlements, use signing credentials or
  install a FinderSync extension; those belong to a separately authorized experiment.
- Existing ADR conclusions have changed or the prototype commit is unavailable;
  record the evidence gap rather than inventing reproduction results.
- An insecure fallback is proposed to make connectivity pass.

## Maintenance notes

Completing this plan produces an experiment specification, not proof of authenticated
production transport. Later execution needs concrete isolated environment and signing
inputs. Keep old production behavior docs accurate until a separately reviewed migration
actually removes both unauthenticated execute and snapshot consumers.
