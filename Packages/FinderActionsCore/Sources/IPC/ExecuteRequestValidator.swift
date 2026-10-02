import Foundation

public enum ExecuteRejection: Error, Equatable, Sendable {
    case unsupportedVersion(Int)
    case tooManyPaths(Int)
    case pathNotAbsolute(String)
    case pathMissing(String)
    case unknownAction(String)
    case actionDisabled(String)
    case selectionNotAllowed(String)

    public var summary: String {
        switch self {
        case .unsupportedVersion: "Rejected request: unsupported version"
        case .tooManyPaths: "Rejected request: too many paths"
        case .pathNotAbsolute: "Rejected request: path is not absolute"
        case .pathMissing: "Rejected request: path does not exist"
        case .unknownAction: "Rejected request: unknown action"
        case .actionDisabled: "Rejected request: action is disabled"
        case .selectionNotAllowed: "Rejected request: selection is not allowed"
        }
    }
}

/// Checks whether a request could have come from a real Finder click.
/// Distributed notifications do not authenticate the sender, so the Host must
/// check the selection against the action's filters before executing it.
public enum ExecuteRequestValidator {
    public static let maxPaths = 10_000

    /// `fileInfo` returns nil for missing paths, otherwise whether they are directories.
    public static func validate(
        _ request: ExecuteRequest,
        manifest: ActionManifest,
        fileInfo: (String) -> Bool? = ExecuteRequestValidator.diskFileInfo
    ) -> Result<ActionDefinition, ExecuteRejection> {
        guard request.v == 1 else { return .failure(.unsupportedVersion(request.v)) }
        guard request.paths.count <= maxPaths else { return .failure(.tooManyPaths(request.paths.count)) }

        var pathsToCheck = request.paths
        if let container = request.containerPath, !container.isEmpty {
            pathsToCheck.append(container)
        }
        for path in pathsToCheck {
            guard path.hasPrefix("/") else { return .failure(.pathNotAbsolute(path)) }
            guard fileInfo(path) != nil else { return .failure(.pathMissing(path)) }
        }

        guard let action = manifest.actions.first(where: { $0.id == request.actionId }) else {
            return .failure(.unknownAction(request.actionId))
        }
        guard action.enabled else { return .failure(.actionDisabled(action.id)) }
        let context = SelectionContext(
            paths: request.paths,
            isDirectory: request.paths.map { fileInfo($0) ?? false }
        )
        guard ShowWhenMatcher.shouldShow(showWhen: action.showWhen, extRules: action.extRules, context: context) else {
            return .failure(.selectionNotAllowed(action.id))
        }
        return .success(action)
    }

    public static func diskFileInfo(_ path: String) -> Bool? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { return nil }
        return isDirectory.boolValue
    }
}
