import AppKit
import Foundation
import FinderActionsCore

/// The supported interaction surface for macOS Full Disk Access.
///
/// macOS does not provide a public API for a regular app to grant or reliably
/// query this permission. Keep the UI honest: guide the user to System Settings
/// and make the exact app bundle easy to locate.
enum FullDiskAccessSettings {
    static let systemSettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles"
    )!

    static var applicationURL: URL {
        if let runningHost = NSRunningApplication
            .runningApplications(withBundleIdentifier: IPCConstants.hostBundleId)
            .first?.bundleURL {
            return runningHost.standardizedFileURL
        }

        return Bundle.main.bundleURL
            .deletingLastPathComponent() // Helpers
            .deletingLastPathComponent() // Contents
            .deletingLastPathComponent() // FinderActions.app
            .standardizedFileURL
    }

    static var isInstalledInApplications: Bool {
        let applicationPath = applicationURL.resolvingSymlinksInPath().path
        return applicationPath == "/Applications"
            || applicationPath.hasPrefix("/Applications/")
    }

    @MainActor
    static func openSystemSettings() {
        NSWorkspace.shared.open(systemSettingsURL)
    }

    @MainActor
    static func revealApplication() {
        NSWorkspace.shared.activateFileViewerSelecting([applicationURL])
    }
}
