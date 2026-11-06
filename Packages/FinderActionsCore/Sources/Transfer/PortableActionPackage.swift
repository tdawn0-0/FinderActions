import Foundation

/// A single local JSON file. Script data is embedded; importing never runs it.
public struct PortableActionPackage: Codable, Sendable, Equatable {
    public static let maximumBytes = 2_000_000
    public static let maximumScriptBytes = 500_000
    public var version: Int
    public var action: ActionDefinition
    public var scripts: [String: Data]
    public var dependencies: String

    public init(version: Int = 1, action: ActionDefinition, scripts: [String: Data] = [:], dependencies: String = "") {
        self.version = version
        self.action = action
        self.scripts = scripts
        self.dependencies = dependencies
    }

    public enum Failure: Error, LocalizedError {
        case invalid(String)
        public var errorDescription: String? {
            switch self { case .invalid(let message): return message }
        }
    }

    public func validate() throws {
        guard version == 1 else { throw Failure.invalid("Unsupported action package version.") }
        guard ActionType.userAssignable.contains(action.type), !action.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Failure.invalid("The action type or name is invalid.")
        }
        if action.type == .application && (action.application?.bundleId ?? "").isEmpty {
            throw Failure.invalid("Portable application actions require a bundle identifier.")
        }
        if let message = ActionAuthoring.validationError(action) { throw Failure.invalid(message) }
        guard dependencies.utf8.count <= 16_000, scripts.count <= 2 else { throw Failure.invalid("Action package is too large.") }
        let references = [action.shell?.scriptFile, action.appleScript?.scriptFile].compactMap { $0 }.filter { !$0.isEmpty }
        for reference in references {
            guard Self.safeName(reference), scripts[reference] != nil else {
                throw Failure.invalid("The package has a missing or unsafe script reference.")
            }
        }
        guard Set(scripts.keys) == Set(references) else { throw Failure.invalid("The package contains unreferenced scripts.") }
        for (name, data) in scripts {
            guard Self.safeName(name), data.count <= Self.maximumScriptBytes,
                  String(data: data, encoding: .utf8) != nil else {
                throw Failure.invalid("Scripts must be bounded UTF-8 files with plain filenames.")
            }
        }
    }

    public func encoded() throws -> Data {
        try validate()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        guard data.count <= Self.maximumBytes else { throw Failure.invalid("Action package is too large.") }
        return data
    }

    public static func read(from url: URL) throws -> Self {
        try regularFile(url, limit: maximumBytes)
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        guard data.count <= maximumBytes else { throw Failure.invalid("Action package is too large.") }
        let package = try JSONDecoder().decode(Self.self, from: data)
        try package.validate()
        return package
    }

    /// File-based sources win over inline sources, exactly as in the executor.
    /// Source paths are replaced by embedded asset names so exports remain portable.
    public static func export(action: ActionDefinition, store: ManifestStore, dependencies: String = "") throws -> Self {
        var result = Self(action: action, dependencies: dependencies)
        if let reference = action.shell?.scriptFile, !reference.isEmpty {
            let name = "shell-script.zsh"
            result.scripts[name] = try scriptData(store.resolveScriptPath(reference))
            result.action.shell?.scriptFile = name
        }
        if let reference = action.appleScript?.scriptFile, !reference.isEmpty {
            let name = "script.applescript"
            result.scripts[name] = try scriptData(store.resolveScriptPath(reference))
            result.action.appleScript?.scriptFile = name
        }
        // The receiver resolves installed applications by ID, not the sender's path.
        result.action.application?.pathFallback = nil
        _ = try result.encoded()
        return result
    }

    /// Fresh IDs and a private asset directory prevent overwrites. If saving the
    /// manifest fails, the newly created asset directory is removed.
    public func install(into store: ManifestStore, manifest: ActionManifest) throws -> ActionManifest {
        try validate()
        _ = try encoded()
        let fm = FileManager.default
        try store.ensureDirectories()
        guard Self.canonicalParentAndLeaf(store.actionsDirectoryURL) == store.actionsDirectoryURL.resolvingSymlinksInPath().standardizedFileURL else {
            throw Failure.invalid("The scripts folder must not be a symbolic link.")
        }
        let assetFolderName = "import-\(UUID().uuidString.lowercased())"
        let assetFolder = store.actionsDirectoryURL.appendingPathComponent(assetFolderName, isDirectory: true)
        var result = manifest
        var imported = action
        imported.id = "user.action.\(UUID().uuidString.lowercased())"
        imported.enabled = false
        let lastIndex = manifest.actions.map(\.sortIndex).max() ?? 0
        imported.sortIndex = lastIndex <= Int.max - 10 ? lastIndex + 10 : lastIndex
        let names = Set(manifest.actions.map { $0.name.lowercased() })
        if names.contains(imported.name.lowercased()) {
            let base = imported.name
            var suffix = 2
            while names.contains("\(base) (\(suffix))".lowercased()) { suffix += 1 }
            imported.name = "\(base) (\(suffix))"
        }
        do {
            if !scripts.isEmpty {
                try fm.createDirectory(at: assetFolder, withIntermediateDirectories: false)
                for (name, data) in scripts {
                    try data.write(to: assetFolder.appendingPathComponent(name), options: .atomic)
                }
            }
            if let reference = imported.shell?.scriptFile, !reference.isEmpty {
                imported.shell?.scriptFile = "\(assetFolderName)/\(reference)"
            }
            if let reference = imported.appleScript?.scriptFile, !reference.isEmpty {
                imported.appleScript?.scriptFile = "\(assetFolderName)/\(reference)"
            }
            imported.application?.pathFallback = nil
            result.actions.append(imported)
            try store.save(result)
            return result
        } catch {
            if !scripts.isEmpty { try? fm.removeItem(at: assetFolder) }
            throw error
        }
    }

    public var scriptPreviews: [(name: String, source: String)] {
        var values = scripts.keys.sorted().map { ($0, String(data: scripts[$0]!, encoding: .utf8) ?? "") }
        if let source = action.shell?.scriptInline, !source.isEmpty { values.append(("Inline Shell", source)) }
        if let source = action.appleScript?.scriptInline, !source.isEmpty { values.append(("Inline AppleScript", source)) }
        return values
    }

    private static func safeName(_ name: String) -> Bool {
        !name.isEmpty && name != "." && name != ".." && name.utf8.count <= 255
            && !name.contains("/") && !name.contains("\\") && !name.contains("\0") && !name.contains(":")
    }

    private static func scriptData(_ url: URL) throws -> Data {
        try regularFile(url, limit: maximumScriptBytes)
        let data = try Data(contentsOf: url)
        guard data.count <= maximumScriptBytes else { throw Failure.invalid("Script is too large.") }
        return data
    }

    private static func canonicalParentAndLeaf(_ url: URL) -> URL {
        url.deletingLastPathComponent().resolvingSymlinksInPath().appendingPathComponent(url.lastPathComponent).standardizedFileURL
    }

    private static func regularFile(_ url: URL, limit: Int) throws {
        guard canonicalParentAndLeaf(url) == url.resolvingSymlinksInPath().standardizedFileURL else {
            throw Failure.invalid("Symbolic links are not supported for action packages or scripts.")
        }
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard attributes[.type] as? FileAttributeType == .typeRegular,
              let size = attributes[.size] as? NSNumber, size.intValue <= limit else {
            throw Failure.invalid("Expected a regular file within the package size limit.")
        }
    }
}
