import Foundation

/// Local-only execution log shared by Host execution and Settings inspection.
public final class ExecLogStore: @unchecked Sendable {
    public let fileURL: URL
    public let maxEntries: Int
    private let queue = DispatchQueue(label: "com.finderactions.log")

    public init(directory: URL, maxEntries: Int = 200) {
        self.fileURL = directory.appendingPathComponent("exec.jsonl")
        self.maxEntries = maxEntries
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public func append(_ entry: ExecLogEntry) {
        queue.sync {
            var entries = loadAllUnlocked()
            entries.append(entry)
            if entries.count > maxEntries {
                entries = Array(entries.suffix(maxEntries))
            }
            saveAllUnlocked(entries)
        }
    }

    public func recent(limit: Int = 200) -> [ExecLogEntry] {
        queue.sync {
            Array(loadAllUnlocked().suffix(limit).reversed())
        }
    }

    public func clear() {
        queue.sync {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private func loadAllUnlocked() -> [ExecLogEntry] {
        guard let data = try? Data(contentsOf: fileURL),
              let text = String(data: data, encoding: .utf8) else {
            return []
        }
        let decoder = JSONDecoder()
        return text.split(separator: "\n", omittingEmptySubsequences: true).compactMap { line in
            guard let d = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(ExecLogEntry.self, from: d)
        }
    }

    private func saveAllUnlocked(_ entries: [ExecLogEntry]) {
        let encoder = JSONEncoder()
        var lines: [String] = []
        for e in entries {
            if let data = try? encoder.encode(e), let s = String(data: data, encoding: .utf8) {
                lines.append(s)
            }
        }
        try? lines.joined(separator: "\n").write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
