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

5. Rebuild so the appex is embedded: `./Scripts/dev.sh`

## Host not running item only

Launch FinderActions. On action click the extension also tries to launch Host once and retry.

## Action does nothing

- Check **Logs** in Host settings.  
- For shell actions, ensure the chosen script file exists and is readable. The selected interpreter executes it; the script itself does not need its executable bit set.  
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


## Setup and execution feedback

Registration and enablement are separate hints. A registered extension may still
need enabling in System Settings; an unknown status must be checked there. Setup
is verified only after Host records a successful Finder-origin **Copy Path**
action. A Settings test, an unrelated action, or a failed execution does not count.
**Skip for Now** leaves setup unverified. Return to the setup flow to finish it.

The menu bar displays the active Host task count. **Recent Activity** contains
running tasks and recent results. Choose a result to open its filtered Activity
Logs; **Edit Action** opens the matching action when it still exists. New log
entries retain the readable action name, path count and duration. Older log rows
remain readable even when they lack those fields. In **General → Execution
Notifications**, choose every completion, failures only, or off. Notification
clicks open the associated logs when macOS delivers them.

A long-running command may still be running when no notification appears. Check
Recent Activity before running it again. FinderActions does not promise to cancel
all descendant processes, undo file changes or automatically retry failed scripts.
Production IPC remains distributed notifications; these workflow changes do not
add authenticated transport.

## Verify the six workflows

These are executable acceptance scenarios, not a claim that GUI checks have
already been performed. Run `./Scripts/test.sh` for automated model/integration
coverage and `./Scripts/dev.sh` for a Debug app build plus the Host dependency
boundary check. Real Finder behavior needs the installed extension and a live Host.

For Settings-only UI checks, use an isolated configuration root from the repository:

```bash
./Scripts/dev.sh
FA_QA_ROOT="$(mktemp -d -t finderactions-qa)"
mkdir -p "$FA_QA_ROOT/inputs" "$FA_QA_ROOT/work"
touch "$FA_QA_ROOT/inputs/one file.png" "$FA_QA_ROOT/inputs/中文.png" "$FA_QA_ROOT/inputs/notes.txt"
./build/DerivedData/Debug/Build/Products/Debug/FinderActionsSettings.app/Contents/MacOS/FinderActionsSettings --qa-root "$FA_QA_ROOT"
```

The `--qa-root` helper uses that directory for manifests, scripts and logs, uses
in-memory preferences, and suppresses configuration notifications to the live
Host. It still executes any action explicitly tested, so use the harmless print
scripts below and disposable inputs. It cannot prove live Finder integration:
Finder uses the regular Host configuration, not this isolated root. Close the
helper before removing the QA directory. To inspect the onboarding layout in
isolation, add `--onboarding` to the helper command; it should remain unverified.

1. **Real-input Live Test:** Add a per-file template. Choose the two PNG fixtures
   above, or drag them into the drop area. Check both ordered paths in the preview,
   run, and verify stdout contains each full path including spaces/Chinese. Choose
   `work` as working directory and check the `FA_CWD` preview. Remove one input,
   clear all inputs, and verify the retained container becomes the effective
   input. Clear the container too and check Run is disabled. While a harmless
   `sleep 3; print -r -- "$@"` test runs, verify duplicate Run, changing/deleting
   that action and closing Settings are prevented; after completion inspect output.
2. **Matching:** On the same action choose Single Selection, Files Only and
   extensions `.PNG, jpg`. Enable it. A single PNG should be described as visible;
   two PNGs should be hidden by count; a PNG plus `notes.txt` should be hidden.
   Remove the count restriction and confirm two PNGs match while mixed extensions
   do not. Change to Folders Only with extensions retained and check the validation
   explanation. An action hidden by matching can still be explicitly tested.
3. **Authoring:** Create each of the four templates and check it starts disabled.
   Configure the application template with Choose Application. For a shell action,
   save `print -r -- external` in a temporary `.zsh`, choose Use External Script
   File, and check preview/run uses it. Switch back to inline and check the retained
   inline draft becomes active. An empty name, empty source or missing application
   must not become an enabled action. Cancelling a chooser should preserve valid
   existing settings.
4. **Onboarding:** In the isolated helper with `--onboarding`, inspect tool
   selection, extension hints and optional protected-folder guidance. Finish should
   remain unavailable without a confirmed Finder Copy Path execution; Skip should
   leave verification false. Separately, launch the regular installed app, enable
   its extension, right-click a disposable file in Finder and choose Copy Path.
   Return to onboarding/refresh: successful Host execution should verify setup.
   A Settings test and another action must not verify it.
5. **Feedback:** With the regular installed Host, enable a harmless long-running
   action and invoke it on disposable files. Open Recent Activity during execution
   to see name/count and the active count. Run two independent actions and verify
   the count returns to zero after both complete. Run `print -u2 -- test-error;
   exit 1` in a disposable action, then open its result → logs → Edit Action. Check
   name, paths, duration and stderr. Test notification modes all/failures/off with
   success and failure, accounting for macOS notification permission; click a
   delivered failure notification to open its logs.
6. **Sharing:** Export the file-based action with dependency notes, import it via
   the chooser and by dropping it on the import/export controls. Preview must show
   script/dependencies before confirmation. Cancel once and check no action or
   asset is installed. Confirm and check a new disabled action, fresh ID, numbered
   conflicting name and intact originals. Run the imported harmless script to
   confirm its installed asset is used. Try malformed JSON, an unsupported version,
   a missing embedded script or a script reference containing `../`; each should
   fail without changing existing configuration. Repeat with inline and AppleScript
   actions; actual AppleScript execution may require macOS permissions.

Repeat Settings checks with English and Simplified Chinese selected as the app
language; ensure labels, validation explanations and long paths remain readable.
Record actual commands, UI observations and unsupported/unrun cases in the change
review. Passing automated tests alone does not establish real Finder verification.
