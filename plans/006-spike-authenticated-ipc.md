# Plan 006 (spike): Decide and prototype an authenticated Extension → Host channel

> **Executor instructions**: This is a **design/spike plan**, not a build plan.
> The deliverable is a decision record plus a throwaway prototype result. Do not
> merge prototype code into `main`. If anything in "STOP conditions" occurs,
> stop and report. When done, update the status row in `plans/README.md` —
> unless a reviewer dispatched you and told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 2e59370..HEAD -- Apps/Host/Sources/IPC Extensions/FinderSync Packages/FinderActionsCore/Sources/Models/Snapshot.swift project.yml Extensions/FinderSync/FinderSync.entitlements Apps/Host/Resources/FinderActions.entitlements docs/ipc.md`
> Plan 005 is expected to have touched `IPCServer.swift` and `docs/ipc.md`. Other changes → re-read before proceeding.

## Status

- **Priority**: P2
- **Effort**: M (spike) — implementation afterwards is likely L
- **Risk**: LOW for the spike (no production change)
- **Depends on**: plans/005-validate-execute-requests.md (short-term mitigation lands first)
- **Category**: security / direction
- **Planned at**: commit `2e59370`, 2026-10-02

## Why this matters

All Host↔Extension IPC uses `DistributedNotificationCenter`, which has no sender authentication:
- **Extension → Host** `com.finderactions.extension.execute`: any same-user process can ask the Full-Disk-Access Host to run enabled actions (plan 005 narrows, but cannot close, this).
- **Host → Extension** `com.finderactions.host.snapshot`: any process can post a fake menu snapshot, e.g. a harmless title ("Copy Path") routed to a destructive user action id.
- **Settings → Host** `com.finderactions.settings.configuration-changed` and `…snapshot-request`: low impact (only trigger reloads).

The fix is a transport where the receiver can verify the peer's code signature. The project needs a written decision on which mechanism works for a **sandboxed FinderSync extension** talking to a **non-sandboxed, Developer ID, Hardened Runtime** Host app that is launched as a normal app (not a launchd agent today).

## Current state

- Targets & entitlements (`project.yml`):
  - Host `com.finderactions.host` — `ENABLE_APP_SANDBOX: NO`; entitlements: `com.apple.security.automation.apple-events` only.
  - Settings helper `com.finderactions.host.Settings` — not sandboxed, embedded at `Contents/Helpers/`.
  - Extension `com.finderactions.host.FinderSync` — `ENABLE_APP_SANDBOX: YES`; entitlements file `Extensions/FinderSync/FinderSync.entitlements` contains only `com.apple.security.app-sandbox`. **No App Group entitlement** anywhere, even though `IPCConstants.appGroupId = "group.com.finderactions.shared"` exists in code (plan 009 removes that dead code).
- IPC code: `Apps/Host/Sources/IPC/IPCServer.swift` (server + `SnapshotPublisher`), `Extensions/FinderSync/IPCClient.swift` (client, chunked snapshot reassembly, Host launch-and-retry), `Packages/FinderActionsCore/Sources/IPC/ExecuteDelivery.swift` (delivery policy), `docs/ipc.md` (protocol doc).
- Distribution: Developer ID + notarization via `Scripts/release.sh`; macOS 15+ only; Swift 6.

## Questions the spike must answer

1. Can the sandboxed extension `NSXPCConnection(machServiceName:)` to a service vended by the Host? What entitlement does it need — an App Group (on macOS, Mach service names prefixed with a team-ID-prefixed app group are reachable from the sandbox) or a `com.apple.security.temporary-exception.mach-lookup.global-name` exception (acceptable for Developer ID, not App Store)?
2. How does a normal `.app` vend a Mach service? Options: (a) register the Host as a LaunchAgent via `SMAppService.agent(plistName:)` with a `MachServices` key (changes how the Host is launched — on-demand by launchd — and interacts with "Launch at login" and the extension's launch-and-retry); (b) a separate tiny XPC helper agent; (c) `NSXPCListener.anonymous()` endpoints exchanged via some bootstrap channel (evaluate whether any bootstrap channel is itself authenticated).
3. Peer verification: `NSXPCConnection.setCodeSigningRequirement(_:)` (macOS 13+) on both sides with a requirement like `anchor apple generic and identifier "com.finderactions.host.FinderSync" and certificate leaf[subject.OU] = "<TEAMID>"` — confirm it works for ad-hoc Debug builds (likely needs a Debug-only relaxed requirement; document how).
4. Snapshot direction: can the extension pull the snapshot over the same XPC connection (request/reply) and drop the Host→Extension distributed notification entirely? What replaces "push on change" (e.g. extension re-fetches in `menu(for:)` with a short cache, or the Host pushes over a bidirectional connection)?
5. Cost to `ExecuteDelivery` launch-and-retry: with launchd on-demand launch, is retry still needed?
6. Effect on memory/footprint goals (README: Host is a "featherweight background (<10MB RAM)").

## Steps

### Step 1: Research (no code)
Read Apple docs for `NSXPCConnection`, `NSXPCListener`, `SMAppService`, `setCodeSigningRequirement`, App Sandbox Mach lookup rules, and macOS App Group identifiers (team-prefixed on macOS). Record sources (URLs) in the ADR.

### Step 2: Prototype on a throwaway branch
Branch `spike/006-xpc-ipc` (never merge). Minimal goal: the extension sends a "ping" with an `ExecuteRequest`-shaped payload over XPC; the Host replies; both sides enforce a code-signing requirement; a non-matching client (e.g. a tiny Swift script or `ShellExecHarness` variant) is refused. Use `./Scripts/dev.sh` to build, install to `/Applications`, and register the extension per README ("If the menu never appears").

**Verify**: write down, for the prototype: did the sandboxed extension connect (yes/no + entitlement used); was the unsigned client rejected (yes/no + log line); Debug ad-hoc signing story.

### Step 3: Write the decision record
Create `docs/adr/0001-authenticated-host-ipc.md` with sections: Context, Options considered (at least the three from question 2, each with pros/cons and entitlements), Decision (or "Recommendation, needs maintainer sign-off"), Consequences (launch model, Debug builds, release script/notarization changes, migration of `docs/ipc.md`), Prototype results (answers to questions 1–6), and an implementation outline broken into steps that could become plans 0xx.

**Verify**: `test -f docs/adr/0001-authenticated-host-ipc.md && grep -c "^## " docs/adr/0001-authenticated-host-ipc.md` → at least 6.

## Scope

**In scope (on `main`)**: `docs/adr/0001-authenticated-host-ipc.md` (create). **In scope (spike branch only)**: anything needed for the prototype.

**Out of scope**: merging any transport change; changing signing identities or `Scripts/release.sh`; adding real credentials anywhere.

## Done criteria

- [ ] ADR file exists on the working branch with the sections above and answers to all 6 questions
- [ ] Prototype outcome recorded (including "could not run because …" if applicable)
- [ ] `git diff --stat main -- Apps Extensions Packages project.yml` on the ADR branch → empty (no production code)
- [ ] `plans/README.md` row updated

## STOP conditions

- The prototype requires a paid-account action you cannot perform (provisioning an App Group in the developer portal, notarizing) — record what's needed in the ADR and stop there.
- Every option requires App Store–incompatible exceptions *and* the maintainer has indicated App Store distribution is a goal (check `docs/` and README; currently Developer ID only) — record and stop.

## Maintenance notes

- Until the ADR's implementation lands, plan 005's validation is the only guard; keep it.
- If the decision moves the Host under launchd, revisit onboarding text and the "Host not running" offline menu in `FinderSync.swift`.
