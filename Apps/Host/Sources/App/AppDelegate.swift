import AppKit
import FinderActionsCore

/// Process lifecycle: bootstrap, status menu, lazy windows, IPC, and headless CLI dump.
@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    private var ipcServer: IPCServer?
    private var statusMenuController: StatusMenuController?
    private var windowController: AppWindowController?

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

        let windowController = AppWindowController(appState: appState)
        self.windowController = windowController
        statusMenuController = StatusMenuController(
            appState: appState,
            openSettings: { [weak windowController] in
                windowController?.showSettings()
            }
        )

        startIPC()
        publishSnapshot()

        DistributedNotificationCenter.default().post(
            name: Notification.Name(IPCConstants.hostReadyNotification),
            object: nil
        )

        if appState.showOnboarding {
            windowController.showOnboarding()
        }
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        windowController?.showSettings()
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
        server.start()
        ipcServer = server
        appState.onManifestChanged = { [weak self] in
            self?.publishSnapshot()
        }
    }

    private func publishSnapshot() {
        let snapshot = SnapshotBuilder.build(
            from: appState.effectiveManifest,
            hostRunning: true
        )
        SnapshotPublisher.publish(snapshot)
        appState.lastSnapshot = snapshot
    }
}
