# Authenticated IPC — production-shaped integration experiment

Status: experiment specification complete; integration NOT_RUN, adoption not ready.
Baseline 9898180, 2026-11-06. This artifact does not approve ADR 0001's architecture
or change the production distributed-notification transport.

## Existing evidence

ADR 0001 records a Foundation launchd XPC listener and ad-hoc CDHash clients on
macOS 27. Matching peers replied, wrong peers failed controlled checks, and a
sandbox app needed an exact Mach lookup exception. The wrong-server client sent
its outgoing ping before failing reply verification. Genuine FinderSync, Developer
ID/App Group requirements, SMAppService lifecycle, macOS 15, typed snapshots and
aggregate product footprint were not tested. Prototype 083ccef exists on
spike/006-xpc-ipc; its evidence cannot be promoted to production results.

## Architecture candidates

A: SMAppService LaunchAgent hosts the actual AppKit Host and advertises a Mach
service; avoids another resident process but changes launch/quit/login semantics.
B: a separate tiny broker/agent retains app launch semantics, at the cost of another
process and mutually authenticated broker↔Host hop. C: anonymous endpoints still
need authenticated bootstrap; unauthenticated discovery is insufficient.

## Proposed default

Investigate A first and compare against B only if actual status-menu/application
lifecycle cannot satisfy requirements. This is a recommendation awaiting maintainer
acceptance. Keep Host nonsandboxed/AppKit-only, Settings ephemeral/SwiftUI, and
FinderSync sandboxed/menu-only. Execution and Full Disk Access remain Host-owned.
Do not move execution into a helper to avoid lifecycle work.

## Trust protocol

Use a Foundation-only typed schema with version negotiation, hello, snapshot pull/
subscription, execute request/reply and configuration reload. Before resume set
exact reciprocal Developer ID Application signing requirements: Apple-issued anchor,
actual supplied Team ID and exact allowed bundle identifiers. Placeholders
`<SUPPLIED_TEAM_ID>` and `<SUPPLIED_SIGNING_IDENTITY>` are inputs, not defaults.
Do not ship ad-hoc, unconditional or identifier-only Debug rules in Release.
Client and server exchange a nonsensitive hello and verify its reply BEFORE any
paths, action selections or snapshots cross the connection. Reject wrong-server
connections without disclosing path-bearing requests. Assign role allowlists:
FinderSync may read snapshots/execute; Settings may reload but cannot execute via
that role; unrelated same-team apps are denied. App Group namespace grants sandbox
reachability, not authorization. Prefer a supplied Team-ID group service namespace;
experimental temporary Mach lookup exception is a comparison, not distribution policy.

Capture validated request context off-main; retain all path/filter checks and request-ID
deduplication. An unknown/lost execution reply is not failure proof: do not auto-replay
outside the dedupe contract. Define explicit queued/running/completed/unknown responses
and a bounded result history before extending retries. Reconnect requires new trust/
hello negotiation. Finder builds menus synchronously from last-authenticated cache;
refresh asynchronously, never block Finder menu construction on RPC. Use monotonic
snapshot revisions and session IDs to discard stale callbacks. Migration must remove
BOTH legacy execute and snapshot consumers/publishers. Forged old notifications must
have no effect, and no unauthenticated compatibility fallback is permitted.

## Lifecycle decisions

Proposed choices awaiting acceptance: login activation is an explicit user setting;
Quit stops Host execution and prevents demand revival until explicit Open; Open re-arms
service availability. Test whether SMAppService supports these semantics reliably;
if not, report a failed A gate rather than quietly changing Quit behavior. One Host
instance owns the status item, even when manual and demand launch race. Denied agent
approval shows recovery guidance and leaves execution unavailable. Crashes reconnect
with hello and do not replay uncertain requests. Define clean upgrade/uninstall behavior
and readiness ordering before exposing the listener. Do not equate running process
presence with service readiness.

## Isolated packaging

Use a dedicated disposable macOS account or VM with no production FinderActions
registration. Prepare two environments: macOS 15 and the current supported macOS,
recording full actual OS/Xcode/architecture versions at run time. Use unique supplied
experimental IDs under `com.finderactions.experiment020.<run-id>` and matching
`<SUPPLIED_TEAM_ID>.finderactions.experiment020.<run-id>` service/group namespace.
Generate a run manifest with exact identifiers, paths and registration ownership.
Use synthetic /tmp selections and experiment-owned Application Support/cache/log
locations. No production preferences, app replacement or production extension
registration. Real FinderSync must be embedded in the experimental signed app and
connect from Finder's genuine sandbox. Signing/private keys remain in Keychain;
record requirement metadata, never private credentials. No execution occurs in this
document stage. Future commands are planned harness contracts, not existing scripts:
`experiment020 prepare`, `experiment020 run --platform <recorded-os>`,
`experiment020 collect`, `experiment020 cleanup --manifest <run-manifest>`.

## Matrix

020-ipc-integration-matrix.json has cases for each required environment. All begin
NOT_RUN. A PASS needs artifact paths containing positive/negative control outcomes,
peer requirements, OS versions and cleanup evidence. A generic XPC error code alone
does not prove peer rejection. Snapshot and execute authentication are separate tests.
Timeout tests must distinguish nonexecution from lost reply after execution.

## Measurements

Measure aggregate physical footprint of actual Host, Settings while open/closed,
FinderSync and any broker, plus idle CPU and peak during script/snapshot refresh.
Compare before/after in identical signed builds, report sample duration, counts,
method and variance. A single artificial server RSS sample is insufficient. Record
pre-agreed acceptable footprint/launch latency thresholds as experiment inputs;
absence of thresholds blocks adoption instead of inventing a passing budget.

## Cleanup

Run cleanup in finally and on interrupted-run recovery using the run manifest.
Unregister only the exact experimental SMAppService and FinderSync IDs, stop only
owned processes, remove experiment-owned files, and verify no experimental job or
extension registration remains. Capture before/after inventory in artifacts.
Never kill or re-register the user's production Finder extension. If ownership cannot
be established, stop cleanup and report rather than issuing broad kill/delete commands.
Disposable VM teardown is the final recovery option, after evidence is exported.

## Adoption gates

Both OS environments must PASS every matrix case, clean up successfully, and satisfy
accepted lifecycle/trust/footprint requirements. Maintainer must accept A versus B,
Quit/login semantics and distribution entitlements. No NOT_RUN/BLOCKED/FAIL counts
as success. `python3 plans/check-020-design.py` checks document quality only;
`--require-adoption-ready` intentionally fails until complete evidence is recorded.
Any production migration is a separately reviewed change to IPC, packaging, signing,
protocol documentation and tests; preserve off-main validation and bounded snapshots
or replace them with equivalent guarantees. The current release remains notifications.

## Open decisions

Inputs needed for the later experiment: accepted architecture/lifecycle defaults;
dedicated account/VMs for both OS versions; supplied exact experimental identifiers,
Team/group/signing identity; entitlement provisioning; footprint/latency thresholds;
permission to register only those experimental bundles/services and collect artifacts.
Recommendation: accept the isolated A experiment contract first. Do not publish or
register anything from this document, and do not interpret permission to release the
existing product as permission to migrate authenticated IPC without these gates.
