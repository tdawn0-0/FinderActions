# IPC

Local-only communication between Host and FinderSync.

## Notifications

| Name | Direction | Payload |
|------|-----------|---------|
| `com.finderactions.host.snapshot` | Host → Ext | JSON `MenuSnapshot` as notification `object` (chunked if large) |
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

## Cold-start cache

Host also writes `menu-snapshot.json` under Application Support (and App Group if available). Extension reads this when no live snapshot has arrived yet.
