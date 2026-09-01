import Foundation

public enum ManifestError: Error, LocalizedError, Equatable {
    case fileNotFound(String)
    case decodeFailed(String)
    case encodeFailed
    case writeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let p): return "Manifest not found: \(p)"
        case .decodeFailed(let m): return "Manifest decode failed: \(m)"
        case .encodeFailed: return "Manifest encode failed"
        case .writeFailed(let m): return "Manifest write failed: \(m)"
        }
    }
}

/// Loads and saves `ActionManifest` JSON. Pure Foundation — no AppKit.
public struct ManifestStore: Sendable {
    public var fileURL: URL
    public var actionsDirectoryURL: URL

    public init(fileURL: URL, actionsDirectoryURL: URL) {
        self.fileURL = fileURL
        self.actionsDirectoryURL = actionsDirectoryURL
    }

    /// Standard Application Support layout for the given app name.
    public static func applicationSupportLayout(appName: String = "FinderActions") -> (root: URL, manifest: URL, actions: URL) {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent(appName, isDirectory: true)
        let manifest = root.appendingPathComponent("manifest.json")
        let actions = root.appendingPathComponent("Actions", isDirectory: true)
        return (root, manifest, actions)
    }

    public static func makeDefault(appName: String = "FinderActions") -> ManifestStore {
        let layout = applicationSupportLayout(appName: appName)
        return ManifestStore(fileURL: layout.manifest, actionsDirectoryURL: layout.actions)
    }

    public func ensureDirectories() throws {
        let fm = FileManager.default
        let root = fileURL.deletingLastPathComponent()
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        try fm.createDirectory(at: actionsDirectoryURL, withIntermediateDirectories: true)
    }

    public func load() throws -> ActionManifest {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw ManifestError.fileNotFound(fileURL.path)
        }
        let data = try Data(contentsOf: fileURL)
        do {
            return try JSONDecoder().decode(ActionManifest.self, from: data)
        } catch {
            throw ManifestError.decodeFailed(error.localizedDescription)
        }
    }

    public func loadOrEmpty() -> ActionManifest {
        (try? load()) ?? ActionManifest()
    }

    public func save(_ manifest: ActionManifest) throws {
        try ensureDirectories()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(manifest) else {
            throw ManifestError.encodeFailed
        }
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw ManifestError.writeFailed(error.localizedDescription)
        }
    }

    /// Resolve a shell script path relative to Actions directory.
    public func resolveScriptPath(_ scriptFile: String) -> URL {
        if scriptFile.hasPrefix("/") {
            return URL(fileURLWithPath: scriptFile)
        }
        return actionsDirectoryURL.appendingPathComponent(scriptFile)
    }
}

// MARK: - JSON helpers used by IPC

public enum JSONCoding {
    public static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    public static let prettyEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    public static let decoder = JSONDecoder()

    public static func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }

    public static func encodeToString<T: Encodable>(_ value: T) throws -> String {
        let data = try encode(value)
        guard let s = String(data: data, encoding: .utf8) else {
            throw ManifestError.encodeFailed
        }
        return s
    }

    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }

    public static func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
        guard let data = string.data(using: .utf8) else {
            throw ManifestError.decodeFailed("invalid utf8")
        }
        return try decode(type, from: data)
    }
}
