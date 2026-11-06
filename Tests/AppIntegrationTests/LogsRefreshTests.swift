import Testing
import Foundation
import FinderActionsCore

@Suite("Log refresh") @MainActor
struct LogsRefreshTests {
    @Test func externalAppendRefreshClearAndMissing() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = ManifestStore(fileURL: root.appendingPathComponent("manifest.json"), actionsDirectoryURL: root.appendingPathComponent("Actions"))
        let logs = ExecLogStore(directory: root.appendingPathComponent("logs"))
        let state = AppState(store: store, logStore: logs, preferences: .memory())
        state.refreshLogs(); #expect(state.logs.isEmpty)
        let external = ExecLogStore(directory: logs.fileURL.deletingLastPathComponent())
        for n in 0..<205 { external.append(ExecLogEntry(actionId: "\(n)", success: true, summary: "result", paths: [])) }
        #expect(state.logs.isEmpty)
        state.refreshLogs(); #expect(state.logs.count == 200); #expect(state.logs.first?.actionId == "204")
        let ids = state.logs.map(\.id); state.refreshLogs(); #expect(state.logs.map(\.id) == ids)
        state.clearLogs(); state.refreshLogs(); #expect(state.logs.isEmpty)
    }
}
