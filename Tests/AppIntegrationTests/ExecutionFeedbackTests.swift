import Testing
import Foundation
import FinderActionsCore

@Suite("Execution feedback and setup verification") @MainActor
struct ExecutionFeedbackTests {
    @Test func registrationNeverConfusesRegisteredWithEnabled() {
        let id = IPCConstants.extensionBundleId
        #expect(ExtensionRegistration.parse("+ \(id) (1.0)", bundleID: id) == .enabled)
        #expect(ExtensionRegistration.parse("- \(id) (1.0)", bundleID: id) == .registered)
        #expect(ExtensionRegistration.parse("  \(id) (1.0)", bundleID: id) == .registered)
        #expect(ExtensionRegistration.parse("", bundleID: id) == .notRegistered)
        #expect(ExtensionRegistration.parse("Permission denied", bundleID: id) == .unknown)
    }

    @Test func notificationMigrationAndModes() {
        #expect(ExecutionNotificationMode.load(preferences: .memory()) == .all)
        #expect(ExecutionNotificationMode.load(preferences: .memory(["notificationsEnabled": false])) == .off)
        #expect(ExecutionNotificationMode.load(preferences: .memory(["notificationsEnabled": true])) == .all)
        let prefs = PreferencesStore.memory()
        ExecutionNotificationMode.failures.persist(preferences: prefs)
        #expect(ExecutionNotificationMode.load(preferences: prefs) == .failures)
        #expect(!ExecutionNotificationMode.failures.shouldNotify(success: true))
        #expect(ExecutionNotificationMode.failures.shouldNotify(success: false))
        #expect(!ExecutionNotificationMode.off.shouldNotify(success: false))
    }

    @Test func oldLogsDecodeWithoutNewFields() throws {
        let data = Data(#"{"id":"old","timestamp":"2026-11-06T00:00:00Z","actionId":"x","success":true,"summary":"ok","paths":[]}"#.utf8)
        let entry = try JSONDecoder().decode(ExecLogEntry.self, from: data)
        #expect(entry.actionName == nil && entry.durationSeconds == nil && entry.source == nil)
        let modern = ExecLogEntry(actionId: "x", success: false, summary: "bad", paths: ["/tmp/中文"], actionName: "Name", durationSeconds: 1.25, source: .finder)
        #expect(try JSONDecoder().decode(ExecLogEntry.self, from: JSONEncoder().encode(modern)) == modern)
    }

    @Test func onlySuccessfulFinderCopyPathVerifiesSetup() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let prefs = PreferencesStore.memory()
        let host = HostRuntimeState(store: ManifestStore(fileURL: root.appendingPathComponent("manifest.json"), actionsDirectoryURL: root.appendingPathComponent("Actions")), preferences: prefs)
        host.recordLog(ExecLogEntry(actionId: "copy-path", success: true, summary: "test", paths: [], source: .test))
        host.recordLog(ExecLogEntry(actionId: "copy-name", success: true, summary: "other", paths: [], source: .finder))
        host.recordLog(ExecLogEntry(actionId: "copy-path", success: false, summary: "failed", paths: [], source: .finder))
        #expect(!prefs.bool(forKey: "finderSetupVerified"))
        host.recordLog(ExecLogEntry(actionId: "copy-path", success: true, summary: "copied", paths: [], source: .finder))
        #expect(prefs.bool(forKey: "finderSetupVerified"))
    }

    @Test func concurrentRunsHaveIndependentLifetimesAndNavigationIsValidated() {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let prefs = PreferencesStore.memory()
        let host = HostRuntimeState(store: ManifestStore(fileURL: root.appendingPathComponent("manifest.json"), actionsDirectoryURL: root.appendingPathComponent("Actions")), preferences: prefs)
        let first = ExecuteRequest(actionId: "a", paths: ["/tmp/a"])
        let second = ExecuteRequest(actionId: "b", paths: ["/tmp/b"])
        host.beginExecution(request: first, actionName: "First")
        host.beginExecution(request: second, actionName: "Second")
        #expect(host.activeExecutions.count == 2)
        #expect(host.endExecution(requestID: first.requestId)?.actionName == "First")
        #expect(host.activeExecutions.count == 1)
        #expect(host.endExecution(requestID: first.requestId) == nil)
        host.endExecution(requestID: second.requestId)
        #expect(host.activeExecutions.isEmpty)
        WorkflowFeedback.requestNavigation(destination: "bad", actionID: "x", preferences: prefs)
        #expect(prefs.object(forKey: "settingsDestination") == nil)
        WorkflowFeedback.requestNavigation(destination: "actions", actionID: "a", preferences: prefs)
        #expect(prefs.object(forKey: "settingsDestination") as? String == "actions")
        #expect(prefs.object(forKey: "settingsActionID") as? String == "a")
    }

    @Test func skippingAndVerifiedCompletionRemainDistinct() {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let prefs = PreferencesStore.memory()
        let app = AppState(store: ManifestStore(fileURL: root.appendingPathComponent("manifest.json"), actionsDirectoryURL: root.appendingPathComponent("Actions")), preferences: prefs)
        app.showOnboarding = true
        app.completeOnboarding()
        #expect(app.showOnboarding && !prefs.bool(forKey: "didCompleteOnboarding"))
        app.completeOnboarding(skipped: true)
        #expect(!app.showOnboarding && prefs.bool(forKey: "onboardingSkipped"))
        #expect(!app.finderSetupVerified)
        app.logs = [ExecLogEntry(actionId: "copy-path", success: true, summary: "test", paths: [], source: .test)]
        #expect(!app.finderSetupVerified)
        app.logs = [ExecLogEntry(actionId: "copy-path", success: true, summary: "copied", paths: [], source: .finder)]
        app.completeOnboarding()
        #expect(app.finderSetupVerified && !prefs.bool(forKey: "onboardingSkipped"))
    }

    @Test func rejectedIPCCompletesActivityAndWritesReadableFailure() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let host = HostRuntimeState(store: ManifestStore(fileURL: root.appendingPathComponent("manifest.json"), actionsDirectoryURL: root.appendingPathComponent("Actions")), preferences: .memory(["notificationsEnabled": false]))
        host.bootstrap()
        let server = IPCServer(appState: host, validate: { _, _ in .failure(.unknownAction("missing")) }, execute: { _, _ in ExecResult(success: true, summary: "must not run") })
        let request = ExecuteRequest(actionId: "copy-path", paths: [root.path])
        server.processJSON(try JSONCoding.encodeToString(request))
        #expect(host.activeExecutions.count == 1)
        let deadline = ContinuousClock.now.advanced(by: .seconds(10))
        while host.logStore.recent().isEmpty && ContinuousClock.now < deadline { try? await Task.sleep(for: .milliseconds(10)) }
        #expect(host.activeExecutions.isEmpty)
        let log = try #require(host.logStore.recent().first)
        #expect(log.actionName == "Copy Path")
        #expect(log.durationSeconds != nil && !log.success && log.source == .finder)
    }
}
