import Foundation

// MARK: - Built-in identifiers

public enum CutBuiltinID: String, Sendable, Equatable, CaseIterable {
    case cut = "cut-add"
    case moveHere = "cut-move-here"
    case clear = "cut-clear"
}

public struct CutMenuLabels: Sendable, Equatable {
    public var cutTitle: String
    public var moveHereTitle: String
    public var clearTitle: String

    public init(cutTitle: String = "Cut", moveHereTitle: String = "Move Here", clearTitle: String = "Clear Cut") {
        self.cutTitle = cutTitle
        self.moveHereTitle = moveHereTitle
        self.clearTitle = clearTitle
    }
}

// MARK: - Generated actions

/// Generated, never persisted: Cut actions are composed at runtime from the
/// feature toggle and the current cut queue, like Open With actions.
public enum CutActions {
    public static let actionIdPrefix = "builtin.cut"
    public static let cutActionId = "builtin.cut"
    public static let moveHereActionId = "builtin.cut-move-here"
    public static let clearActionId = "builtin.cut-clear"

    public static func isCutAction(_ actionId: String) -> Bool {
        actionId.hasPrefix(actionIdPrefix)
    }

    public static func stripGenerated(from manifest: ActionManifest) -> ActionManifest {
        var result = manifest
        result.actions.removeAll { isCutAction($0.id) }
        return result
    }

    public static func compose(
        baseManifest: ActionManifest,
        enabled: Bool,
        cutCount: Int,
        labels: CutMenuLabels = CutMenuLabels()
    ) -> ActionManifest {
        var result = stripGenerated(from: baseManifest)
        guard enabled else { return result }

        result.actions.append(ActionDefinition(
            id: cutActionId,
            name: labels.cutTitle,
            type: .builtin,
            enabled: true,
            sortIndex: 1,
            icon: ActionIcon(sfSymbol: "scissors"),
            showWhen: .always,
            builtinId: CutBuiltinID.cut.rawValue,
            allowedMenuKinds: [.contextualMenuForItems]
        ))
        if cutCount > 0 {
            result.actions.append(ActionDefinition(
                id: moveHereActionId,
                name: labels.moveHereTitle,
                type: .builtin,
                enabled: true,
                sortIndex: 2,
                icon: ActionIcon(sfSymbol: "arrow.down.doc"),
                showWhen: .single,
                extRules: ExtRules(foldersOnly: true),
                builtinId: CutBuiltinID.moveHere.rawValue,
                allowedMenuKinds: [.contextualMenuForContainer, .contextualMenuForItems]
            ))
            result.actions.append(ActionDefinition(
                id: clearActionId,
                name: labels.clearTitle,
                type: .builtin,
                enabled: true,
                sortIndex: 3,
                icon: ActionIcon(sfSymbol: "xmark.circle"),
                showWhen: .always,
                builtinId: CutBuiltinID.clear.rawValue,
                allowedMenuKinds: [.contextualMenuForContainer, .contextualMenuForItems]
            ))
        }
        return result
    }
}

// MARK: - Cut queue

public final class CutBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []

    public init() {}

    public var items: [String] {
        lock.lock(); defer { lock.unlock() }
        return storage
    }

    public var count: Int {
        lock.lock(); defer { lock.unlock() }
        return storage.count
    }

    public var isEmpty: Bool { count == 0 }

    /// Replaces the queue. Paths are standardized (symlinks preserved), de-duplicated,
    /// and any path nested inside another queued path is dropped.
    @discardableResult
    public func set(_ rawPaths: [String]) -> [String] {
        var seen = Set<String>()
        var unique: [String] = []
        for raw in rawPaths {
            let path = URL(fileURLWithPath: raw).standardizedFileURL.path
            if seen.insert(path).inserted { unique.append(path) }
        }
        let pruned = unique.filter { path in
            !unique.contains { other in other != path && path.hasPrefix(other == "/" ? "/" : other + "/") }
        }
        lock.lock()
        storage = pruned
        lock.unlock()
        return pruned
    }

    @discardableResult
    public func clear() -> Int {
        lock.lock(); defer { lock.unlock() }
        let previous = storage.count
        storage.removeAll()
        return previous
    }

    public func remove(_ completedPaths: Set<String>) {
        lock.lock(); defer { lock.unlock() }
        storage.removeAll { completedPaths.contains($0) }
    }
}

