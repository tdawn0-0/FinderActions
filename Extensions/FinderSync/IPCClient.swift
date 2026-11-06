import Foundation
import AppKit
import FinderActionsCore

/// Snapshot notification fields extracted as Sendable values (Swift 6 safe).
private struct SnapshotNotePayload: Sendable {
    var body: String?
    var batchId: String?
    var index: Int?
    var total: Int?

    init(_ note: Notification) {
        body = (note.object as? String) ?? (note.userInfo?["json"] as? String)
        batchId = note.userInfo?["batchId"] as? String
        index = note.userInfo?["index"] as? Int
        total = note.userInfo?["total"] as? Int
    }
}

/// Extension-side IPC. `@unchecked Sendable` because FIFinderSync calls in from arbitrary queues;
/// state is guarded by `lock`.
final class IPCClient: @unchecked Sendable {
    var onSnapshot: ((MenuSnapshot) -> Void)?
    private var snapshotObserver: NSObjectProtocol?
    private var assembler = SnapshotAssembler()
    private var cleanup: DispatchWorkItem?
    private let cacheURL: URL
    private let lock = NSLock()

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("FinderActions", isDirectory: true)
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        cacheURL = support.appendingPathComponent(IPCConstants.snapshotFileName)
    }

    func start() {
        let center = DistributedNotificationCenter.default()
        snapshotObserver = center.addObserver(
            forName: Notification.Name(IPCConstants.snapshotNotification),
            object: nil,
            queue: nil
        ) { [weak self] note in
            let payload = SnapshotNotePayload(note)
            self?.handleSnapshotPayload(payload)
        }
        center.postNotificationName(
            Notification.Name(IPCConstants.snapshotRequestNotification),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    deinit {
        cleanup?.cancel()
        if let snapshotObserver {
            DistributedNotificationCenter.default().removeObserver(snapshotObserver)
        }
    }

    /// Last live snapshot, cached in this sandboxed extension's own container.
    func loadCachedSnapshot() -> MenuSnapshot? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONCoding.decode(MenuSnapshot.self, from: data)
    }

    func isHostRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == IPCConstants.hostBundleId
        }
    }

    /// Post once when Host is up; when down, launch + one retry. Never unconditional double-post.
    func sendExecute(_ request: ExecuteRequest) {
        guard let json = try? JSONCoding.encodeToString(request) else { return }
        let plan = ExecuteDelivery.plan(hostRunning: isHostRunning())

        switch plan {
        case .once:
            Self.postExecute(json)
        case .launchAndRetry:
            Self.postExecute(json)
            launchHost()
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                Self.postExecute(json)
            }
        }
    }

    func launchHost() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: IPCConstants.hostBundleId) {
            let conf = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: url, configuration: conf, completionHandler: nil)
            return
        }
        let hostURL = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        if FileManager.default.fileExists(atPath: hostURL.path) {
            NSWorkspace.shared.open(hostURL)
        }
    }

    private static func postExecute(_ json: String) {
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(IPCConstants.executeNotification),
            object: json,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    private func handleSnapshotPayload(_ payload: SnapshotNotePayload) {
        guard let body = payload.body else { return }

        lock.lock()
        defer { lock.unlock() }

        if let total = payload.total, let index = payload.index, let batchId = payload.batchId {
            if let merged = assembler.accept(body: body, batchID: batchId, index: index,
                                              total: total, now: ProcessInfo.processInfo.systemUptime) {
                applySnapshotJSONUnlocked(merged)
            }
            scheduleCleanupUnlocked()
            return
        }
        // A partial envelope is malformed, never reinterpret it as a complete message.
        guard payload.total == nil, payload.index == nil, payload.batchId == nil,
              body.utf8.count <= SnapshotTransport.partBytes else { return }
        applySnapshotJSONUnlocked(body)
    }

    private func scheduleCleanupUnlocked() {
        guard assembler.batchCount > 0 else { cleanup?.cancel(); cleanup = nil; return }
        guard cleanup == nil else { return }
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.lock.lock()
            defer { self.lock.unlock() }
            self.cleanup = nil
            self.assembler.expire(now: ProcessInfo.processInfo.systemUptime)
            self.scheduleCleanupUnlocked()
        }
        cleanup = item
        let delay = max(0.001, (assembler.nextExpiration ?? ProcessInfo.processInfo.systemUptime) - ProcessInfo.processInfo.systemUptime)
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func applySnapshotJSONUnlocked(_ json: String) {
        guard let snap = try? JSONCoding.decode(MenuSnapshot.self, from: json) else { return }
        try? json.write(to: cacheURL, atomically: true, encoding: .utf8)
        onSnapshot?(snap)
    }
}
