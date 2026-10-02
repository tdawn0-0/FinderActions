import Foundation

public enum OutputTail {
    /// Characters of stderr kept per log entry.
    public static let logLimit = 4_000

    /// Trimmed last `limit` characters of `text`, or nil when empty/whitespace.
    /// Prefixed with "…" when truncated.
    public static func tail(_ text: String, limit: Int = logLimit) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.count > limit else { return trimmed }
        return "…" + String(trimmed.suffix(limit))
    }
}
