import AppKit

@MainActor
final class SettingsHelperLauncher {
    enum Mode {
        case settings
        case onboarding

        var arguments: [String] {
            self == .onboarding ? ["--onboarding"] : []
        }
    }

    private var helperURL: URL {
        Bundle.main.bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Helpers", isDirectory: true)
            .appendingPathComponent("FinderActionsSettings.app", isDirectory: true)
    }

    func open(_ mode: Mode) {
        guard FileManager.default.fileExists(atPath: helperURL.path) else {
            presentLaunchError("The embedded Settings app is missing. Reinstall FinderActions.")
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.arguments = mode.arguments
        NSWorkspace.shared.openApplication(
            at: helperURL,
            configuration: configuration
        ) { [weak self] _, error in
            guard let error else { return }
            Task { @MainActor in
                self?.presentLaunchError(error.localizedDescription)
            }
        }
    }

    private func presentLaunchError(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Unable to Open FinderActions Settings"
        alert.informativeText = message
        alert.runModal()
    }
}
