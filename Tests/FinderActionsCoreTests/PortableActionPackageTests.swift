import Testing
import Foundation
@testable import FinderActionsCore

@Suite("Portable action packages")
struct PortableActionPackageTests {
    private func fixture() throws -> (URL, ManifestStore) {
        let root = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent("FA-Package-\(UUID())")
        let store = ManifestStore(fileURL: root.appendingPathComponent("manifest.json"), actionsDirectoryURL: root.appendingPathComponent("Actions"))
        try store.ensureDirectories()
        return (root, store)
    }

    @Test func fileExportImportRoundTripIsPortableAndDisabled() throws {
        let (root, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = "#!/bin/zsh\nprint -r -- \"$@\"\n"
        let path = store.actionsDirectoryURL.appendingPathComponent("空 格.zsh")
        try Data(source.utf8).write(to: path)
        let original = ActionDefinition(id: "shared", name: "处理 图片", type: .shell, extRules: ExtRules(pathExtensions: ["png"]), shell: ShellConfig(scriptFile: path.path, scriptInline: "not active"))
        let package = try PortableActionPackage.export(action: original, store: store, dependencies: "zsh")
        let file = root.appendingPathComponent("example.faaction")
        try package.encoded().write(to: file)
        let loaded = try PortableActionPackage.read(from: file)
        #expect(loaded == package)
        let installed = try loaded.install(into: store, manifest: ActionManifest(actions: [original]))
        let action = try #require(installed.actions.last)
        #expect(action.name == "处理 图片 (2)")
        #expect(action.id != original.id)
        #expect(!action.enabled)
        #expect(action.extRules == original.extRules)
        #expect(action.shell?.scriptInline == "not active")
        let script = store.resolveScriptPath(try #require(action.shell?.scriptFile))
        #expect(try String(contentsOf: script, encoding: .utf8) == source)
        #expect(try store.load() == installed)
    }

    @Test func inlineAndAppleScriptRoundTripNeverExecute() throws {
        let (root, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let marker = root.appendingPathComponent("must-not-exist")
        let action = ActionDefinition(id: "x", name: "Inline", type: .shell, shell: ShellConfig(scriptInline: "touch '\(marker.path)'"))
        let package = try PortableActionPackage.export(action: action, store: store)
        let imported = try package.install(into: store, manifest: ActionManifest())
        #expect(imported.actions.last?.shell?.scriptInline == action.shell?.scriptInline)
        #expect(!FileManager.default.fileExists(atPath: marker.path))
        let apple = ActionDefinition(id: "as", name: "Apple", type: .appleScript, appleScript: AppleScriptConfig(scriptInline: "return 1"))
        #expect(try PortableActionPackage.export(action: apple, store: store).install(into: store, manifest: imported).actions.last?.appleScript == apple.appleScript)
        let file = store.actionsDirectoryURL.appendingPathComponent("script.applescript")
        try Data("return 2".utf8).write(to: file)
        let fileApple = ActionDefinition(id: "as2", name: "Apple File", type: .appleScript, appleScript: AppleScriptConfig(scriptFile: file.path))
        let filePackage = try PortableActionPackage.export(action: fileApple, store: store)
        #expect(filePackage.scripts["script.applescript"] == Data("return 2".utf8))
    }

    @Test func malformedReferencesAndVersionsAreRejectedBeforeWrites() throws {
        let (root, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        for path in ["../outside.zsh", "/tmp/outside.zsh", "folder/code.zsh", "..\\code", "file:code"] {
            let action = ActionDefinition(id: "x", name: "X", type: .shell, shell: ShellConfig(scriptFile: path))
            let package = PortableActionPackage(action: action, scripts: [path: Data("echo no".utf8)])
            #expect(throws: Error.self) { try package.install(into: store, manifest: ActionManifest()) }
        }
        let action = ActionDefinition(id: "x", name: "X", type: .shell, shell: ShellConfig(scriptFile: "missing.zsh"))
        #expect(throws: Error.self) { try PortableActionPackage(action: action).validate() }
        #expect(throws: Error.self) { try PortableActionPackage(version: 2, action: action).validate() }
        #expect(try FileManager.default.contentsOfDirectory(atPath: store.actionsDirectoryURL.path).isEmpty)
    }

    @Test func rejectsSymlinksMissingSourcesOversizeAndMalformedJSON() throws {
        let (root, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let script = root.appendingPathComponent("source.zsh")
        try Data("echo hi".utf8).write(to: script)
        let link = root.appendingPathComponent("link.zsh")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: script)
        for path in [link.path, root.appendingPathComponent("missing").path] {
            let action = ActionDefinition(id: "x", name: "X", type: .shell, shell: ShellConfig(scriptFile: path))
            #expect(throws: Error.self) { try PortableActionPackage.export(action: action, store: store) }
        }
        let malformed = root.appendingPathComponent("bad.faaction")
        try Data("not JSON".utf8).write(to: malformed)
        #expect(throws: Error.self) { try PortableActionPackage.read(from: malformed) }
        let oversized = root.appendingPathComponent("large.faaction")
        try Data(repeating: 0, count: PortableActionPackage.maximumBytes + 1).write(to: oversized)
        #expect(throws: Error.self) { try PortableActionPackage.read(from: oversized) }
        let package = PortableActionPackage(action: ActionDefinition(id: "x", name: "X", type: .shell, shell: ShellConfig(scriptFile: "a.zsh")), scripts: ["a.zsh": Data(repeating: 0, count: PortableActionPackage.maximumScriptBytes + 1)])
        #expect(throws: Error.self) { try package.validate() }
    }

    @Test func manifestFailureRollsBackOnlyNewAssets() throws {
        let (root, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let sentinel = store.actionsDirectoryURL.appendingPathComponent("keep.zsh")
        try Data("keep".utf8).write(to: sentinel)
        // A directory at the manifest destination makes atomic file replacement fail.
        try FileManager.default.createDirectory(at: store.fileURL, withIntermediateDirectories: false)
        let action = ActionDefinition(id: "x", name: "X", type: .shell, shell: ShellConfig(scriptFile: "a.zsh"))
        let package = PortableActionPackage(action: action, scripts: ["a.zsh": Data("echo no".utf8)])
        #expect(throws: Error.self) { try package.install(into: store, manifest: ActionManifest()) }
        #expect(try FileManager.default.contentsOfDirectory(atPath: store.actionsDirectoryURL.path) == ["keep.zsh"])
        #expect(try String(contentsOf: sentinel, encoding: .utf8) == "keep")
    }
    @Test func incompleteActionsAndUndeclaredAssetsAreRejected() throws {
        let incomplete = ActionDefinition(id: "x", name: "X", type: .shell)
        #expect(throws: Error.self) { try PortableActionPackage(action: incomplete).validate() }
        let app = ActionDefinition(id: "a", name: "App", type: .application, application: ApplicationConfig(bundleId: "", pathFallback: "/Applications/App.app"))
        #expect(throws: Error.self) { try PortableActionPackage(action: app).validate() }
        let inline = ActionDefinition(id: "x", name: "X", type: .shell, shell: ShellConfig(scriptInline: "echo hi"))
        #expect(throws: Error.self) { try PortableActionPackage(action: inline, scripts: ["extra.zsh": Data("echo hidden".utf8)]).validate() }
    }

    @Test func symbolicLinkDestinationIsRejectedWithoutChangingData() throws {
        let (root, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let linkedActions = root.appendingPathComponent("LinkedActions")
        try FileManager.default.createSymbolicLink(at: linkedActions, withDestinationURL: store.actionsDirectoryURL)
        let linkedStore = ManifestStore(fileURL: store.fileURL, actionsDirectoryURL: linkedActions)
        let action = ActionDefinition(id: "x", name: "X", type: .shell, shell: ShellConfig(scriptInline: "echo hi"))
        #expect(throws: Error.self) { try PortableActionPackage(action: action).install(into: linkedStore, manifest: ActionManifest()) }
        #expect(!FileManager.default.fileExists(atPath: store.fileURL.path))
        #expect(try FileManager.default.contentsOfDirectory(atPath: store.actionsDirectoryURL.path).isEmpty)
    }

    @Test func applicationExportDropsMachineSpecificPath() throws {
        let (root, store) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let action = ActionDefinition(id: "app", name: "Application", type: .application, application: ApplicationConfig(bundleId: "com.example.Editor", pathFallback: "/private/other-machine/Editor.app"))
        let package = try PortableActionPackage.export(action: action, store: store)
        #expect(package.action.application?.bundleId == "com.example.Editor")
        #expect(package.action.application?.pathFallback == nil)
        let imported = try package.install(into: store, manifest: ActionManifest())
        #expect(imported.actions.last?.application == package.action.application)
    }

}
