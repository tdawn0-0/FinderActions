import Foundation
import Testing
@testable import FinderActionsCore

@Suite("Execute request validation")
struct ExecuteRequestValidationTests {
    private let files = ["/d": true, "/d/a.txt": false, "/d/b.png": false]
    private let manifest = ActionManifest(actions: [
        ActionDefinition(id: "always", name: "Always", type: .shell),
        ActionDefinition(id: "files", name: "Files", type: .shell, showWhen: .filesOnly),
        ActionDefinition(id: "png", name: "PNG", type: .shell, extRules: ExtRules(pathExtensions: ["png"])),
        ActionDefinition(id: "off", name: "Off", type: .shell, enabled: false),
    ])

    private func validate(_ request: ExecuteRequest) -> Result<ActionDefinition, ExecuteRejection> {
        ExecuteRequestValidator.validate(request, manifest: manifest, fileInfo: { files[$0] })
    }

    @Test func acceptsGenuineClick() {
        #expect(validate(ExecuteRequest(actionId: "always", paths: ["/d/a.txt"], containerPath: "/d")) == .success(manifest.actions[0]))
    }

    @Test func unsupportedVersionRejectsBeforeFilesystemAccess() {
        let request = ExecuteRequest(v: 2, actionId: "always", paths: ["relative"])
        let result = ExecuteRequestValidator.validate(request, manifest: manifest, fileInfo: { _ in
            Issue.record("Unsupported version must not inspect the filesystem")
            return nil
        })
        #expect(result == .failure(.unsupportedVersion(2)))
    }

    @Test(arguments: ["a.txt", "-option", ""])
    func rejectsNonAbsoluteSelection(path: String) {
        #expect(validate(ExecuteRequest(actionId: "always", paths: [path])) == .failure(.pathNotAbsolute(path)))
    }

    @Test func rejectsMissingPath() {
        #expect(validate(ExecuteRequest(actionId: "always", paths: ["/d/nope"])) == .failure(.pathMissing("/d/nope")))
    }

    @Test func rejectsMissingContainer() {
        #expect(validate(ExecuteRequest(actionId: "always", paths: ["/d/a.txt"], containerPath: "/missing")) == .failure(.pathMissing("/missing")))
    }

    @Test func rejectsRelativeContainer() {
        #expect(validate(ExecuteRequest(actionId: "always", paths: ["/d/a.txt"], containerPath: "d")) == .failure(.pathNotAbsolute("d")))
    }

    @Test(arguments: [nil, ""] as [String?])
    func acceptsAbsentOrEmptyContainer(container: String?) {
        #expect(validate(ExecuteRequest(actionId: "always", paths: ["/d/a.txt"], containerPath: container)) == .success(manifest.actions[0]))
    }

    @Test func rejectsUnknownAndDisabledActions() {
        #expect(validate(ExecuteRequest(actionId: "missing", paths: ["/d/a.txt"])) == .failure(.unknownAction("missing")))
        #expect(validate(ExecuteRequest(actionId: "off", paths: ["/d/a.txt"])) == .failure(.actionDisabled("off")))
    }

    @Test func enforcesFileFilter() {
        #expect(validate(ExecuteRequest(actionId: "files", paths: ["/d"])) == .failure(.selectionNotAllowed("files")))
        #expect(validate(ExecuteRequest(actionId: "files", paths: ["/d/a.txt"])) == .success(manifest.actions[1]))
    }

    @Test func enforcesExtensionFilter() {
        #expect(validate(ExecuteRequest(actionId: "png", paths: ["/d/a.txt"])) == .failure(.selectionNotAllowed("png")))
        #expect(validate(ExecuteRequest(actionId: "png", paths: ["/d/b.png"])) == .success(manifest.actions[2]))
    }

    @Test func acceptsContainerClick() {
        #expect(validate(ExecuteRequest(actionId: "always", paths: ["/d"], containerPath: "/d")) == .success(manifest.actions[0]))
    }

    @Test func boundsPathCountBeforeFilesystemAccess() {
        let request = ExecuteRequest(actionId: "always", paths: Array(repeating: "/d/a.txt", count: ExecuteRequestValidator.maxPaths + 1))
        let result = ExecuteRequestValidator.validate(request, manifest: manifest, fileInfo: { _ in
            Issue.record("Oversized selection must not inspect the filesystem")
            return nil
        })
        #expect(result == .failure(.tooManyPaths(ExecuteRequestValidator.maxPaths + 1)))
        #expect(validate(ExecuteRequest(actionId: "always", paths: Array(repeating: "/d/a.txt", count: ExecuteRequestValidator.maxPaths))) == .success(manifest.actions[0]))
    }

    @Test func backgroundVisibilityRemainsValidForContainerRequest() {
        let empty = SelectionContext(paths: [], isDirectory: [])
        // Cover every flag combination, both absent rules and extension filtering.
        var rules: [ExtRules?] = [nil]
        for extensions in [[], ["png"], [".PNG", "txt"]] {
            for foldersOnly in [false, true] {
                for filesOnly in [false, true] {
                    rules.append(ExtRules(pathExtensions: extensions, foldersOnly: foldersOnly, filesOnly: filesOnly))
                }
            }
        }
        for showWhen in ShowWhen.allCases {
            for rule in rules where ShowWhenMatcher.shouldShow(showWhen: showWhen, extRules: rule, context: empty) {
                let action = ActionDefinition(id: "background", name: "Background", type: .shell, showWhen: showWhen, extRules: rule)
                let result = ExecuteRequestValidator.validate(
                    ExecuteRequest(actionId: action.id, paths: ["/d"], containerPath: "/d"),
                    manifest: ActionManifest(actions: [action]), fileInfo: { files[$0] }
                )
                #expect(result == .success(action))
            }
        }
    }

    @Test func rejectionSummariesDoNotExposePayloadValues() {
        let privateValue = "/private/selection-value"
        let rejections: [ExecuteRejection] = [
            .unsupportedVersion(42), .tooManyPaths(12345), .pathNotAbsolute(privateValue),
            .pathMissing(privateValue), .unknownAction(privateValue), .actionDisabled(privateValue),
            .selectionNotAllowed(privateValue),
        ]
        for rejection in rejections {
            #expect(rejection.summary.hasPrefix("Rejected request:"))
            #expect(!rejection.summary.contains(privateValue))
        }
    }
}
