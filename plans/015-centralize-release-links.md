# Plan 015: Keep website download links independent of old version strings

> **Executor instructions:** Read the entire plan; implement only its scope. Run
> each step's verification and compare the stated result. Stop on the conditions
> below rather than silently expanding the task. Update this plan's status row in
> `plans/README.md` when verified, unless your reviewer owns that index.
>
> **Drift check first:** `git diff --stat 9898180..HEAD -- web/src/release.ts web/src/components/Hero.tsx web/src/components/GettingStarted.tsx web/scripts/check-release-links.mjs web/package.json`.
> Also inspect `git status --short` and existing uncommitted changes. Compare live
> code with the excerpts below. Unexplained differences require stopping; changes
> from listed prerequisites require re-reading and documenting the adapted baseline.

## Status

- **Priority:** P2
- **Effort:** S
- **Risk:** LOW
- **Category:** docs + dx
- **Depends on:** none
- **Planned at:** commit `9898180`, 2026-11-06
- **Status:** DONE (reviewed in isolated integration branch; see index verification)

## Why this matters

Two website sections hardcode v1.0.0 while the application metadata is v1.0.2.
Point both to one maintained latest-release landing URL so future releases do not
require hand-editing duplicated asset names. Do not guess a latest DMG asset URL.

## Current state and conventions

Hero.tsx:109 and GettingStarted.tsx:56 use
`https://github.com/tdawn0-0/FinderActions/releases/download/v1.0.0/FinderActions-1.0.0.dmg`;
release-note anchors also use `/releases/tag/v1.0.0`. App Info.plist declares 1.0.2.
These are plain React anchors with translated labels; preserve target/rel safety
and the existing `lang` prop. This audit did not verify live GitHub assets.

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
- `web/src/release.ts`
- `web/src/components/Hero.tsx`
- `web/src/components/GettingStarted.tsx`
- `web/scripts/check-release-links.mjs`
- `web/package.json`

Also update only this plan's status/evidence in `plans/README.md`.
All other files, the installed app, user configuration, user scripts, signing
credentials, and live deployment are out of scope. A generated
`FinderActions.xcodeproj/project.pbxproj` change is allowed only where explicitly
listed and must contain only the source membership changes required by this plan.

## Git workflow

Use an isolated branch `codex/015-centralize-release-links` when dispatched to implement.
Match conventional commit style (e.g. `fix(host): validate execute requests against action filters`).
Do not merge, push, publish, or commit to the user's branch without separate instructions.

## Steps

### Step 1: Introduce one release destination

Create release.ts exporting `latestReleaseURL` with the existing repository's
`https://github.com/tdawn0-0/FinderActions/releases/latest` destination. Import it in
both sections for download/release-note anchors. Change DMG-filename labels to
honest bilingual labels such as Download latest release / 下载最新版本; explain via
label that the destination is a release page, not an immediate binary download.
Do not add runtime API requests, a GitHub token, or automatic version fetching.

**Verify:** `npm --prefix web run lint` and `npm --prefix web run build` → exit 0.
`rg -n 'v1\.0\.0|FinderActions-1\.0\.0' web/src/components/Hero.tsx web/src/components/GettingStarted.tsx`
→ no matches (rg exits 1 for the successful no-match check).

### Step 2: Add a focused release-link guard

Create web/scripts/check-release-links.mjs and an npm `check:release-links` command.
Check that these two download surfaces use the shared source and do not contain
version-pinned release download/tag URLs or DMG filenames. Keep this check narrow;
version strings in historical release content elsewhere are legitimate. Validate
the shared URL's host/repository/path. Verify live GitHub redirect/readiness with a
read-only request if network is available, recording failure without inventing a
published asset. No publishing is part of this plan.

**Verify:** `npm --prefix web run check:release-links` (new) → exit 0; `curl -IL --max-time 30 https://github.com/tdawn0-0/FinderActions/releases/latest`
→ expected GitHub redirect to a release and successful final response, or explicitly
record the environment/network limitation before marking external verification.

## Test plan

A narrowly scoped static guard is enough for the version regression; no browser
snapshot suite is needed. Manually inspect English/Chinese CTA labels and confirm
both sections navigate to the same release page. Do not claim a direct DMG download
when the URL opens GitHub's release landing page.

## Done criteria

- [ ] Web lint/build and `check:release-links` exit 0.
- [ ] Both sections consume one URL source and have accurate bilingual labels.
- [ ] Old pinned release/DMG strings are absent from both components.
- [ ] Live destination validation result is recorded; no asset existence guessed.
- [ ] `git diff --check` exits 0.
- [ ] `git diff --name-only` and `git status --short` contain only in-scope changes.
- [ ] The index row records results and any explicitly unverified manual gates.

## STOP conditions

- Unexplained drift from the excerpts or conflicting user changes.
- A verification gate fails twice after a reasonable repair attempt.
- Completion requires an out-of-scope file or a live user-data mutation.
- The repository has no publicly reachable releases or has moved; report the
  actual destination evidence rather than selecting a different project.
- A direct one-click asset is mandatory; it needs a separate asset-naming contract.

## Maintenance notes

Stable release landing links trade one extra click for avoiding stale filenames.
If a direct download is later required, establish a stable asset name in packaging
and test that release contract before changing these links.

