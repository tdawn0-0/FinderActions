import Testing
import Foundation
import Synchronization
import FinderActionsCore

private final class Box<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: T
    init(_ value: T) { self.value = value }
    func withLock<R>(_ body: (inout T) -> R) -> R { lock.lock(); defer { lock.unlock() }; return body(&value) }
}

@Suite("Cut workflow") @MainActor
struct CutWorkflowTests {
    private struct Fixture {
        let root: URL, store: ManifestStore, host: HostRuntimeState, server: IPCServer
        let pasteboard: Box<[[String]]>, snapshots: Box<Int>
    }

    private func fixture(prefs: PreferencesStore = .memory(["notificationsEnabled": false])) throws -> Fixture {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("cutwf-\(UUID().uuidString)").resolvingSymlinksInPath()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let store = ManifestStore(fileURL: root.appendingPathComponent("config/manifest.json"), actionsDirectoryURL: root.appendingPathComponent("config/Actions"))
        let pasteboard = Box<[[String]]>([])
        let host = HostRuntimeState(store: store, preferences: prefs, writePasteboardURLs: { paths in pasteboard.withLock { $0.append(paths) } })
        host.bootstrap()
        let snapshots = Box(0)
        let server = IPCServer(appState: host)
        server.onSnapshotNeeded = { snapshots.withLock { $0 += 1 } }
        return Fixture(root: root, store: store, host: host, server: server, pasteboard: pasteboard, snapshots: snapshots)
    }

    private func send(_ f: Fixture, _ id: String, _ paths: [String], container: String, kind: MenuKind) async throws {
        let before = f.host.logStore.recent().count
        f.server.processJSON(try JSONCoding.encodeToString(ExecuteRequest(actionId: id, paths: paths, containerPath: container, menuKind: kind)))
        let deadline = ContinuousClock.now.advanced(by: .seconds(15))
        while f.host.logStore.recent().count == before && ContinuousClock.now < deadline { try await Task.sleep(for: .milliseconds(10)) }
    }

    private func touch(_ url: URL, _ text: String = "x") throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: url)
    }

    @Test func cutThenMoveHereMovesFilesAndRepublishesMenu() async throws {
        let f = try fixture(); defer { try? FileManager.default.removeItem(at: f.root) }
        let src = f.root.appendingPathComponent("src"), dst = f.root.appendingPathComponent("dst")
        try touch(src.appendingPathComponent("a.txt")); try FileManager.default.createDirectory(at: dst, withIntermediateDirectories: true)
        let file = src.appendingPathComponent("a.txt").path

        #expect(!f.host.effectiveManifest.actions.contains { $0.id == CutActions.moveHereActionId })
        try await send(f, CutActions.cutActionId, [file], container: src.path, kind: .contextualMenuForItems)
        #expect(f.host.cutBuffer.items == [file])
        #expect(f.pasteboard.withLock { $0 } == [[file]])
        #expect(f.snapshots.withLock { $0 } == 1)
        let move = try #require(f.host.effectiveManifest.actions.first { $0.id == CutActions.moveHereActionId })
        #expect(move.name.contains("1"))
        #expect(f.host.effectiveManifest.actions.contains { $0.id == CutActions.clearActionId })

        try await send(f, CutActions.moveHereActionId, [dst.path], container: dst.path, kind: .contextualMenuForContainer)
        #expect(FileManager.default.fileExists(atPath: dst.appendingPathComponent("a.txt").path))
        #expect(!FileManager.default.fileExists(atPath: file))
        #expect(f.host.cutBuffer.isEmpty)
        #expect(f.snapshots.withLock { $0 } == 2)
        #expect(!f.host.effectiveManifest.actions.contains { $0.id == CutActions.moveHereActionId })
        #expect(f.host.logStore.recent().first?.success == true)
    }

    @Test func conflictKeepsItemQueuedAndLogsDetails() async throws {
        let f = try fixture(); defer { try? FileManager.default.removeItem(at: f.root) }
        let src = f.root.appendingPathComponent("src"), dst = f.root.appendingPathComponent("dst")
        try touch(src.appendingPathComponent("a.txt"), "new"); try touch(src.appendingPathComponent("b.txt"))
        try touch(dst.appendingPathComponent("a.txt"), "old")
        let a = src.appendingPathComponent("a.txt").path, b = src.appendingPathComponent("b.txt").path

        try await send(f, CutActions.cutActionId, [a, b], container: src.path, kind: .contextualMenuForItems)
        try await send(f, CutActions.moveHereActionId, [dst.path], container: dst.path, kind: .contextualMenuForContainer)

        #expect(f.host.cutBuffer.items == [a])
        #expect(try String(contentsOf: dst.appendingPathComponent("a.txt"), encoding: .utf8) == "old")
        #expect(FileManager.default.fileExists(atPath: dst.appendingPathComponent("b.txt").path))
        let log = try #require(f.host.logStore.recent().first)
        #expect(!log.success)
        #expect(log.stderrTail?.contains("a.txt") == true)
    }

    @Test func clearEmptiesQueueAndRepublishes() async throws {
        let f = try fixture(); defer { try? FileManager.default.removeItem(at: f.root) }
        let file = f.root.appendingPathComponent("a.txt"); try touch(file)
        try await send(f, CutActions.cutActionId, [file.path], container: f.root.path, kind: .contextualMenuForItems)
        try await send(f, CutActions.clearActionId, [f.root.path], container: f.root.path, kind: .contextualMenuForContainer)
        #expect(f.host.cutBuffer.isEmpty)
        #expect(f.snapshots.withLock { $0 } == 2)
        #expect(FileManager.default.fileExists(atPath: file.path))
    }

    @Test func cutWithoutSelectionNeverCutsTheContainer() throws {
        let f = try fixture(); defer { try? FileManager.default.removeItem(at: f.root) }
        let action = try #require(CutActions.compose(baseManifest: ActionManifest(), enabled: true, cutCount: 0).actions.first)
        let result = f.host.executor.execute(action: action, paths: [], containerPath: f.root.path)
        #expect(!result.success && f.host.cutBuffer.isEmpty && f.pasteboard.withLock { $0 }.isEmpty)
    }

    @Test func togglePersistsAndDisablingClearsQueue() throws {
        let prefs = PreferencesStore.memory(["notificationsEnabled": false])
        let f = try fixture(prefs: prefs); defer { try? FileManager.default.removeItem(at: f.root) }
        #expect(SharedConfiguration.loadCutEnabled(preferences: prefs))
        f.host.cutBuffer.set(["/tmp/x"])

        let app = AppState(store: f.store, preferences: prefs); app.bootstrap()
        #expect(app.cutActionsEnabled)
        app.cutActionsEnabled = false; app.persistSettings()
        f.host.reloadConfiguration()
        #expect(!f.host.cutEnabled && f.host.cutBuffer.isEmpty)
        #expect(!f.host.effectiveManifest.actions.contains { CutActions.isCutAction($0.id) })

        let reopened = AppState(store: f.store, preferences: prefs); reopened.reloadManifest()
        #expect(!reopened.cutActionsEnabled)
        reopened.seedDefaults()
        #expect(reopened.cutActionsEnabled)
        f.host.reloadConfiguration()
        #expect(f.host.cutEnabled)
        #expect(try f.store.load().actions.allSatisfy { !CutActions.isCutAction($0.id) })
    }
}
