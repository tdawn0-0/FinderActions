# Plan 012: Publish a manifest example the real decoder accepts

> **Executor instructions:** Read the entire plan; implement only its scope. Run
> each step's verification and compare the stated result. Stop on the conditions
> below rather than silently expanding the task. Update this plan's status row in
> `plans/README.md` when verified, unless your reviewer owns that index.
>
> **Drift check first:** `git diff --stat 9898180..HEAD -- web/src/i18n.ts web/src/examples/compress-action.json Tests/FinderActionsCoreTests/PublishedManifestTests.swift Package.swift`.
> Also inspect `git status --short` and existing uncommitted changes. Compare live
> code with the excerpts below. Unexplained differences require stopping; changes
> from listed prerequisites require re-reading and documenting the adapted baseline.

## Status

- **Priority:** P1
- **Effort:** S
- **Risk:** LOW
- **Category:** docs + tests
- **Depends on:** none
- **Planned at:** commit `9898180`, 2026-11-06
- **Status:** DONE (reviewed in isolated integration branch; see index verification)

## Why this matters

The website's copyable action example uses an unsupported object for showWhen.
Users following the documented workflow create an undecodable manifest. Make the
published example one shared fixture and test it through the production Swift decoder.

## Current state and conventions

`web/src/i18n.ts:448-465` embeds this action fragment:

```json
"showWhen": {
  "target": "filesAndFolders",
  "minSelection": 1
}
```

`Action.swift:20-25` instead declares `public enum ShowWhen: String, Codable` with
always/filesOnly/foldersOnly/single/multiple. `ActionDefinition.showWhen` is required.
`ScriptShowcase.tsx:19-20` renders `codeSnippets.manifest` and its copy handler copies
that same string. Preserve that API. `README.md:139` uses `"showWhen": "always"`.
Tests follow ManifestTests: `let decoded = try JSONCoding.decode(...); #expect(...)`.

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
- `web/src/i18n.ts`
- `web/src/examples/compress-action.json`
- `Tests/FinderActionsCoreTests/PublishedManifestTests.swift`
- `Package.swift`

Also update only this plan's status/evidence in `plans/README.md`.
All other files, the installed app, user configuration, user scripts, signing
credentials, and live deployment are out of scope. A generated
`FinderActions.xcodeproj/project.pbxproj` change is allowed only where explicitly
listed and must contain only the source membership changes required by this plan.

## Git workflow

Use an isolated branch `codex/012-validate-published-manifest` when dispatched to implement.
Match conventional commit style (e.g. `fix(host): validate execute requests against action filters`).
Do not merge, push, publish, or commit to the user's branch without separate instructions.

## Steps

### Step 1: Share a valid fixture with the website

Create web/src/examples/compress-action.json using the existing action id, name,
shell interpreter and scriptFile, changing showWhen to `"always"` (the README's
supported behavior; do not invent a minSelection schema). Import it in i18n.ts as
raw text using Vite's `?raw` import and assign codeSnippets.manifest to that value.
Keep it an action entry, not a full manifest, and keep the script example untouched.

**Verify:** `npm --prefix web run lint` and `npm --prefix web run build` → exit 0.

### Step 2: Decode the exact published fixture in Core tests

Create PublishedManifestTests.swift. Locate the repository via #filePath's test-file
parent traversal; load web/src/examples/compress-action.json directly, so tests do
not validate an independent copy. Decode ActionDefinition, assert id/type/showWhen
and scriptFile, wrap in ActionManifest, round-trip it and build a snapshot.
A missing fixture must fail clearly. Package.swift change is allowed only if needed
for test resource plumbing; prefer no manifest change when direct repository-relative
loading works. Do not execute the sample compression script.

**Verify:** `swift test --scratch-path build/SwiftPM --filter PublishedManifestTests`
→ published action decodes and round-trips. `./Scripts/test.sh` → all pass.

## Test plan

At least one real fixture decode test and one round-trip/snapshot test. The source
of truth must be the file imported by the site, not a hardcoded Swift string.
Retain a negative decoder assertion that object-valued showWhen is rejected, to
explain the boundary. No UI snapshot or screenshot test is necessary.

## Done criteria

- [ ] `./Scripts/test.sh`, web lint and web build exit 0.
- [ ] PublishedManifestTests reads the exact website fixture and passes.
- [ ] `rg -n 'filesAndFolders|minSelection' web/src/i18n.ts web/src/examples` finds no obsolete example keys.
- [ ] `git diff --check` exits 0.
- [ ] `git diff --name-only` and `git status --short` contain only in-scope changes.
- [ ] The index row records results and any explicitly unverified manual gates.

## STOP conditions

- Unexplained drift from the excerpts or conflicting user changes.
- A verification gate fails twice after a reasonable repair attempt.
- Completion requires an out-of-scope file or a live user-data mutation.
- The live decoder now supports a different schema; revise the example contract first.
- Vite raw imports require changes outside the permitted scope.
- A packaging setup cannot access repository fixtures; report rather than duplicate data.

## Maintenance notes

Keep example schema and semantics tested when changing ActionDefinition. This
fix is independent of configuration recovery; do not delay it until plan 011 lands.

