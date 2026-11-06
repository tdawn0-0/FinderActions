import Testing
import Foundation
import FinderActionsCore

@Suite("Configuration persistence") @MainActor
struct ConfigurationPersistenceTests {
    func fixture() throws -> (URL, ManifestStore) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = ManifestStore(fileURL: root.appendingPathComponent("manifest.json"), actionsDirectoryURL: root.appendingPathComponent("Actions"))
        try store.ensureDirectories()
        return (root, store)
    }
    @Test func malformedFileIsNeverOverwritten() throws {
        let (root, store) = try fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let bytes = Data("{broken".utf8); try bytes.write(to: store.fileURL)
        let state = AppState(store: store, preferences: .memory())
        state.reloadManifest()
        #expect(state.writesBlocked)
        _ = state.addNewAction()
        #expect(state.isDirty)
        #expect(try Data(contentsOf: store.fileURL) == bytes)
        try store.save(ActionManifest())
        state.reloadManifest()
        #expect(!state.writesBlocked && !state.isDirty)
    }
    @Test func saveFailureRetainsDirtyAndRetryNotifies() throws {
        let (root, store) = try fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let state = AppState(store: store, preferences: .memory())
        state.reloadManifest()
        var changes = 0; state.onManifestChanged = { changes += 1 }
        try FileManager.default.removeItem(at: store.fileURL)
        try FileManager.default.createDirectory(at: store.fileURL, withIntermediateDirectories: true)
        #expect(!state.saveManifest()); #expect(state.isDirty); #expect(changes == 0)
        try FileManager.default.removeItem(at: store.fileURL)
        #expect(state.saveManifest()); #expect(!state.isDirty); #expect(changes == 1)
    }
    @Test func hostKeepsLastGoodConfiguration() throws {
        let (root, store) = try fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let host = HostRuntimeState(store: store, preferences: .memory())
        host.bootstrap(); let original = host.manifest
        try Data("invalid".utf8).write(to: store.fileURL)
        host.reloadConfiguration()
        #expect(host.manifest == original)
        #expect(host.logStore.recent().first?.success == false)
    }
    @Test func validEmptyDefaultsResetAndScripts() throws {
        let (root, store) = try fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let state = AppState(store: store, preferences: .memory())
        state.reloadManifest(); #expect(!state.manifest.actions.isEmpty)
        let script = store.actionsDirectoryURL.appendingPathComponent("copy-path.zsh")
        try "custom".write(to: script, atomically: true, encoding: .utf8)
        try store.save(ActionManifest()); state.reloadManifest()
        #expect(state.manifest.actions.isEmpty)
        #expect(try String(contentsOf: script, encoding: .utf8) == "custom")
        state.seedDefaults(); #expect(!state.manifest.actions.isEmpty)
    }
    @Test func flushUsesLatestEditAndCancelsScheduledSave() async throws {
        let (root, store) = try fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let state = AppState(store: store, preferences: .memory()); state.reloadManifest()
        var changes = 0; state.onManifestChanged = { changes += 1 }
        state.manifest.actions[0].name = "first"; state.scheduleManifestSave()
        state.manifest.actions[0].name = "latest"; state.scheduleManifestSave()
        state.flushPendingManifestSave()
        #expect(try store.load().actions[0].name == "latest"); #expect(changes == 1)
        try await Task.sleep(for: .milliseconds(500)); #expect(changes == 1)
    }
    @Test func generatedMigrationAndFailedMigrationPreserveInput() throws {
        let (root, store) = try fixture(); defer { try? FileManager.default.removeItem(at: root) }
        var old = DefaultActions.manifest()
        old.actions.append(ActionDefinition(id: "legacy-terminal", name: "Terminal", type: .terminal))
        try store.save(old)
        let original = try Data(contentsOf: store.fileURL)
        enum Failure: Error { case injected }
        #expect(throws: Failure.self) {
            try SharedConfiguration.bootstrap(store: store, preferences: .memory(), migrationSave: { _ in throw Failure.injected })
        }
        #expect(try Data(contentsOf: store.fileURL) == original)
        let result = try SharedConfiguration.bootstrap(store: store, preferences: .memory())
        #expect(!result.manifest.actions.contains { $0.type == .terminal })
        #expect(try store.load() == result.manifest)
    }
    @Test func resetCancelsPendingEdit() async throws {
        let (root, store) = try fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let state = AppState(store: store, preferences: .memory()); state.reloadManifest()
        state.manifest.actions[0].name = "unwanted"; state.scheduleManifestSave()
        state.seedDefaults()
        try await Task.sleep(for: .milliseconds(500))
        #expect(try store.load() == DefaultActions.manifest()); #expect(!state.isDirty)
    }
    @Test func naturalDebouncePersistsLatestEdit() async throws {
        let (root, store) = try fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let state = AppState(store: store, preferences: .memory()); state.reloadManifest()
        var callbacks = 0; state.onManifestChanged = { callbacks += 1 }
        state.manifest.actions[0].name = "first"; state.scheduleManifestSave()
        state.manifest.actions[0].name = "latest"; state.scheduleManifestSave()
        for _ in 0..<100 where state.isDirty { try await Task.sleep(for: .milliseconds(10)) }
        #expect(!state.isDirty); #expect(callbacks == 1)
        #expect(try store.load().actions[0].name == "latest")
    }
    @Test func malformedManifestKeepsIndependentApplicationPreferences() throws {
        let (root, store) = try fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let prefs = PreferencesStore.memory()
        var settings = OpenWithSettings.defaults
        settings.editors = []
        SharedConfiguration.saveOpenWithSettings(settings, preferences: prefs)
        try Data("broken".utf8).write(to: store.fileURL)
        let state = AppState(store: store, preferences: prefs); state.reloadManifest()
        let host = HostRuntimeState(store: store, preferences: prefs); host.bootstrap()
        #expect(state.openWithSettings == settings); #expect(host.openWithSettings == settings)
        #expect(state.writesBlocked)
    }
}
