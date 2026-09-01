import Testing
import Foundation
@testable import FinderActionsCore

@Suite("Manifest & snapshot codec")
struct ManifestTests {
    @Test func manifestRoundTrip() throws {
        let original = DefaultActions.manifest()
        let data = try JSONCoding.encode(original)
        let decoded = try JSONCoding.decode(ActionManifest.self, from: data)
        #expect(decoded.version == 2)
        #expect(decoded.actions.count == original.actions.count)
        #expect(decoded == original)
    }

    @Test func manifestStoreSaveAndLoad() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FA-Manifest-\(UUID().uuidString)", isDirectory: true)
        let manifestURL = root.appendingPathComponent("manifest.json")
        let actionsURL = root.appendingPathComponent("Actions", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let store = ManifestStore(fileURL: manifestURL, actionsDirectoryURL: actionsURL)
        let m = DefaultActions.manifest()
        try store.save(m)

        #expect(FileManager.default.fileExists(atPath: manifestURL.path))
        #expect(FileManager.default.fileExists(atPath: actionsURL.path))

        let loaded = try store.load()
        #expect(loaded == m)
        #expect(loaded.actions.first?.id == "copy-path")
    }

    @Test func loadMissingThrows() {
        let store = ManifestStore(
            fileURL: URL(fileURLWithPath: "/tmp/definitely-missing-fa-\(UUID().uuidString).json"),
            actionsDirectoryURL: URL(fileURLWithPath: "/tmp")
        )
        #expect(throws: ManifestError.self) {
            try store.load()
        }
    }

    @Test func resolveScriptPathRelativeAndAbsolute() {
        let actions = URL(fileURLWithPath: "/Users/me/Library/Application Support/FinderActions/Actions")
        let store = ManifestStore(
            fileURL: actions.deletingLastPathComponent().appendingPathComponent("manifest.json"),
            actionsDirectoryURL: actions
        )
        #expect(
            store.resolveScriptPath("copy-path.zsh").path
                == actions.appendingPathComponent("copy-path.zsh").path
        )
        #expect(store.resolveScriptPath("/opt/scripts/x.zsh").path == "/opt/scripts/x.zsh")
    }

    @Test func defaultActionsIncludeRequiredTypes() {
        let actions = DefaultActions.actions()
        #expect(actions.contains { $0.type == .shell })
        #expect(!actions.contains { $0.type == .terminal })
        #expect(!actions.contains { $0.type == .application })
        #expect(DefaultActions.bundledScripts()["copy-path.zsh"] != nil)
        #expect(DefaultActions.bundledScripts()["copy-name.zsh"] != nil)
    }

    @Test func snapshotEncodeDecode() throws {
        let snap = SnapshotBuilder.build(from: DefaultActions.manifest())
        #expect(snap.hostRunning)
        #expect(!snap.items.isEmpty)
        let enabledCount = DefaultActions.actions().filter(\.enabled).count
        #expect(snap.items.count == enabledCount)

        let data = try JSONCoding.encode(snap)
        let decoded = try JSONCoding.decode(MenuSnapshot.self, from: data)
        #expect(decoded.items.map(\.actionId) == snap.items.map(\.actionId))
    }

    @Test func executeRequestRoundTrip() throws {
        let req = ExecuteRequest(
            actionId: "open-terminal",
            paths: ["/Users/me/proj/a b.swift"],
            containerPath: "/Users/me/proj",
            menuKind: .contextualMenuForItems
        )
        let s = try JSONCoding.encodeToString(req)
        let decoded = try JSONCoding.decode(ExecuteRequest.self, from: s)
        #expect(decoded.actionId == "open-terminal")
        #expect(decoded.paths == ["/Users/me/proj/a b.swift"])
        #expect(decoded.containerPath == "/Users/me/proj")
        #expect(decoded.menuKind == .contextualMenuForItems)
    }
}
