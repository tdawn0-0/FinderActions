import Foundation

/// Pure policy for how the extension delivers an execute request to Host.
public enum ExecuteDeliveryPlan: String, Sendable, Equatable {
    /// Host is already running — post execute exactly once (no delayed retry).
    case once
    /// Host is down — launch Host, then retry the same payload once after warm-up.
    case launchAndRetry
}

public enum ExecuteDelivery {
    /// Decide delivery strategy from live Host process presence.
    /// Never schedules an unconditional delayed re-post when Host is already up
    /// (that caused every menu click to run twice).
    public static func plan(hostRunning: Bool) -> ExecuteDeliveryPlan {
        hostRunning ? .once : .launchAndRetry
    }

    /// How many times the extension should post the execute notification for a plan.
    /// `.once` → 1; `.launchAndRetry` → 2 (initial + one retry after launch).
    public static func postCount(for plan: ExecuteDeliveryPlan) -> Int {
        switch plan {
        case .once: return 1
        case .launchAndRetry: return 2
        }
    }
}

/// Whether Finder menu should show real actions vs host-offline degradation.
public enum MenuAvailability {
    /// Use **live** Host process state, not the cached snapshot's `hostRunning` flag
    /// (that flag is always true in last publish and goes stale when Host quits).
    public static func shouldShowActionMenu(
        hostProcessRunning: Bool,
        snapshot: MenuSnapshot?
    ) -> Bool {
        guard hostProcessRunning else { return false }
        guard let snapshot, !snapshot.items.isEmpty else { return false }
        return true
    }
}

/// Host-side windowed dedupe of execute `requestId`s (guards against retry storms).
public final class RequestIdDedupe: @unchecked Sendable {
    private var seen: [String: Date] = [:]
    private let window: TimeInterval
    private let lock = NSLock()

    public init(windowSeconds: TimeInterval = 5) {
        self.window = windowSeconds
    }

    /// Returns `true` if this is the first time we've seen `id` within the window
    /// (caller should execute). Returns `false` if it is a duplicate (skip).
    @discardableResult
    public func accept(_ id: String, now: Date = Date()) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        prune(now: now)
        if let previous = seen[id], now.timeIntervalSince(previous) < window {
            return false
        }
        seen[id] = now
        return true
    }

    public func reset() {
        lock.lock()
        seen.removeAll()
        lock.unlock()
    }

    private func prune(now: Date) {
        seen = seen.filter { now.timeIntervalSince($0.value) < window }
    }
}
