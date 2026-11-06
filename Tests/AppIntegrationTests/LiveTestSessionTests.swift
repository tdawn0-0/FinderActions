import Testing
import Foundation
import FinderActionsCore

@Suite("Live test and authoring") @MainActor
struct LiveTestSessionTests {
    func fixture() throws -> (URL, ManifestStore, [String]) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = ManifestStore(fileURL: root.appendingPathComponent("manifest.json"), actionsDirectoryURL: root.appendingPathComponent("Actions"))
        try store.ensureDirectories()
        let paths = ["含 空格.PNG", "second.jpg"].map { root.appendingPathComponent($0).path }
        for path in paths { try Data("example".utf8).write(to: URL(fileURLWithPath: path)) }
        return (root, store, paths)
    }
    @Test func previewUsesExactProductionArgumentsAndOnlyPublicEnvironment() async throws {
        let (root, store, paths) = try fixture(); defer { try? FileManager.default.removeItem(at: root) }
        var action = ActionTemplate.perFile.make(id: "test", sortIndex: 0)
        action.enabled = true; action.extRules = ExtRules(pathExtensions: ["png", "jpg"])
        let preview = try LiveTestSession.buildPreview(action: action, paths: paths, container: root.path, store: store)
        #expect(preview.paths == paths); #expect(preview.workingDirectory == root.path); #expect(preview.visible)
        let argv = ShellEnvironment.argvForInlineScript(interpreter: "/bin/zsh", script: action.shell!.scriptInline!, paths: paths)
        #expect(preview.description.contains(String(data: try JSONEncoder().encode(argv), encoding: .utf8)!))
        #expect(!preview.description.contains("PATH=")); #expect(preview.description.contains("FA_PATH_COUNT=2"))
        var recorded: [ExecLogEntry] = []
        let session = LiveTestSession(); session.paths = paths; session.container = root.path
        await session.validate(action: action, store: store)
        await session.run(action: action, executor: ActionExecutor(store: store), record: { recorded.append($0) })
        #expect(session.result?.success == true)
        #expect(session.result?.stdout.contains(paths[0]) == true)
        #expect(recorded.count == 1); #expect(recorded[0].source == .test)
        #expect(session.resultActionId == "test")
        session.invalidate(); #expect(session.result == nil && session.preview == nil)
    }
    @Test func containerFallbackAndMissingInputs() throws {
        let (root, store, paths) = try fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let action = ActionTemplate.currentDirectory.make(id: "test", sortIndex: 0)
        let preview = try LiveTestSession.buildPreview(action: action, paths: [], container: root.path, store: store)
        #expect(preview.paths == [root.path])
        #expect(throws: Error.self) { try LiveTestSession.buildPreview(action: action, paths: [], container: nil, store: store) }
        #expect(throws: Error.self) { try LiveTestSession.buildPreview(action: action, paths: [paths[0] + "missing"], container: nil, store: store) }
        var fileAction = action; fileAction.shell?.scriptFile = "missing.zsh"
        #expect(throws: Error.self) { try LiveTestSession.buildPreview(action: fileAction, paths: paths, container: nil, store: store) }
    }
    @Test func legacySourceSwitchAndDraftValidation() throws {
        let (root, store, _) = try fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let state = AppState(store: store, preferences: .memory()); state.reloadManifest()
        for template in ActionTemplate.allCases {
            let action = state.addAction(template: template); #expect(!action.enabled)
        }
        let application = state.manifest.actions.last { $0.type == .application }!
        state.setEnabled(actionId: application.id, enabled: true)
        #expect(state.manifest.actions.first { $0.id == application.id }?.enabled == false)
        var dual = ActionTemplate.blank.make(id: "dual", sortIndex: 0)
        dual.shell?.scriptFile = "old.zsh"; dual.shell?.scriptInline = "echo preserved"
        let decoded = try JSONDecoder().decode(ActionDefinition.self, from: JSONEncoder().encode(dual))
        #expect(decoded.shell?.scriptFile == "old.zsh")
        ActionAuthoring.useInline(&dual)
        #expect(dual.shell?.scriptFile == nil); #expect(dual.shell?.scriptInline == "echo preserved")
        #expect(ActionAuthoring.normalizedExtensions(".PNG, jpg; PNG") == ["jpg", "png"])
        dual.extRules = ExtRules(pathExtensions: ["jpg"], foldersOnly: true)
        #expect(ActionAuthoring.validationError(dual) != nil)
        dual.extRules = ExtRules(foldersOnly: true, filesOnly: true)
        #expect(ActionAuthoring.validationError(dual) != nil)
    }
    @Test func staleInputsAndActionsCannotExecute() async throws {
        let (root, store, paths) = try fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let session = LiveTestSession(); session.paths = paths
        var action = ActionTemplate.perFile.make(id: "test", sortIndex: 0)
        var recorded = 0
        await session.validate(action: action, store: store)
        action.shell?.scriptInline = "echo changed"
        await session.run(action: action, executor: ActionExecutor(store: store), record: { _ in recorded += 1 })
        #expect(recorded == 0)
        await session.validate(action: action, store: store)
        session.paths = [paths[0]]
        await session.run(action: action, executor: ActionExecutor(store: store), record: { _ in recorded += 1 })
        #expect(recorded == 0)
        action.showWhen = .filesOnly; action.extRules = ExtRules(foldersOnly: true)
        #expect(ActionAuthoring.validationError(action) != nil)
    }

    @Test func validationGenerationDropsStaleResults() async throws {
        let (root, store, paths) = try fixture(); defer { try? FileManager.default.removeItem(at: root) }
        let session = LiveTestSession(); session.paths = paths
        let action = ActionTemplate.perFile.make(id: "test", sortIndex: 0)
        let first = Task { await session.validate(action: action, store: store) }
        await Task.yield()
        session.paths = [paths[0] + "missing"]
        await session.validate(action: action, store: store)
        await first.value
        #expect(session.preview == nil); #expect(session.validationError != nil)
    }
}
