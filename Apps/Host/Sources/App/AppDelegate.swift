import AppKit
import FinderActionsCore

/// Always-resident process lifecycle: native status menu, IPC, execution, and CLI dump.
@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = HostRuntimeState()

    private var ipcServer: IPCServer?
    private var statusMenuController: StatusMenuController?
    private var settingsLauncher: SettingsHelperLauncher?

    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if CommandLine.arguments.contains("--dump-actions") {
            dumpActionsAndExit()
            return
        }

        appState.bootstrap()

        let settingsLauncher = SettingsHelperLauncher()
        self.settingsLauncher = settingsLauncher
        statusMenuController = StatusMenuController(
            appState: appState,
            openSettings: { [weak settingsLauncher] in
                settingsLauncher?.open(.settings)
            }
        )

        startIPC()
        publishSnapshot()

        DistributedNotificationCenter.default().post(
            name: Notification.Name(IPCConstants.hostReadyNotification),
            object: nil
        )

        if appState.needsOnboarding {
            settingsLauncher.open(.onboarding)
        }
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        settingsLauncher?.open(.settings)
        return true
    }

    private func dumpActionsAndExit() {
        appState.bootstrap()
        let manifest = appState.effectiveManifest
        let ids = manifest.actions.map(\.id)
        let enabled = manifest.actions.filter(\.enabled).map(\.id)
        print("LOADED_ACTIONS=\(ids.joined(separator: ","))")
        print("ENABLED_ACTIONS=\(enabled.joined(separator: ","))")
        print("MANIFEST_PATH=\(appState.store.fileURL.path)")
        print("ACTION_COUNT=\(ids.count)")
        fflush(stdout)
        exit(0)
    }

    private func startIPC() {
        let server = IPCServer(appState: appState)
        server.onSnapshotNeeded = { [weak self] in
            self?.publishSnapshot()
        }
        server.onConfigurationChanged = { [weak self] in
            self?.appState.reloadConfiguration()
            self?.publishSnapshot()
        }
        server.start()
        ipcServer = server
    }

    private func publishSnapshot() {
        let snapshot = SnapshotBuilder.build(
            from: appState.effectiveManifest,
            hostRunning: true
        )
        SnapshotPublisher.publish(snapshot)
        appState.setLastSnapshot(snapshot)
    }
}
