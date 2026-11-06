import Foundation
import AppKit
import Observation
import SwiftUI
import FinderActionsCore

@Observable
@MainActor
final class AppState {
    var manifest: ActionManifest = ActionManifest()
    var logs: [ExecLogEntry] = []
    let liveTest = LiveTestSession()
    var selectedActionID: String?
    var navigationDestination: String?
    var extensionRegistration: ExtensionRegistration = .unknown
    var notificationMode: ExecutionNotificationMode = .all
    var extensionEnabledHint: String = "Unknown"
    var showOnboarding: Bool = false

    let preferences: PreferencesStore
    var configurationError: String?
    var isDirty = false
    var writesBlocked = false

    let store: ManifestStore
    let logStore: ExecLogStore
    let executor: ActionExecutor

    var notificationsEnabled: Bool = true
    var openWithSettings: OpenWithSettings = .defaults

    var onManifestChanged: (() -> Void)?

    /// Pending debounced save from continuous edits (typing in the inspector).
    private var pendingSave: Task<Void, Never>?

    var effectiveManifest: ActionManifest {
        OpenWithActions.compose(baseManifest: manifest, settings: openWithSettings)
    }

    init(store: ManifestStore = .makeDefault(), logStore: ExecLogStore? = nil, preferences: PreferencesStore = .live) {
        self.preferences = preferences
        self.store = store
        let logsDir = store.fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("logs", isDirectory: true)
        self.logStore = logStore ?? ExecLogStore(directory: logsDir)
        self.executor = ActionExecutor(store: store)
    }

    func bootstrap() {
        reloadManifest()
        refreshLogs()
        refreshExtensionStatus()

        if !preferences.bool(forKey: "didCompleteOnboarding") {
            showOnboarding = true
        }
        notificationsEnabled = preferences.object(forKey: "notificationsEnabled") as? Bool ?? true
        notificationMode = .load(preferences: preferences)
    }

    func reloadManifest() {
        pendingSave?.cancel()
        pendingSave = nil
        do {
            (manifest, openWithSettings) = try SharedConfiguration.bootstrap(store: store, preferences: preferences)
            configurationError = nil
            writesBlocked = false
            isDirty = false
        } catch {
            openWithSettings = SharedConfiguration.loadOpenWithSettings(preferences: preferences)
            configurationError = error.localizedDescription
            writesBlocked = true
        }
    }

    func seedDefaults() {
        pendingSave?.cancel()
        pendingSave = nil
        do {
            (manifest, openWithSettings) = try SharedConfiguration.resetToDefaults(store: store, preferences: preferences)
            SharedConfiguration.seedMissingScripts(store: store)
            configurationError = nil
            writesBlocked = false
            isDirty = false
            onManifestChanged?()
        } catch { configurationError = error.localizedDescription }
    }

    @discardableResult
    func saveManifest() -> Bool {
        pendingSave?.cancel()
        pendingSave = nil
        isDirty = true
        guard !writesBlocked else { return false }
        let base = OpenWithActions.baseManifest(from: manifest)
        do {
            try store.save(base)
            manifest = base
            isDirty = false
            configurationError = nil
            onManifestChanged?()
            return true
        } catch {
            configurationError = error.localizedDescription
            return false
        }
    }

    /// Persist after edits settle so typing does not rewrite the manifest and
    /// wake the Host on every keystroke.
    func scheduleManifestSave() {
        isDirty = true
        pendingSave?.cancel()
        pendingSave = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.saveManifest()
        }
    }

    /// Write any pending debounced edit now (e.g. before the process exits).
    func flushPendingManifestSave() {
        guard pendingSave != nil || isDirty else { return }
        saveManifest()
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
        if enabled, let error = ActionAuthoring.validationError(manifest.actions[idx]) { configurationError = String(localized: String.LocalizationValue(error)); return }
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
            enabled: false,
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

    @discardableResult
    func addAction(template: ActionTemplate) -> ActionDefinition {
        var action = template.make(id: "user.action.\(UUID().uuidString.lowercased())", sortIndex: (manifest.actions.map(\.sortIndex).max() ?? 0) + 10)
        action.name = String(localized: String.LocalizationValue(action.name))
        manifest.actions.append(action); saveManifest()
        return action
    }

    func duplicateAction(id: String) -> ActionDefinition? {
        guard let original = manifest.actions.first(where: { $0.id == id }) else { return nil }
        var copy = original
        copy.enabled = false
        copy.id = "user.action.\(UUID().uuidString.prefix(8).lowercased())"
        copy.name = "\(original.name) (Copy)"
        let maxIndex = manifest.actions.map(\.sortIndex).max() ?? 0
        copy.sortIndex = maxIndex + 10
        manifest.actions.append(copy)
        saveManifest()
        return copy
    }

    func deleteAction(id: String) {
        manifest.actions.removeAll { $0.id == id }
        saveManifest()
    }

    func recordLog(_ entry: ExecLogEntry) {
        logStore.append(entry)
        refreshLogs()
    }

    func refreshLogs() {
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
            extensionRegistration = .parse(out, bundleID: IPCConstants.extensionBundleId)
            extensionEnabledHint = extensionRegistration.message

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

    var finderSetupVerified: Bool {
        preferences.bool(forKey: "finderSetupVerified") || logs.contains {
            $0.source == .finder && $0.success && $0.actionId == "copy-path"
        }
    }

    func completeOnboarding(skipped: Bool = false) {
        guard skipped || finderSetupVerified else { return }
        preferences.set(skipped, forKey: "onboardingSkipped")
        preferences.set(true, forKey: "didCompleteOnboarding")
        showOnboarding = false
    }

    func persistSettings() {
        notificationMode.persist(preferences: preferences)
        onManifestChanged?()
    }

    func chooseApplications(kind: ExternalApplicationKind) {
        let panel = NSOpenPanel()
        panel.title = kind == .terminal ? "Choose a Terminal" : "Choose Editor Applications"
        panel.prompt = "Choose"
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = kind == .editor

        guard panel.runModal() == .OK else { return }
        let applications = panel.urls.compactMap { externalApplication(at: $0, kind: kind) }
        if kind == .terminal, let application = applications.first {
            selectTerminal(application)
        } else {
            for application in applications {
                setEditor(application, enabled: true)
            }
        }
    }

    private func externalApplication(at url: URL, kind: ExternalApplicationKind) -> ExternalApplication? {
        guard let bundle = Bundle(url: url), let bundleId = bundle.bundleIdentifier else { return nil }
        if let known = ExternalApplicationCatalog.knownApplication(bundleId: bundleId, kind: kind) {
            return known
        }
        let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? url.deletingPathExtension().lastPathComponent
        return ExternalApplication(
            id: "custom.\(bundleId)",
            name: name,
            bundleId: bundleId,
            pathFallback: url.path,
            sfSymbol: kind == .terminal ? "terminal" : "app",
            kind: kind,
            terminalLaunchMethod: kind == .terminal ? .openDirectory : nil
        )
    }

    private func canonicalApplication(
        _ application: ExternalApplication,
        kind: ExternalApplicationKind
    ) -> ExternalApplication {
        ExternalApplicationCatalog.knownApplication(bundleId: application.bundleId, kind: kind)
            ?? application
    }

    private func saveOpenWithSettings() {
        SharedConfiguration.saveOpenWithSettings(openWithSettings, preferences: preferences)
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
