# Troubleshooting

## Right-click menu missing

1. Confirm Host is running (menu bar icon).  
2. System Settings → enable the FinderActions Finder extension.  
3. `pluginkit -m -i com.finderactions.host.FinderSync` — is it listed?  
4. Re-register:

```bash
APP="/Applications/FinderActions.app"
pluginkit -a "$APP/Contents/PlugIns/FAFinderSync.appex"
pluginkit -e use -i com.finderactions.host.FinderSync
killall Finder
```

5. Rebuild so the appex is embedded: `./Scripts/build.sh`

## Host not running item only

Launch FinderActions. On action click the extension also tries to launch Host once and retry.

## Action does nothing

- Check **Logs** in Host settings.  
- For shell actions, ensure the script exists under `~/Library/Application Support/FinderActions/Actions/` and is executable.  
- Paths with spaces must use `"$@"` in your script (the Host already passes them as separate argv entries).

## Terminal / app permissions

First automation of Terminal or iTerm may show a macOS Automation prompt — accept once. Host is not sandboxed, so you should not see sandbox “open file” storms on every click.

## Permission prompt storm

If an old sandboxed build was used, remove it. This project’s Host has `ENABLE_APP_SANDBOX: NO` / sandbox entitlement false.

## Reset config

```bash
rm -rf "$HOME/Library/Application Support/FinderActions"
# Relaunch Host to re-seed defaults
```

## Extension process crash

Host remains usable; menu bar still runs actions if you add a future “run for Finder selection” entry. Restart Finder to reload the appex: `killall Finder`.
