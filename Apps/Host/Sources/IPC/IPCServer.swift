import Foundation
import UserNotifications
import FinderActionsCore

/// Host IPC: receives execute requests from the extension; coordinates snapshot publish.
@MainActor
final class IPCServer {
    private let appState: AppState
    var onSnapshotNeeded: (() -> Void)?
    private nonisolated(unsafe) var executeObserver: NSObjectProtocol?
    private nonisolated(unsafe) var snapshotRequestObserver: NSObjectProtocol?
    /// Ignore duplicate requestIds (e.g. launch-and-retry posts both landing).
    private let requestDedupe = RequestIdDedupe(windowSeconds: 5)

    init(appState: AppState) {
        self.appState = appState
    }

    func start() {
        let center = DistributedNotificationCenter.default()
        executeObserver = center.addObserver(
            forName: Notification.Name(IPCConstants.executeNotification),
            object: nil,
            queue: nil
        ) { [weak self] note in
            let json = (note.object as? String) ?? (note.userInfo?["json"] as? String)
            Task { @MainActor in
                guard let self, let json else { return }
                self.processJSON(json)
            }
        }
        snapshotRequestObserver = center.addObserver(
            forName: Notification.Name(IPCConstants.snapshotRequestNotification),
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in
                self?.onSnapshotNeeded?()
            }
        }
    }

    deinit {
        if let executeObserver {
            DistributedNotificationCenter.default().removeObserver(executeObserver)
        }
        if let snapshotRequestObserver {
            DistributedNotificationCenter.default().removeObserver(snapshotRequestObserver)
        }
    }

    private func processJSON(_ json: String) {
        do {
            let request = try JSONCoding.decode(ExecuteRequest.self, from: json)
            guard requestDedupe.accept(request.requestId) else { return }
            let result = appState.executor.execute(request: request, manifest: appState.effectiveManifest)
            let entry = ExecLogEntry(
                actionId: request.actionId,
                success: result.success,
                summary: result.summary,
                paths: request.paths
            )
            appState.recordLog(entry)
            notify(result: result, actionId: request.actionId)
        } catch {
            let entry = ExecLogEntry(
                actionId: "?",
                success: false,
                summary: "Bad execute payload: \(error.localizedDescription)",
                paths: []
            )
            appState.recordLog(entry)
        }
    }

    private func notify(result: ExecResult, actionId: String) {
        guard appState.notificationsEnabled else { return }
        let title = result.success ? "FinderActions" : "FinderActions failed"
        let body = "\(actionId): \(result.summary)"
        let playFailureSound = !result.success

        Task {
            let center = UNUserNotificationCenter.current()
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = playFailureSound ? .default : nil
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            try? await center.add(request)
        }
    }
}

enum SnapshotPublisher {
    /// Publish menu snapshot via DistributedNotification (chunk if needed) + Application Support file.
    static func publish(_ snapshot: MenuSnapshot) {
        guard let json = try? JSONCoding.encodeToString(snapshot) else { return }

        writeFallback(json: json)

        let center = DistributedNotificationCenter.default()
        let maxChunk = 40_000
        if json.utf8.count <= maxChunk {
            center.postNotificationName(
                Notification.Name(IPCConstants.snapshotNotification),
                object: json,
                userInfo: ["complete": true],
                deliverImmediately: true
            )
            return
        }

        let chunks = chunk(json, size: maxChunk)
        let batchId = UUID().uuidString
        for (i, part) in chunks.enumerated() {
            center.postNotificationName(
                Notification.Name(IPCConstants.snapshotNotification),
                object: part,
                userInfo: [
                    "batchId": batchId,
                    "index": i,
                    "total": chunks.count,
                    "complete": i == chunks.count - 1,
                ] as [String: Any],
                deliverImmediately: true
            )
        }
    }

    private static func writeFallback(json: String) {
        let support = ManifestStore.applicationSupportLayout().root
            .appendingPathComponent(IPCConstants.snapshotFileName)
        try? json.write(to: support, atomically: true, encoding: .utf8)

        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: IPCConstants.appGroupId
        ) {
            let url = container.appendingPathComponent(IPCConstants.snapshotFileName)
            try? json.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private static func chunk(_ s: String, size: Int) -> [String] {
        var result: [String] = []
        var start = s.startIndex
        while start < s.endIndex {
            let end = s.index(start, offsetBy: size, limitedBy: s.endIndex) ?? s.endIndex
            result.append(String(s[start..<end]))
            start = end
        }
        return result
    }
}
