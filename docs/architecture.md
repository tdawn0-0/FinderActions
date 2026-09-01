# Architecture

## Platform

- **macOS 15+** only (no legacy fallbacks)
- **Swift 6**, AppKit (`NSStatusItem`, `NSMenu`) for the always-resident Host
  and SwiftUI (`@Observable`, `NavigationSplitView`) only in an on-demand
  Settings helper
- **Swift Testing** for Core unit tests

## Runtime processes

There are two resident roles and one ephemeral UI role:

1. **Host** (`com.finderactions.host`) — not sandboxed

   Owns configuration reload, script files, execution (application / shell / terminal / AppleScript), menu-snapshot publishing, logs, IPC, and a lightweight AppKit status menu. It neither imports nor links SwiftUI.

2. **Settings** (`com.finderactions.host.Settings`) — not sandboxed, on demand

   Owns all SwiftUI settings and onboarding. It persists configuration, posts one configuration-change notification, and exits after its last window closes.

3. **FinderSync** (`com.finderactions.host.FinderSync`) — sandboxed

   Pure UI probe: caches the last menu snapshot, builds Finder contextual menus, on click sends `ExecuteRequest` JSON and returns. Does **not** run scripts, spawn `Process`, or hold long-term security-scoped bookmarks.

Shared pure logic lives in **FinderActionsCore** (SwiftPM): models, manifest I/O, `showWhen` matching, shell env/argv construction, snapshot build/filter.

## Why no Runner

Sandbox App Store apps needed a separate helper + bookmark relay. With a Developer ID-signed, Hardened Runtime-enabled Host that is **not** sandboxed, Host can execute directly. Fewer moving parts.

## Data flow

```
Settings save → manifest.json / shared preferences → configuration-change notification
             → Host reloads → SnapshotBuilder → DistributedNotification
                                               (+ Application Support cache)

Right-click → Extension filters snapshot by selection → user picks item
           → ExecuteRequest { actionId, paths, containerPath }
           → DistributedNotification → Host ActionExecutor → log + optional notification
```

## Storage

```
~/Library/Application Support/FinderActions/
  manifest.json
  Actions/*.zsh
  logs/exec.jsonl
  menu-snapshot.json   # cold-start fallback for extension
```

## Targets

| Target | Sandbox | Role |
|--------|---------|------|
| FinderActions (Host) | **No** | AppKit menu + IPC + executor |
| FinderActionsSettings | **No** | SwiftUI settings; exits on close |
| FinderSync | Yes | Menu only |
| FinderActionsCore | — | Shared models / matching / quoting |
