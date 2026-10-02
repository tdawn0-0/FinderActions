import AppKit
import Foundation
import FinderActionsCore

/// Mutable state required by the always-resident process. This type intentionally
/// has no Observation or SwiftUI dependency.
@MainActor
final class HostRuntimeState {
    private(set) var manifest = ActionManifest()
    private(set) var openWithSettings: OpenWithSettings = .defaults
    private(set) var notificationsEnabled = true
    private(set) var lastSnapshot: MenuSnapshot?

    let store: ManifestStore
    let logStore: ExecLogStore
    let executor: ActionExecutor

    var effectiveManifest: ActionManifest {
        OpenWithActions.compose(baseManifest: manifest, settings: openWithSettings)
    }

    var needsOnboarding: Bool {
        !AppPreferences.bool(forKey: "didCompleteOnboarding")
    }

    init(store: ManifestStore = .makeDefault(), logStore: ExecLogStore? = nil) {
        self.store = store
        let logsDirectory = store.fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("logs", isDirectory: true)
        self.logStore = logStore ?? ExecLogStore(directory: logsDirectory)
        self.executor = ActionExecutor(store: store)
    }

    func bootstrap() {
        (manifest, openWithSettings) = SharedConfiguration.bootstrap(store: store)
        loadPreferences()
    }

    /// Reload only externally editable configuration. Execution objects and IPC
    /// remain alive so a Settings save does not churn the resident process.
    func reloadConfiguration() {
        manifest = OpenWithActions.baseManifest(from: store.loadOrEmpty())
        openWithSettings = SharedConfiguration.loadOpenWithSettings()
        loadPreferences()
    }

    func recordLog(_ entry: ExecLogEntry) {
        logStore.append(entry)
    }

    func openActionsDirectory() {
        NSWorkspace.shared.open(store.actionsDirectoryURL)
    }

    func restartFinder() {
        Task {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            process.arguments = ["Finder"]
            try? process.run()
        }
    }

    func setLastSnapshot(_ snapshot: MenuSnapshot) {
        lastSnapshot = snapshot
    }

    private func loadPreferences() {
        notificationsEnabled = AppPreferences.object(forKey: "notificationsEnabled") as? Bool ?? true
    }

}
