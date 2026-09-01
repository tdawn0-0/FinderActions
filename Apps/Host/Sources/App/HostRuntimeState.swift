import AppKit
import Foundation
import FinderActionsCore

/// Mutable state required by the always-resident process. This type intentionally
/// has no Observation or SwiftUI dependency.
@MainActor
final class HostRuntimeState {
    private let openWithDefaultsKey = "openWithSettings.v2"

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
        try? store.ensureDirectories()
        if FileManager.default.fileExists(atPath: store.fileURL.path) {
            let storedManifest = store.loadOrEmpty()
            manifest = OpenWithActions.baseManifest(from: storedManifest)
            if manifest != storedManifest {
                try? store.save(manifest)
            }
            openWithSettings = loadOpenWithSettings()
        } else {
            manifest = DefaultActions.manifest()
            openWithSettings = .defaults
            try? store.save(manifest)
            saveOpenWithSettings()
        }
        seedMissingScripts()
        loadPreferences()
    }

    /// Reload only externally editable configuration. Execution objects and IPC
    /// remain alive so a Settings save does not churn the resident process.
    func reloadConfiguration() {
        manifest = OpenWithActions.baseManifest(from: store.loadOrEmpty())
        openWithSettings = loadOpenWithSettings()
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

    private func loadOpenWithSettings() -> OpenWithSettings {
        guard let data = AppPreferences.data(forKey: openWithDefaultsKey),
              let settings = try? JSONDecoder().decode(OpenWithSettings.self, from: data) else {
            return .defaults
        }
        return settings
    }

    private func saveOpenWithSettings() {
        guard let data = try? JSONEncoder().encode(openWithSettings) else { return }
        AppPreferences.set(data, forKey: openWithDefaultsKey)
    }

    private func seedMissingScripts() {
        try? store.ensureDirectories()
        for (name, body) in DefaultActions.bundledScripts() {
            let destination = store.actionsDirectoryURL.appendingPathComponent(name)
            guard !FileManager.default.fileExists(atPath: destination.path) else { continue }
            try? body.write(to: destination, atomically: true, encoding: .utf8)
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destination.path)
        }

        guard let resourceURL = Bundle.main.resourceURL?.appendingPathComponent("BundledActions"),
              let files = try? FileManager.default.contentsOfDirectory(atPath: resourceURL.path) else {
            return
        }
        for file in files where file.hasSuffix(".zsh") {
            let destination = store.actionsDirectoryURL.appendingPathComponent(file)
            guard !FileManager.default.fileExists(atPath: destination.path) else { continue }
            try? FileManager.default.copyItem(at: resourceURL.appendingPathComponent(file), to: destination)
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destination.path)
        }
    }
}
