import Foundation
import Testing
@testable import FinderActionsCore

@Suite("Cut actions")
struct CutActionsTests {
    private func ids(_ manifest: ActionManifest) -> [String] { manifest.actions.map(\.id) }

    private func visible(_ actionId: String, count: Int, items: [String], dirs: [Bool], kind: MenuKind) -> Bool {
        let manifest = CutActions.compose(baseManifest: ActionManifest(), enabled: true, cutCount: count)
        let snapshot = SnapshotBuilder.build(from: manifest)
        let filtered = SnapshotBuilder.filter(snapshot, context: SelectionContext(paths: items, isDirectory: dirs, menuKind: kind))
        return filtered.items.contains { $0.actionId == actionId }
    }

    @Test func composeRespectsToggleAndQueue() {
        #expect(ids(CutActions.compose(baseManifest: ActionManifest(), enabled: false, cutCount: 3)).isEmpty)
        #expect(ids(CutActions.compose(baseManifest: ActionManifest(), enabled: true, cutCount: 0)) == [CutActions.cutActionId])
        #expect(Set(ids(CutActions.compose(baseManifest: ActionManifest(), enabled: true, cutCount: 2)))
            == [CutActions.cutActionId, CutActions.moveHereActionId, CutActions.clearActionId])
    }

    @Test func generatedActionsAreNeverPersisted() {
        let composed = CutActions.compose(baseManifest: DefaultActions.manifest(), enabled: true, cutCount: 1)
        #expect(OpenWithActions.baseManifest(from: composed) == OpenWithActions.baseManifest(from: DefaultActions.manifest()))
    }

    @Test func cutOnlyShowsForItemSelections() {
        #expect(visible(CutActions.cutActionId, count: 0, items: ["/a.txt"], dirs: [false], kind: .contextualMenuForItems))
        #expect(!visible(CutActions.cutActionId, count: 0, items: [], dirs: [], kind: .contextualMenuForContainer))
        #expect(!visible(CutActions.cutActionId, count: 0, items: [], dirs: [], kind: .contextualMenuForItems))
        #expect(!visible(CutActions.cutActionId, count: 0, items: ["/a.txt"], dirs: [false], kind: .toolbarItemMenu))
    }

    @Test func moveHereShowsForBlankSpaceOrSingleFolder() {
        let id = CutActions.moveHereActionId
        #expect(!visible(id, count: 0, items: [], dirs: [], kind: .contextualMenuForContainer))
        #expect(visible(id, count: 1, items: [], dirs: [], kind: .contextualMenuForContainer))
        #expect(visible(id, count: 1, items: ["/d"], dirs: [true], kind: .contextualMenuForItems))
        #expect(!visible(id, count: 1, items: ["/a.txt"], dirs: [false], kind: .contextualMenuForItems))
        #expect(!visible(id, count: 1, items: ["/d", "/e"], dirs: [true, true], kind: .contextualMenuForItems))
    }

    @Test func clearShowsInBothMenusOnceQueued() {
        let id = CutActions.clearActionId
        #expect(visible(id, count: 1, items: [], dirs: [], kind: .contextualMenuForContainer))
        #expect(visible(id, count: 1, items: ["/a.txt"], dirs: [false], kind: .contextualMenuForItems))
        #expect(!visible(id, count: 0, items: ["/a.txt"], dirs: [false], kind: .contextualMenuForItems))
    }

    @Test func validatorEnforcesMenuKind() {
        let manifest = CutActions.compose(baseManifest: ActionManifest(), enabled: true, cutCount: 1)
        let info: (String) -> Bool? = { ["/d": true, "/d/a.txt": false][$0] }
        func check(_ id: String, _ paths: [String], _ kind: MenuKind?) -> Bool {
            let request = ExecuteRequest(actionId: id, paths: paths, containerPath: "/d", menuKind: kind)
            if case .success = ExecuteRequestValidator.validate(request, manifest: manifest, fileInfo: info) { return true }
            return false
        }
        #expect(check(CutActions.cutActionId, ["/d/a.txt"], .contextualMenuForItems))
        #expect(!check(CutActions.cutActionId, ["/d/a.txt"], nil))
        #expect(!check(CutActions.cutActionId, ["/d"], .contextualMenuForContainer))
        #expect(check(CutActions.moveHereActionId, ["/d"], .contextualMenuForContainer))
        #expect(!check(CutActions.moveHereActionId, ["/d/a.txt"], .contextualMenuForItems))
    }

    @Test func builtinValidationAcceptsOnlyCutIds() {
        var action = ActionDefinition(id: "x", name: "X", type: .builtin, builtinId: "cut-add")
        #expect(ActionAuthoring.validationError(action) == nil)
        action.builtinId = "other"
        #expect(ActionAuthoring.validationError(action) != nil)
    }

    @Test func bufferNormalizesDeduplicatesAndPrunes() {
        let buffer = CutBuffer()
        let stored = buffer.set(["/a/b/", "/a/b", "/a/b/c.txt", "/a/x.txt", "/a/bb"])
        #expect(stored == ["/a/b", "/a/x.txt", "/a/bb"])
        #expect(buffer.count == 3 && !buffer.isEmpty)
        buffer.remove(["/a/x.txt"])
        #expect(buffer.items == ["/a/b", "/a/bb"])
        #expect(buffer.clear() == 2 && buffer.isEmpty)
    }
}

