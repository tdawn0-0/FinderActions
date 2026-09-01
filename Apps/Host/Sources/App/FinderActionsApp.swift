import SwiftUI
import AppKit
import FinderActionsCore

@main
struct FinderActionsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // 1. Modern MenuBar Window Scene
        MenuBarExtra("FinderActions", systemImage: "hammer.fill") {
            MenuBarPopoverView()
                .environment(appDelegate.appState)
        }
        .menuBarExtraStyle(.window)

        // 2. Declarative Settings Window
        Window("FinderActions Settings", id: "settings") {
            SettingsRootView()
                .environment(appDelegate.appState)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 940, height: 600)
        .defaultPosition(.center)

        // 3. Declarative Onboarding Setup Window
        Window("Set Up FinderActions", id: "onboarding") {
            OnboardingView()
                .environment(appDelegate.appState)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 540, height: 500)
        .defaultPosition(.center)
    }
}

/// Process lifecycle: bootstrap, IPC server, headless CLI dump.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private var ipcServer: IPCServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if CommandLine.arguments.contains("--dump-actions") {
            dumpActionsAndExit()
            return
        }

        appState.bootstrap()
        startIPC()
        publishSnapshot()

        DistributedNotificationCenter.default().post(
            name: Notification.Name(IPCConstants.hostReadyNotification),
            object: nil
        )
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
        let snap = SnapshotBuilder.build(from: appState.effectiveManifest, hostRunning: true)
        SnapshotPublisher.publish(snap)
        appState.lastSnapshot = snap
    }
}
