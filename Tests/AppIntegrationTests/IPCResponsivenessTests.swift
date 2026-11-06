import Testing
import Foundation
import FinderActionsCore

private final class Counter: @unchecked Sendable {
    let lock = NSLock()
    var count = 0
    func increment() { lock.lock(); defer { lock.unlock() }; count += 1 }
    var value: Int { lock.lock(); defer { lock.unlock() }; return count }
}
@Suite("IPC responsiveness") @MainActor
struct IPCResponsivenessTests {
    @Test func blockedValidationDoesNotBlockMainActorAndDeduplicates() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let prefs = PreferencesStore.memory(["notificationsEnabled": false])
        let host = HostRuntimeState(store: ManifestStore(fileURL: root.appendingPathComponent("manifest.json"), actionsDirectoryURL: root.appendingPathComponent("Actions")), preferences: prefs)
        host.bootstrap()
        let entered = Counter(), executions = Counter()
        let release = DispatchSemaphore(value: 0)
        defer { release.signal() }
        let action = host.manifest.actions[0]
        let server = IPCServer(appState: host, validate: { _, _ in
            entered.increment()
            _ = release.wait(timeout: .now() + 5)
            return .success(action)
        }, execute: { _, _ in executions.increment(); return ExecResult(success: true, summary: "stub") })
        let request = ExecuteRequest(actionId: action.id, paths: [root.path])
        let json = try JSONCoding.encodeToString(request)
        server.processJSON(json); server.processJSON(json)
        for _ in 0..<100 where entered.value == 0 { try await Task.sleep(for: .milliseconds(10)) }
        #expect(entered.value == 1)
        // This point is a MainActor heartbeat while the validator is held.
        #expect(executions.value == 0)
        release.signal()
        for _ in 0..<100 where host.logStore.recent().isEmpty { try await Task.sleep(for: .milliseconds(10)) }
        #expect(executions.value == 1); #expect(host.logStore.recent().count == 1)
    }
    @Test func rejectedRequestDoesNotExecute() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let host = HostRuntimeState(store: ManifestStore(fileURL: root.appendingPathComponent("manifest.json"), actionsDirectoryURL: root.appendingPathComponent("Actions")), preferences: .memory(["notificationsEnabled": false]))
        let executions = Counter()
        let server = IPCServer(appState: host, validate: { _, _ in .failure(.unknownAction("missing")) }, execute: { _, _ in executions.increment(); return ExecResult(success: true, summary: "unexpected") })
        server.processJSON(try JSONCoding.encodeToString(ExecuteRequest(actionId: "missing", paths: [])))
        for _ in 0..<100 where host.logStore.recent().isEmpty { try await Task.sleep(for: .milliseconds(10)) }
        #expect(executions.value == 0); #expect(host.logStore.recent().first?.success == false)
    }
}
