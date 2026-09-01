import Foundation
import Testing
@testable import FinderActionsCore

@Suite("Open With actions")
struct OpenWithActionsTests {
    @Test func composesExactlyOneConfiguredTerminal() {
        var settings = OpenWithSettings.defaults
        settings.terminal = ExternalApplicationCatalog.terminals[1]

        let manifest = OpenWithActions.compose(
            baseManifest: DefaultActions.manifest(),
            settings: settings
        )
        let terminals = manifest.actions.filter { $0.type == .terminal }

        #expect(terminals.count == 1)
        #expect(terminals[0].id == OpenWithActions.terminalActionId)
        #expect(terminals[0].name == "Open in Terminal")
        #expect(terminals[0].subtitle == "iTerm2")
        #expect(terminals[0].terminal?.application.bundleId == "com.googlecode.iterm2")
        #expect(terminals[0].terminal?.launchMethod == .iTerm)
    }

    @Test func createsOneFinderActionPerSelectedEditor() {
        var settings = OpenWithSettings.defaults
        settings.editors = Array(ExternalApplicationCatalog.editors.prefix(3))

        let manifest = OpenWithActions.compose(
            baseManifest: DefaultActions.manifest(),
            settings: settings
        )
        let editorActions = manifest.actions.filter {
            $0.id.hasPrefix(OpenWithActions.editorActionPrefix)
        }

        #expect(editorActions.count == 3)
        #expect(editorActions.map(\.name) == [
            "Open in Visual Studio Code",
            "Open in Visual Studio Code Insiders",
            "Open in Cursor",
        ])
    }

    @Test func removesObsoleteBuiltInsButPreservesCustomActions() {
        let legacy = ActionManifest(version: 1, actions: [
            ActionDefinition(id: "open-terminal", name: "Open in Terminal", type: .terminal),
            ActionDefinition(id: "open-iterm", name: "Open in iTerm", type: .terminal),
            ActionDefinition(id: "open-vscode", name: "Open in VS Code", type: .application),
            ActionDefinition(id: "my-script", name: "My Script", type: .shell),
        ])

        let base = OpenWithActions.baseManifest(from: legacy)

        #expect(base.version == 2)
        #expect(base.actions.map(\.id) == ["my-script"])
    }

    @Test func settingsRoundTripIncludesCustomApplications() throws {
        let custom = ExternalApplication(
            id: "custom.dev.example.Editor",
            name: "Example Editor",
            bundleId: "dev.example.Editor",
            pathFallback: "/Applications/Example Editor.app",
            sfSymbol: "app",
            kind: .editor
        )
        let original = OpenWithSettings(
            terminal: ExternalApplicationCatalog.terminals[0],
            editors: [custom]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OpenWithSettings.self, from: data)

        #expect(decoded == original)
    }

    @Test func catalogIdentifiersAndBundleIdsAreUnique() {
        let applications = ExternalApplicationCatalog.terminals + ExternalApplicationCatalog.editors

        #expect(Set(applications.map(\.id)).count == applications.count)
        #expect(Set(applications.map(\.bundleId)).count == applications.count)
    }
}
