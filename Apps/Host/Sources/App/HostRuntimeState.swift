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
    private(set) var notificationMode: ExecutionNotificationMode = .all
    static let maximumConcurrentExecutions = 16
    private(set) var activeExecutions: [String: ActiveExecution] = [:]
    var onActivityChanged: (() -> Void)?

    let preferences: PreferencesStore

    let store: ManifestStore
    let logStore: ExecLogStore
    let executor: ActionExecutor

    var effectiveManifest: ActionManifest {
        OpenWithActions.compose(baseManifest: manifest, settings: openWithSettings)
    }

    var needsOnboarding: Bool {
        !preferences.bool(forKey: "didCompleteOnboarding")
    }

    init(store: ManifestStore = .makeDefault(), logStore: ExecLogStore? = nil, preferences: PreferencesStore = .live) {
        self.preferences = preferences
        self.store = store
        let logsDirectory = store.fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("logs", isDirectory: true)
        self.logStore = logStore ?? ExecLogStore(directory: logsDirectory)
        self.executor = ActionExecutor(store: store)
        loadPreferences()
    }

    func bootstrap() {
        do {
            (manifest, openWithSettings) = try SharedConfiguration.bootstrap(store: store, preferences: preferences)
        } catch {
            openWithSettings = SharedConfiguration.loadOpenWithSettings(preferences: preferences)
            recordConfigurationFailure()
        }
        loadPreferences()
    }

    /// Reload only externally editable configuration. Execution objects and IPC
    /// remain alive so a Settings save does not churn the resident process.
    func reloadConfiguration() {
        do { manifest = OpenWithActions.baseManifest(from: try store.load()) }
        catch { recordConfigurationFailure() }
        openWithSettings = SharedConfiguration.loadOpenWithSettings(preferences: preferences)
        loadPreferences()
    }

    private func recordConfigurationFailure() {
        recordLog(ExecLogEntry(actionId: "configuration", success: false,
                               summary: "Could not load configuration; previous actions retained", paths: []))
    }

    func recordLog(_ entry: ExecLogEntry) {
        logStore.append(entry)
        if WorkflowFeedback.verifiesSetup(entry) {
            preferences.set(true, forKey: "finderSetupVerified")
        }
        onActivityChanged?()
        if !preferences.isInMemory {
            DistributedNotificationCenter.default().postNotificationName(WorkflowFeedback.executionChanged, object: nil, deliverImmediately: true)
        }
    }

    @discardableResult
    func beginExecution(request: ExecuteRequest, actionName: String, now: Date = Date()) -> Bool {
        guard activeExecutions.count < Self.maximumConcurrentExecutions,
              activeExecutions[request.requestId] == nil else { return false }
        activeExecutions[request.requestId] = ActiveExecution(id: request.requestId,
            actionID: request.actionId, actionName: actionName, paths: request.paths, startedAt: now)
        onActivityChanged?()
        return true
    }

    @discardableResult
    func endExecution(requestID: String) -> ActiveExecution? {
        let run = activeExecutions.removeValue(forKey: requestID)
        onActivityChanged?()
        return run
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

    private func loadPreferences() {
        notificationMode = ExecutionNotificationMode.load(preferences: preferences)
        notificationsEnabled = notificationMode != .off
    }

}
