import Foundation
import Testing
@testable import FinderActionsCore

@Suite("Published manifest example")
struct PublishedManifestTests {
    private func publishedAction() throws -> ActionDefinition {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("web/src/examples/compress-action.json"))
        return try JSONCoding.decode(ActionDefinition.self, from: data)
    }

    @Test func publishedActionDecodes() throws {
        let action = try publishedAction()
        #expect(action.id == "compress-archive")
        #expect(action.type == .shell)
        #expect(action.showWhen == .always)
        #expect(action.shell?.interpreter == "/bin/zsh")
        #expect(action.shell?.scriptFile == "compress.zsh")
    }

    @Test func publishedActionRoundTripsAndBuildsSnapshot() throws {
        let manifest = ActionManifest(actions: [try publishedAction()])
        let decoded = try JSONCoding.decode(ActionManifest.self, from: JSONCoding.encode(manifest))
        #expect(decoded == manifest)
        let snapshot = SnapshotBuilder.build(from: decoded)
        #expect(snapshot.items.count == 1)
        #expect(snapshot.items.first?.actionId == "compress-archive")
    }

    @Test func objectValuedShowWhenIsRejected() throws {
        let action = try publishedAction()
        let data = try JSONCoding.encode(action)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["showWhen"] = ["target": "filesAndFolders", "minSelection": 1] as [String: Any]
        let invalid = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) {
            try JSONCoding.decode(ActionDefinition.self, from: invalid)
        }
    }
}
