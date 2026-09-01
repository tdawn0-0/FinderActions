import Foundation
import AppKit
import SwiftUI
import Observation
import FinderActionsCore

@Observable
@MainActor
final class AppState {
    var manifest: ActionManifest = ActionManifest()
    var logs: [ExecLogEntry] = []
    var lastSnapshot: MenuSnapshot?
    var extensionEnabledHint: String = "Unknown"
    var showOnboarding: Bool = false

    let store: ManifestStore
    let logStore: ExecLogStore
    let executor: ActionExecutor

    var launchAtLogin: Bool = false
    var notificationsEnabled: Bool = true
    var openWithSettings: OpenWithSettings = .defaults

    var onManifestChanged: (() -> Void)?

    /// Guards one-time bootstrap / IPC start.
    private(set) var didStart = false
    private let openWithDefaultsKey = "openWithSettings.v2"

    var effectiveManifest: ActionManifest {
        OpenWithActions.compose(baseManifest: manifest, settings: openWithSettings)
    }

    init(store: ManifestStore = .makeDefault(), logStore: ExecLogStore? = nil) {
        self.store = store
        let logsDir = store.fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("logs", isDirectory: true)
        self.logStore = logStore ?? ExecLogStore(directory: logsDir)
        self.executor = ActionExecutor(store: store)
    }

