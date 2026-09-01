import SwiftUI
import AppKit
import FinderActionsCore

@main
struct FinderActionsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Modern menu bar UI (no NSStatusItem / NSPopover)
        MenuBarExtra("FinderActions", systemImage: "hammer.fill") {
            MenuBarPopoverView()
                .environment(appDelegate.appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsRootView()
                .environment(appDelegate.appState)
        }
    }
}

/// Process lifecycle only: bootstrap, IPC, headless dump. UI is pure SwiftUI.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private var ipcServer: IPCServer?
    private var onboardingWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if CommandLine.arguments.contains("--dump-actions") {
            dumpActionsAndExit()
            return
        }

        appState.bootstrap()
        startIPC()
        publishSnapshot()
        presentOnboardingIfNeeded()
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

    private func presentOnboardingIfNeeded() {
        guard appState.showOnboarding, onboardingWindowController == nil else { return }

        let rootView = OnboardingView { [weak self] in
            self?.onboardingWindowController?.close()
            self?.onboardingWindowController = nil
        }
        .environment(appState)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Set Up FinderActions"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()

        let controller = NSWindowController(window: window)
        onboardingWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
