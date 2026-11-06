import Foundation

/// Application budgets, not claims about the operating system's notification limit.
public enum SnapshotTransport {
    public static let partBytes = 40_000
    public static let maxParts = 128
    public static let maxMessageBytes = partBytes * maxParts
    public static let maxBatches = 4
    public static let maxBufferedBytes = 8 * 1024 * 1024
    public static let idleSeconds: TimeInterval = 30

    /// Scalar boundaries keep each piece valid UTF-8 even for huge grapheme clusters.
    public static func chunks(_ text: String) -> [String]? {
        guard text.utf8.count <= maxMessageBytes else { return nil }
        var parts: [String] = [], current = "", bytes = 0
        for scalar in text.unicodeScalars {
            let count = scalar.utf8.count
            if bytes + count > partBytes { parts.append(current); current = ""; bytes = 0 }
            current.unicodeScalars.append(scalar)
            bytes += count
        }
        if !current.isEmpty || parts.isEmpty { parts.append(current) }
        guard parts.count <= maxParts else { return nil }
        return parts
    }
}

/// Caller serializes access. Monotonic time is supplied by the caller for deterministic tests.
public struct SnapshotAssembler: Sendable {
    private struct Batch: Sendable {
        var total: Int
        var parts: [Int: String] = [:]
        var bytes = 0
        var touched: TimeInterval
    }
    private var batches: [String: Batch] = [:]
    public init() {}
    public var batchCount: Int { batches.count }
    public var nextExpiration: TimeInterval? { batches.values.map { $0.touched + SnapshotTransport.idleSeconds }.min() }
    public var bufferedBytes: Int { batches.values.reduce(0) { $0 + $1.bytes } }
    public mutating func expire(now: TimeInterval) {
        batches = batches.filter { now - $0.value.touched < SnapshotTransport.idleSeconds }
    }
    public mutating func accept(body: String, batchID: String, index: Int, total: Int, now: TimeInterval) -> String? {
        expire(now: now)
        guard batchID.utf8.count <= 128, total > 1, total <= SnapshotTransport.maxParts, index >= 0, index < total,
              body.utf8.count <= SnapshotTransport.partBytes else {
            batches[batchID] = nil; return nil
        }
        if let existing = batches[batchID] {
            guard existing.total == total else { batches[batchID] = nil; return nil }
            if let prior = existing.parts[index] {
                if prior != body { batches[batchID] = nil }
                return nil
            }
        } else {
            while batches.count >= SnapshotTransport.maxBatches { evictOldest() }
        }
        var batch = batches.removeValue(forKey: batchID) ?? Batch(total: total, touched: now)
        let bytes = body.utf8.count
        guard batch.bytes + bytes <= SnapshotTransport.maxMessageBytes else { return nil }
        while bufferedBytes + batch.bytes + bytes > SnapshotTransport.maxBufferedBytes, !batches.isEmpty { evictOldest() }
        guard bufferedBytes + batch.bytes + bytes <= SnapshotTransport.maxBufferedBytes else { return nil }
        batch.parts[index] = body; batch.bytes += bytes; batch.touched = now
        if batch.parts.count == total { return (0..<total).map { batch.parts[$0]! }.joined() }
        batches[batchID] = batch
        return nil
    }
    private mutating func evictOldest() {
        if let key = batches.min(by: { $0.value.touched < $1.value.touched })?.key { batches[key] = nil }
    }
}