    func bootstrap() {
        try? store.ensureDirectories()
        openWithSettings = loadOpenWithSettings()

        if FileManager.default.fileExists(atPath: store.fileURL.path) {
            manifest = store.loadOrEmpty()
            let base = OpenWithActions.baseManifest(from: manifest)
            if base != manifest {
                manifest = base
                try? store.save(manifest)
            }
        } else {
            seedDefaults()
        }

        seedMissingScripts()
        logs = logStore.recent(limit: 200)
        refreshExtensionStatus()

        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "didCompleteOnboarding") {
            showOnboarding = true
        }
        notificationsEnabled = defaults.object(forKey: "notificationsEnabled") as? Bool ?? true
    }

    func seedDefaults() {
        manifest = DefaultActions.manifest()
        openWithSettings = .defaults
        try? store.save(manifest)
        saveOpenWithSettings()
        seedMissingScripts()
        onManifestChanged?()
    }

    func seedMissingScripts() {
        try? store.ensureDirectories()
        for (name, body) in DefaultActions.bundledScripts() {
            let url = store.actionsDirectoryURL.appendingPathComponent(name)
            guard !FileManager.default.fileExists(atPath: url.path) else { continue }
            try? body.write(to: url, atomically: true, encoding: .utf8)
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: url.path
            )
        }
        if let resourceURL = Bundle.main.resourceURL?.appendingPathComponent("BundledActions"),
           let files = try? FileManager.default.contentsOfDirectory(atPath: resourceURL.path) {
            for file in files where file.hasSuffix(".zsh") {
                let dest = store.actionsDirectoryURL.appendingPathComponent(file)
                guard !FileManager.default.fileExists(atPath: dest.path) else { continue }
                try? FileManager.default.copyItem(
                    at: resourceURL.appendingPathComponent(file),
                    to: dest
                )
                try? FileManager.default.setAttributes(
                    [.posixPermissions: 0o755],
                    ofItemAtPath: dest.path
                )
            }
        }
    }

    func saveManifest() {
        manifest = OpenWithActions.baseManifest(from: manifest)
        try? store.save(manifest)
        onManifestChanged?()
    }

    func selectTerminal(_ application: ExternalApplication) {
        openWithSettings.terminal = canonicalApplication(application, kind: .terminal)
        saveOpenWithSettings()
    }

    func setEditor(_ application: ExternalApplication, enabled: Bool) {
        let application = canonicalApplication(application, kind: .editor)
        openWithSettings.editors.removeAll { $0.bundleId == application.bundleId }
        if enabled {
            openWithSettings.editors.append(application)
        }
        saveOpenWithSettings()
    }

    func isEditorEnabled(_ application: ExternalApplication) -> Bool {
        openWithSettings.editors.contains { $0.bundleId == application.bundleId }
    }

    func isApplicationInstalled(_ application: ExternalApplication) -> Bool {
        if NSWorkspace.shared.urlForApplication(withBundleIdentifier: application.bundleId) != nil {
            return true
        }
        guard let path = application.pathFallback else { return false }
        return FileManager.default.fileExists(atPath: path)
    }

    var customEditors: [ExternalApplication] {
        let catalogIds = Set(ExternalApplicationCatalog.editors.map(\.bundleId))
        return openWithSettings.editors.filter { !catalogIds.contains($0.bundleId) }
    }

    func setEnabled(actionId: String, enabled: Bool) {
        guard let idx = manifest.actions.firstIndex(where: { $0.id == actionId }) else { return }
        manifest.actions[idx].enabled = enabled
        saveManifest()
    }

    func moveAction(from source: IndexSet, to destination: Int) {
        var sorted = manifest.actions.sorted { $0.sortIndex < $1.sortIndex }
        sorted.move(fromOffsets: source, toOffset: destination)
        for i in sorted.indices {
            sorted[i].sortIndex = (i + 1) * 10
        }
        manifest.actions = sorted
        saveManifest()
    }

    func updateAction(_ action: ActionDefinition) {
        if let idx = manifest.actions.firstIndex(where: { $0.id == action.id }) {
            manifest.actions[idx] = action
        } else {
            manifest.actions.append(action)
        }
        saveManifest()
    }

    func addNewAction(
        name: String = "New Action",
        type: ActionType = .shell,
        symbol: String = "bolt"
    ) -> ActionDefinition {
        let maxIndex = manifest.actions.map(\.sortIndex).max() ?? 0
        let newId = "user.action.\(UUID().uuidString.prefix(8).lowercased())"
        let action = ActionDefinition(
            id: newId,
            name: name,
            type: type,
            enabled: true,
            sortIndex: maxIndex + 10,
            group: "Custom",
            icon: ActionIcon(sfSymbol: symbol),
            showWhen: .always,
            shell: type == .shell ? ShellConfig(interpreter: "/bin/zsh", scriptFile: "", scriptInline: "#!/bin/zsh\n\necho \"Executing on $@\"\n") : nil
        )
        manifest.actions.append(action)
        saveManifest()
        return action
    }

    func duplicateAction(id: String) -> ActionDefinition? {
        guard let original = manifest.actions.first(where: { $0.id == id }) else { return nil }
        var copy = original
        copy.id = "user.action.\(UUID().uuidString.prefix(8).lowercased())"
        copy.name = "\(original.name) (Copy)"
        let maxIndex = manifest.actions.map(\.sortIndex).max() ?? 0
        copy.sortIndex = maxIndex + 10
        manifest.actions.append(copy)
        saveManifest()
        return copy
    }

    func executeForTesting(action: ActionDefinition, paths: [String] = []) -> ExecResult {
        let testPaths = paths.isEmpty ? [NSHomeDirectory()] : paths
        let result = executor.execute(
            action: action,
            paths: testPaths,
            containerPath: testPaths.first
        )
        recordLog(ExecLogEntry(
            actionId: action.id,
            success: result.success,
            summary: "Test Run: \(result.summary)",
            paths: testPaths
        ))
        return result
    }

    func deleteAction(id: String) {
        manifest.actions.removeAll { $0.id == id }
        saveManifest()
    }

    func recordLog(_ entry: ExecLogEntry) {
        logStore.append(entry)
        logs = logStore.recent(limit: 200)
    }

    func clearLogs() {
        logStore.clear()
        logs = []
    }

    func openActionsDirectory() {
        NSWorkspace.shared.open(store.actionsDirectoryURL)
    }

    func refreshExtensionStatus() {
        Task {
            let out = await Self.runCapture(
                executable: "/usr/bin/pluginkit",
                arguments: ["-m", "-i", IPCConstants.extensionBundleId]
            )
            if out.contains(IPCConstants.extensionBundleId) || out.contains("FinderSync") {
                if out.contains("+") || out.lowercased().contains("enabled") {
                    extensionEnabledHint = "Registered (check System Settings if menu missing)"
                } else {
                    extensionEnabledHint = "Registered — enable in System Settings → Privacy & Security → Extensions → Added Extensions"
                }
            } else if out.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                extensionEnabledHint = "Not registered — open Host once from /Applications, then enable in System Settings"
            } else {
                extensionEnabledHint = out.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }

    func openExtensionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
            NSWorkspace.shared.open(url)
        }
    }

    func restartFinder() {
        Task {
            _ = await Self.runCapture(executable: "/usr/bin/killall", arguments: ["Finder"])
        }
    }

    // MARK: - Settings Window Management

    private var settingsWindowController: NSWindowController?

    func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if let controller = settingsWindowController, let window = controller.window {
            window.makeKeyAndOrderFront(nil)
            controller.showWindow(nil)
            return
        }
        let rootView = SettingsRootView().environment(self)
        let hosting = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hosting)
        window.title = "FinderActions Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 920, height: 600))
        window.minSize = NSSize(width: 860, height: 520)
        window.center()
        window.isReleasedWhenClosed = false
        let controller = NSWindowController(window: window)
        settingsWindowController = controller
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "didCompleteOnboarding")
        showOnboarding = false
    }

    func persistSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
    }

    private func canonicalApplication(
        _ application: ExternalApplication,
        kind: ExternalApplicationKind
    ) -> ExternalApplication {
        ExternalApplicationCatalog.knownApplication(bundleId: application.bundleId, kind: kind)
            ?? application
    }

    private func loadOpenWithSettings() -> OpenWithSettings {
        guard let data = UserDefaults.standard.data(forKey: openWithDefaultsKey),
              let settings = try? JSONDecoder().decode(OpenWithSettings.self, from: data) else {
            return .defaults
        }
        return settings
    }

    private func saveOpenWithSettings() {
        if let data = try? JSONEncoder().encode(openWithSettings) {
            UserDefaults.standard.set(data, forKey: openWithDefaultsKey)
        }
        onManifestChanged?()
    }

    // MARK: - Process helper (async)

    private static func runCapture(executable: String, arguments: [String]) async -> String {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe
                do {
                    try process.run()
                    process.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    continuation.resume(returning: String(data: data, encoding: .utf8) ?? "")
                } catch {
                    continuation.resume(returning: error.localizedDescription)
                }
            }
        }
    }
}
