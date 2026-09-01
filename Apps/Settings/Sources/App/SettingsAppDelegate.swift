import AppKit
import FinderActionsCore

/// Entry point for the on-demand UI process. Closing its final window ends the
/// process, returning all SwiftUI framework pages to the OS.
@main
@MainActor
final class SettingsAppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private var windowController: SettingsWindowController?

    static func main() {
        let application = NSApplication.shared
        let delegate = SettingsAppDelegate()
        application.delegate = delegate
        application.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState.bootstrap()
        appState.onManifestChanged = {
            DistributedNotificationCenter.default().postNotificationName(
                Notification.Name(IPCConstants.configurationChangedNotification),
                object: nil,
                deliverImmediately: true
            )
        }

        let controller = SettingsWindowController(appState: appState)
        windowController = controller
        if CommandLine.arguments.contains("--onboarding"), appState.showOnboarding {
            controller.showOnboarding()
        } else {
            controller.showSettings()
        }
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        windowController?.showSettings()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
