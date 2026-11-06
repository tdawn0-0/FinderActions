# Plan 018: Make web prerequisites and CI match the locked toolchain

> **Executor instructions:** Read the entire plan, follow its steps and verification
> gates, and stop instead of expanding scope when a STOP condition applies. Update
> this plan's row in `plans/README.md` unless the dispatching reviewer owns the index.
>
> **Drift check first:** `git diff --stat 9898180..HEAD -- web/.nvmrc web/package.json .github/workflows/ci.yml docs/releasing.md docs/releasing.zh-Hans.md web/README.md`.
> Inspect `git status --short` too. Compare excerpts to live sources. Unexplained
> drift is a STOP condition; re-read and document adaptations from named prerequisites.

## Status

- **Priority:** P2
- **Effort:** S
- **Risk:** LOW
- **Category:** dx + tests
- **Depends on:** none; integrate 012/015 checks when already present
- **Planned at:** commit `9898180`, 2026-11-06
- **Status:** DONE (reviewed in isolated integration branch; see index verification)

## Why this matters

The deployment guide permits Node 20 while the locked Wrangler requires Node 22
or newer. The existing workflow builds/tests Swift only. Pin a compatible runtime
for contributors and CI and validate the landing site without deploying it.

## Current state and conventions

docs/releasing.md:24 says `Node.js (v20+)`. Locked Vite engines are
`^20.19.0 || >=22.12.0` and Wrangler engines are `>=22.0.0`.
web/package.json defines `build: tsc -b && vite build`, `lint: oxlint`, and
`deploy: npm run build && wrangler deploy`. CI has one macos job, contents:read,
and cancel-in-progress. Preserve those permissions and the existing Swift job.
No dependency upgrade or advisory fix is justified solely by this plan.

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
- `web/.nvmrc`
- `web/package.json`
- `.github/workflows/ci.yml`
- `docs/releasing.md`
- `docs/releasing.zh-Hans.md`
- `web/README.md`

Also update this plan's row/evidence in `plans/README.md`. All other production
files, installed apps, user preferences/configuration, signing credentials and live
deployments are out of scope. Do not regenerate a tracked Xcode project unless it
is listed; if listed, retain only membership changes required by this plan.

## Git workflow

Use isolated branch `codex/018-verify-web-toolchain` for execution. Match conventional commits
(e.g. `fix(host): validate execute requests against action filters`). Do not merge,
push, publish, or commit to the user's branch without separate instructions.

## Steps

### Step 1: Align local runtime documentation

Use Node major 24 (compatible with the committed requirements) in web/.nvmrc and
an explicit engines constraint such as `>=24 <25` in web/package.json. Document
`cd web`, `nvm use`, `npm ci`, `npm run lint`, `npm run build` in web/README and both
release guides. Describe the runtime as the selected supported project baseline,
not an unverified claim about the current latest Node release. Do not regenerate
the lockfile or update package versions solely for this change.

**Verify:** `node --version` → v24.x in the selected environment;
`npm --prefix web run lint` and `npm --prefix web run build` → exit 0.

### Step 2: Add an independent web CI job

Add a web job to ci.yml with checkout, supported actions/setup-node configured from
web/.nvmrc, npm cache using web/package-lock.json, npm ci, lint and build, working
directory web. Select/verify an action version compatible with the runner using
its official repository; do not guess a tag. Keep read-only permissions; no Cloudflare
token, deploy command or production environment. Run check:release-links from 015
if that script already exists; do not make this job fail on branches where 015 is
not yet implemented. Published-manifest checks from 012 remain in the macOS Swift job.

**Verify:** `cd web && npm ci && npm run lint && npm run build` → exit 0 without
Cloudflare credentials. Inspect workflow parsing in the configured CI tooling, and
record remote CI result only if a separately authorized push/PR runs it.

## Test plan

Use the actual clean-lockfile npm install, TypeScript build and lint as checks;
no tests that merely assert the workflow's text. Verify no deployment step or token
requirement is introduced. Existing npm audit high advisories were not triaged for
reachability; this plan neither upgrades them blindly nor labels them resolved.

## Done criteria

- [ ] Node 24, npm ci, lint and build succeed in a clean environment.
- [ ] .nvmrc, package engines and all three guides agree on Node 24.
- [ ] CI defines independent Swift and web checks with contents:read.
- [ ] No deploy command, token, package-version upgrade or lockfile churn is introduced.
- [ ] Remote CI is explicitly marked run or not run.
- [ ] `git diff --check` exits 0.
- [ ] `git diff --name-only` and `git status --short` contain only scoped changes.
- [ ] The index records verification results and outstanding manual gates.

## STOP conditions

- Unexplained drift, conflicting user edits, or need to change an out-of-scope file.
- A verification gate fails twice after a reasonable repair attempt.
- npm ci reports existing manifest/lock drift; report it before changing dependency versions.
- Build requires real Cloudflare authentication or network deployment.
- The installed runtime cannot satisfy the pinned major; report setup needs rather than claiming a pass.

## Maintenance notes

Review engines when upgrading Vite/Wrangler. Keep runtime selection centralized
through .nvmrc and keep CI caching keyed by the lockfile. Adding a web build is not
an endorsement of all audit advisories; triage those separately with reachability evidence.
