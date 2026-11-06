# IPC

Local-only communication between Host and FinderSync.

## Notifications

| Name | Direction | Payload |
|------|-----------|---------|
| `com.finderactions.host.snapshot` | Host → Ext | JSON `MenuSnapshot` as notification `object` (chunked if large) |
| `com.finderactions.extension.snapshot-request` | Ext → Host | empty (ask Host to republish) |
| `com.finderactions.extension.execute` | Ext → Host | JSON `ExecuteRequest` as notification `object` |
| `com.finderactions.host.ready` | Host → Ext | empty (Host finished launch) |

## MenuSnapshot (v1)

```json
{
  "v": 1,
  "generatedAt": "2026-08-06T12:00:00Z",
  "hostRunning": true,
  "items": [
    {
      "actionId": "open-terminal",
      "title": "Open in Terminal",
      "subtitle": "cd to selection",
      "sfSymbol": "terminal",
      "group": "Develop",
      "showWhen": "always",
      "enabled": true,
      "isSeparator": false,
      "extRules": { "pathExtensions": [], "foldersOnly": false, "filesOnly": false }
    }
  ]
}
```

## ExecuteRequest (v1)

```json
{
  "v": 1,
  "requestId": "uuid",
  "actionId": "open-terminal",
  "paths": ["/Users/me/proj/a b.swift"],
  "containerPath": "/Users/me/proj",
  "menuKind": "contextualMenuForItems"
}
```

## Offline Host

Menu degradation uses **live** Host process presence (`isHostRunning()`), not the cached snapshot’s `hostRunning` flag (which stays true after Host quits).

When Host is down the menu shows “Host not running” + “Open FinderActions”.

On action click (`ExecuteDelivery.plan`):

| Host process | Posts |
|--------------|-------|
| Running | **Once** (no delayed re-post) |
| Not running | Post once → launch Host → **one** retry after ~1.5s |

Host ignores duplicate `requestId`s within a short window (`RequestIdDedupe`) so a retry cannot double-run the same click.

Execution is fire-and-forget; results surface as Host notifications + log.

## Request validation

Distributed notifications do not identify the sender, so the Host re-checks every
`ExecuteRequest` before running it (`ExecuteRequestValidator`): version 1, at most
10,000 paths, every selection path and each non-empty `containerPath` absolute and
existing, the action enabled, and its `showWhen` / `extRules` accepting the selection.
Rejected requests are logged, not executed, and produce no notification.

## Cold-start cache

The extension caches the last live snapshot in its own sandbox container and, on start, posts `com.finderactions.extension.snapshot-request` so a running Host republishes. There is no shared file between Host and extension.

## Snapshot transport budgets

Snapshot bodies are split at Unicode-scalar boundaries into valid UTF-8 strings
of at most 40,000 bytes. This is an application body budget, not a measured macOS
notification ceiling. A message supports at most 128 parts and 5,120,000 bytes;
unsupported snapshots are rejected before any partial publication.

The extension validates indices, totals, duplicate contents and body size. It
retains at most four incomplete batches and 8 MiB of body data; older incomplete
batches are evicted under pressure. Batch identifiers are limited to 128 UTF-8
bytes. A scheduled cleanup expires batches after 30 seconds without a new part,
even when no further messages arrive. Identical duplicate parts are idempotent;
conflicting duplicates discard their batch. Invalid/incomplete JSON never replaces
the last valid menu/cache. Single-part v1 messages remain compatible. These bounds
do not authenticate peers or introduce ordering between complete snapshots.
