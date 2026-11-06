# Plan 017: Bound UTF-8 snapshot chunks and incomplete assemblies

> **Executor instructions:** Read the entire plan, follow its steps and verification
> gates, and stop instead of expanding scope when a STOP condition applies. Update
> this plan's row in `plans/README.md` unless the dispatching reviewer owns the index.
>
> **Drift check first:** `git diff --stat 9898180..HEAD -- Packages/FinderActionsCore/Sources/IPC/SnapshotTransport.swift Apps/Host/Sources/IPC/IPCServer.swift Extensions/FinderSync/IPCClient.swift Tests/FinderActionsCoreTests/SnapshotTransportTests.swift docs/ipc.md`.
> Inspect `git status --short` too. Compare excerpts to live sources. Unexplained
> drift is a STOP condition; re-read and document adaptations from named prerequisites.

## Status

- **Priority:** P2
- **Effort:** M
- **Risk:** MED
- **Category:** bug + perf
- **Depends on:** 016 first when both selected (shared IPCServer edits)
- **Planned at:** commit `9898180`, 2026-11-06
- **Status:** DONE (reviewed in isolated integration branch; see index verification)

## Why this matters

The publisher decides when to chunk using UTF-8 bytes, then splits by Swift
Character count. Non-ASCII titles exceed the intended 40,000-byte part size.
Incomplete batches remain in the extension forever. Correct encoding units and
place deterministic memory/time limits around assembly while keeping the old wire shape.

## Current state and conventions

SnapshotPublisher at IPCServer.swift:140 uses `let maxChunk = 40_000` and
`json.utf8.count <= maxChunk`, while chunk() uses
`s.index(start, offsetBy: size, limitedBy: s.endIndex)` (Characters).
IPCClient.swift:25 owns `[String: (total: Int, parts: [Int: String])]`;
at lines 123-129 it stores parts and removes a batch only on exact completion.
The wire keys are batchId/index/total; single-part messages omit those keys.
`docs/ipc.md` specifies v1 notifications and an extension-local cached snapshot.
Match Core's Foundation-only pure helpers and Swift Testing; do not add AppKit to Core.

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
- `Packages/FinderActionsCore/Sources/IPC/SnapshotTransport.swift`
- `Apps/Host/Sources/IPC/IPCServer.swift`
- `Extensions/FinderSync/IPCClient.swift`
- `Tests/FinderActionsCoreTests/SnapshotTransportTests.swift`
- `docs/ipc.md`

Also update this plan's row/evidence in `plans/README.md`. All other production
files, installed apps, user preferences/configuration, signing credentials and live
deployments are out of scope. Do not regenerate a tracked Xcode project unless it
is listed; if listed, retain only membership changes required by this plan.

## Git workflow

Use isolated branch `codex/017-bound-snapshot-transport` for execution. Match conventional commits
(e.g. `fix(host): validate execute requests against action filters`). Do not merge,
push, publish, or commit to the user's branch without separate instructions.

## Steps

### Step 1: Extract byte-aware chunking and bounded assembly into Core

Create SnapshotTransport.swift containing a pure UTF-8 splitter and stateful
assembler with injected monotonic time. Split at Unicode-scalar boundaries, not
Character boundaries, so even one long combining-character cluster can be divided;
all parts remain valid UTF-8 and concatenation reconstructs the exact original.
Use the existing 40,000-byte body budget. Proposed explicit defensive limits: at
most 128 parts per batch, 5,120,000 bytes per assembled message, 4 active batches,
8 MiB total buffered bytes and 30-second idle expiry. Use overflow-safe checks and
an injected clock; reject oversized messages visibly through local diagnostics,
never truncate JSON. Document limits as application policy, not OS payload limits.
Validate index range, stable total, body size and duplicate index contents. Identical
duplicates are idempotent; conflicting duplicates/total discard the batch.
Evict oldest incomplete batches under pressure. Expiry must actually run even if
no more packets arrive (one cancellable client cleanup schedule, not permanent polling).

**Verify:** `swift test --scratch-path build/SwiftPM --filter SnapshotTransportTests`
(new suite) → round-trip, Unicode and bounded-buffer cases pass.

### Step 2: Integrate publisher and client

Replace private Character chunking with the Core helper. Reject publish above the
explicit supported aggregate size with a local diagnostic; no partial publication.
Adapt IPCClient under its existing lock, preserving single-part compatibility and
wire field names. Apply only fully reconstructed decodable MenuSnapshots. Retain
last-good cached/menu state on malformed input. Schedule/cancel expiration while
batches exist; deinit cleans it up. A valid complete snapshot may clear obsolete
incomplete buffers, but do not claim cross-batch version ordering: the protocol has
no monotonic revision. Do not alter cache location, authentication or menu callbacks.

**Verify:** `./Scripts/test.sh` and `./Scripts/dev.sh` → exit 0.

### Step 3: Document limits and failure behavior

Update docs/ipc.md with UTF-8 byte budget, aggregate limits, expiry and last-good
fallback. Explicitly state that 40KB is the existing body budget, not a measured
macOS notification ceiling. Tests should reconstruct representative multilingual
MenuSnapshot JSON through splitter and assembler and decode the result.

**Verify:** `swift test --scratch-path build/SwiftPM --filter SnapshotTransportTests`
→ complete snapshot decode succeeds; malformed/expired/oversize input never replaces last-good state.

## Test plan

Cover ASCII boundary lengths 39,999/40,000/40,001; CJK and emoji; a combining
cluster longer than the part budget; exact byte round-trip; out-of-order delivery;
missing piece expiry with injected time; negative/out-of-range index; inconsistent
total; identical/conflicting duplicates; too many batches; per-batch/global limits;
single-part compatibility. Assert retained byte/batch counters after every mutation.
For expiry wiring, use a bounded integration/manual observation without sending to
the user's installed extension. No unsafe giant allocation fuzzing.

## Done criteria

- [ ] SnapshotTransportTests, full Swift tests and Debug build exit 0.
- [ ] Every emitted body is valid UTF-8 and at most 40,000 bytes.
- [ ] Tests prove memory bounds and eventual cleanup after abandoned input.
- [ ] Complete reassembly is byte-identical; invalid input leaves the prior menu intact.
- [ ] No protocol field names or authentication behavior changed.
- [ ] `git diff --check` exits 0.
- [ ] `git diff --name-only` and `git status --short` contain only scoped changes.
- [ ] The index records verification results and outstanding manual gates.

## STOP conditions

- Unexplained drift, conflicting user edits, or need to change an out-of-scope file.
- A verification gate fails twice after a reasonable repair attempt.
- A real supported configuration exceeds the proposed cap; report its measured size
  and revise the policy with the maintainer rather than silently dropping actions.
- Correctness requires a protocol revision or broad IPC rewrite.
- Actual notification transport limits differ from assumptions; record evidence and revise budgets.

## Maintenance notes

Keep limits shared between sender and receiver. Unicode scalar boundaries preserve
UTF-8 without requiring whole grapheme clusters. Bounded assembly is defense in depth,
not peer authentication. Protocol ordering remains a separate future design concern.
