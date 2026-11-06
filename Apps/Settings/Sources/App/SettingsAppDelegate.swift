import AppKit
import FinderActionsCore

/// Entry point for the on-demand UI process. Closing its final window ends the
/// process, returning all SwiftUI framework pages to the OS.
@main
@MainActor
final class SettingsAppDelegate: NSObject, NSApplicationDelegate {
    // Explicit arguments avoid a Swift 6.1 stored-property default-argument lowering crash.
    private let appState = AppState(store: .makeDefault(), logStore: nil, preferences: .live)
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

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        appState.flushPendingManifestSave()
        guard appState.isDirty else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = String(localized: "Changes could not be saved")
        alert.informativeText = appState.configurationError ?? String(localized: "Retry saving, discard changes, or cancel closing.")
        alert.addButton(withTitle: String(localized: "Retry"))
        alert.addButton(withTitle: String(localized: "Discard Changes"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        switch alert.runModal() {
        case .alertFirstButtonReturn: return appState.saveManifest() ? .terminateNow : .terminateCancel
        case .alertSecondButtonReturn: return .terminateNow
        default: return .terminateCancel
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Termination was resolved by applicationShouldTerminate.
    }
}
