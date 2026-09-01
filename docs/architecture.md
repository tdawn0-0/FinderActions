# Architecture

## Platform

- **macOS 15+** only (no legacy fallbacks)
- **Swift 6**, SwiftUI (`MenuBarExtra`, `@Observable`, `Tab`, `SettingsLink`)
- **Swift Testing** for Core unit tests

## 方案 B summary

Two processes only:

1. **Host** (`com.finderactions.host`) — not sandboxed  
   Owns configuration, script files, execution (application / shell / terminal / AppleScript), menu-snapshot publishing, logs, and SwiftUI settings / menu bar UI.

2. **FinderSync** (`com.finderactions.host.FinderSync`) — sandboxed  
   Pure UI probe: caches the last menu snapshot, builds Finder contextual menus, on click sends `ExecuteRequest` JSON and returns. Does **not** run scripts, spawn `Process`, or hold long-term security-scoped bookmarks.

Shared pure logic lives in **FinderActionsCore** (SwiftPM): models, manifest I/O, `showWhen` matching, shell env/argv construction, snapshot build/filter.

## Why no Runner

Sandbox App Store apps needed a separate helper + bookmark relay. With a Developer ID / open-source Host that is **not** sandboxed, Host can execute directly. Fewer moving parts.

## Data flow

```
Config change → Host saves manifest.json → SnapshotBuilder → DistributedNotification
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
| FinderActions (Host) | **No** | Executor + UI |
| FinderSync | Yes | Menu only |
| FinderActionsCore | — | Shared models / matching / quoting |