// MARK: - Mover

public struct CutMoveFailure: Sendable, Equatable {
    public var path: String
    public var reason: String

    public init(path: String, reason: String) {
        self.path = path
        self.reason = reason
    }
}

public struct CutMoveResult: Sendable, Equatable {
    public var movedPaths: [String] = []
    public var alreadyInDestinationPaths: [String] = []
    public var conflictPaths: [String] = []
    public var missingPaths: [String] = []
    public var invalidDestinationPaths: [String] = []
    public var failedItems: [CutMoveFailure] = []
    /// Items that stay in the cut queue.
    public var remainingPaths: [String] = []

    public init() {}

    /// Items that no longer belong in the cut queue.
    public var completedPaths: Set<String> {
        Set(movedPaths + alreadyInDestinationPaths + missingPaths)
    }

    public var isSuccess: Bool {
        conflictPaths.isEmpty && missingPaths.isEmpty && invalidDestinationPaths.isEmpty && failedItems.isEmpty
    }
}

public enum CutFileMover {
    /// Moves each source into `destinationDirectory`. Never overwrites or renames:
    /// name conflicts are skipped and stay in the queue.
    public static func move(
        sources: [String],
        toDirectory destinationDirectory: String,
        fileManager: FileManager = .default
    ) -> CutMoveResult {
        var result = CutMoveResult()

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: destinationDirectory, isDirectory: &isDirectory), isDirectory.boolValue else {
            for source in sources {
                result.failedItems.append(CutMoveFailure(path: source, reason: "Destination is not a folder"))
                result.remainingPaths.append(source)
            }
            return result
        }

        let destURL = URL(fileURLWithPath: destinationDirectory).standardizedFileURL
        let destCanonical = destURL.resolvingSymlinksInPath().standardizedFileURL

        for sourcePath in sources {
            guard let attributes = try? fileManager.attributesOfItem(atPath: sourcePath) else {
                result.missingPaths.append(sourcePath)
                continue
            }
            // Never resolve the leaf: a symlink must be moved itself, not its target.
            let sourceURL = URL(fileURLWithPath: sourcePath).standardizedFileURL
            let parentCanonical = sourceURL.deletingLastPathComponent().resolvingSymlinksInPath().standardizedFileURL
            if parentCanonical == destCanonical {
                result.alreadyInDestinationPaths.append(sourcePath)
                continue
            }
            if (attributes[.type] as? FileAttributeType) == .typeDirectory {
                let sourceCanonical = sourceURL.resolvingSymlinksInPath().standardizedFileURL
                if destCanonical == sourceCanonical
                    || sourceCanonical.path == "/"
                    || destCanonical.path.hasPrefix(sourceCanonical.path + "/") {
                    result.invalidDestinationPaths.append(sourcePath)
                    result.remainingPaths.append(sourcePath)
                    continue
                }
            }
            let targetURL = destURL.appendingPathComponent(sourceURL.lastPathComponent)
            if (try? fileManager.attributesOfItem(atPath: targetURL.path)) != nil {
                result.conflictPaths.append(sourcePath)
                result.remainingPaths.append(sourcePath)
                continue
            }
            do {
                try fileManager.moveItem(at: sourceURL, to: targetURL)
                result.movedPaths.append(sourcePath)
            } catch {
                result.failedItems.append(CutMoveFailure(path: sourcePath, reason: error.localizedDescription))
                result.remainingPaths.append(sourcePath)
            }
        }
        return result
    }
}