@Suite("Cut file mover")
struct CutFileMoverTests {
    private func makeRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("cut-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.resolvingSymlinksInPath()
    }

    private func write(_ url: URL, _ text: String = "x") throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: url)
    }

    @Test func movesFilesFoldersAndSymlinks() throws {
        let root = try makeRoot(); defer { try? FileManager.default.removeItem(at: root) }
        let src = root.appendingPathComponent("src"), dst = root.appendingPathComponent("dst")
        try write(src.appendingPathComponent("a.txt")); try write(src.appendingPathComponent("dir/inner.txt"))
        try FileManager.default.createDirectory(at: dst, withIntermediateDirectories: true)
        let link = src.appendingPathComponent("dangling")
        try FileManager.default.createSymbolicLink(atPath: link.path, withDestinationPath: "/nonexistent-target")
        let sources = ["a.txt", "dir", "dangling"].map { src.appendingPathComponent($0).path }

        let result = CutFileMover.move(sources: sources, toDirectory: dst.path)

        #expect(result.isSuccess && result.movedPaths == sources && result.remainingPaths.isEmpty)
        #expect(FileManager.default.fileExists(atPath: dst.appendingPathComponent("dir/inner.txt").path))
        #expect((try? FileManager.default.destinationOfSymbolicLink(atPath: dst.appendingPathComponent("dangling").path)) == "/nonexistent-target")
        #expect(!FileManager.default.fileExists(atPath: src.appendingPathComponent("a.txt").path))
    }

    @Test func conflictsAreSkippedWithoutOverwriting() throws {
        let root = try makeRoot(); defer { try? FileManager.default.removeItem(at: root) }
        let src = root.appendingPathComponent("src"), dst = root.appendingPathComponent("dst")
        try write(src.appendingPathComponent("same.txt"), "new"); try write(src.appendingPathComponent("free.txt"))
        try write(dst.appendingPathComponent("same.txt"), "old")
        let same = src.appendingPathComponent("same.txt").path, free = src.appendingPathComponent("free.txt").path

        let result = CutFileMover.move(sources: [same, free], toDirectory: dst.path)

        #expect(!result.isSuccess)
        #expect(result.conflictPaths == [same] && result.remainingPaths == [same])
        #expect(result.movedPaths == [free] && result.completedPaths == [free])
        #expect(try String(contentsOf: dst.appendingPathComponent("same.txt"), encoding: .utf8) == "old")
        #expect(FileManager.default.fileExists(atPath: same))
    }

    @Test func sameDirectoryIsANoOpThatLeavesTheQueue() throws {
        let root = try makeRoot(); defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("a.txt"); try write(file)
        let result = CutFileMover.move(sources: [file.path], toDirectory: root.path)
        #expect(result.alreadyInDestinationPaths == [file.path] && result.remainingPaths.isEmpty && result.isSuccess)
        #expect(result.completedPaths == [file.path])
        #expect(FileManager.default.fileExists(atPath: file.path))
    }

    @Test func foldersCannotMoveIntoThemselves() throws {
        let root = try makeRoot(); defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appendingPathComponent("f"), child = folder.appendingPathComponent("child")
        try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
        for destination in [folder, child] {
            let result = CutFileMover.move(sources: [folder.path], toDirectory: destination.path)
            #expect(result.invalidDestinationPaths == [folder.path] && result.remainingPaths == [folder.path] && result.movedPaths.isEmpty)
        }
        #expect(FileManager.default.fileExists(atPath: child.path))
    }

    @Test func missingSourcesAreReportedAndDropped() throws {
        let root = try makeRoot(); defer { try? FileManager.default.removeItem(at: root) }
        let gone = root.appendingPathComponent("gone.txt").path
        let dst = root.appendingPathComponent("dst"); try FileManager.default.createDirectory(at: dst, withIntermediateDirectories: true)
        let result = CutFileMover.move(sources: [gone], toDirectory: dst.path)
        #expect(result.missingPaths == [gone] && result.remainingPaths.isEmpty && result.completedPaths == [gone] && !result.isSuccess)
    }

    @Test func invalidDestinationKeepsEverythingQueued() throws {
        let root = try makeRoot(); defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("a.txt"); try write(file)
        let result = CutFileMover.move(sources: [file.path], toDirectory: root.appendingPathComponent("nope").path)
        #expect(result.failedItems.count == 1 && result.remainingPaths == [file.path] && result.movedPaths.isEmpty)
    }
}
