import Foundation

/// Selection context used for `showWhen` and lightweight path rules.
public struct SelectionContext: Sendable, Equatable {
    public var paths: [String]
    /// Whether each path is a directory (same order as paths). Empty = unknown.
    public var isDirectory: [Bool]
    /// The Finder menu the selection was made in, when known.
    public var menuKind: MenuKind?

    public init(paths: [String], isDirectory: [Bool] = [], menuKind: MenuKind? = nil) {
        self.paths = paths
        self.isDirectory = isDirectory
        self.menuKind = menuKind
    }

    public var count: Int { paths.count }

    public var allFolders: Bool {
        guard !paths.isEmpty else { return true }
        if isDirectory.count == paths.count {
            return isDirectory.allSatisfy { $0 }
        }
        // Fallback: treat paths without extension as folders when isDirectory unknown is risky;
        // prefer explicit isDirectory from extension/host.
        return false
    }

    public var allFiles: Bool {
        guard !paths.isEmpty else { return false }
        if isDirectory.count == paths.count {
            return isDirectory.allSatisfy { !$0 }
        }
        return false
    }
}

public enum ShowWhenMatcher {
    /// Returns whether the action should appear for the given selection.
    public static func matches(showWhen: ShowWhen, context: SelectionContext) -> Bool {
        switch showWhen {
        case .always:
            return true
        case .filesOnly:
            // Empty selection (container blank) → not files-only
            guard context.count > 0 else { return false }
            if context.isDirectory.count == context.paths.count {
                return context.allFiles
            }
            // Without dir flags, allow (extension will refine with path heuristics)
            return true
        case .foldersOnly:
            guard context.count > 0 else { return true } // blank container is folder context
            if context.isDirectory.count == context.paths.count {
                return context.allFolders
            }
            return true
        case .single:
            return context.count == 1 || context.count == 0
        case .multiple:
            return context.count > 1
        }
    }

    /// Lightweight path-extension / folder filter (no file content reads).
    public static func matchesExtRules(_ rules: ExtRules?, context: SelectionContext) -> Bool {
        guard let rules else { return true }

        if rules.foldersOnly {
            if context.isDirectory.count == context.paths.count {
                if !context.allFolders { return false }
            }
        }
        if rules.filesOnly {
            if context.isDirectory.count == context.paths.count {
                if !context.allFiles { return false }
            }
        }

        let exts = rules.pathExtensions.map { $0.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")) }
        guard !exts.isEmpty else { return true }
        guard !context.paths.isEmpty else { return false }

        return context.paths.allSatisfy { path in
            let ext = (path as NSString).pathExtension.lowercased()
            return exts.contains(ext)
        }
    }

    /// Combined check used by Host (snapshot filtering) and Extension (runtime filter).
    public static func shouldShow(
        showWhen: ShowWhen,
        extRules: ExtRules?,
        allowedMenuKinds: [MenuKind]? = nil,
        context: SelectionContext
    ) -> Bool {
        if let allowedMenuKinds, !allowedMenuKinds.isEmpty {
            guard let menuKind = context.menuKind, allowedMenuKinds.contains(menuKind) else { return false }
            if !allowedMenuKinds.contains(.contextualMenuForContainer) && context.paths.isEmpty { return false }
        }
        return matches(showWhen: showWhen, context: context)
            && matchesExtRules(extRules, context: context)
    }
}
