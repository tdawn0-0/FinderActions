import Foundation
import FinderActionsCore

/// Registration is a hint; only a completed Finder action verifies the end-to-end path.
enum ExtensionRegistration: String, Sendable, Equatable {
    case unknown, notRegistered, registered, enabled

    static func parse(_ output: String, bundleID: String) -> Self {
        let lines = output.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let line = lines.first(where: { $0.contains(bundleID) }) else {
            return output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .notRegistered : .unknown
        }
        return line.hasPrefix("+") ? .enabled : .registered
    }

    var message: String {
        switch self {
        case .unknown: String(localized: "Extension status unknown — check System Settings")
        case .notRegistered: String(localized: "Not registered — launch FinderActions from Applications")
        case .registered: String(localized: "Registered — enable the extension in System Settings")
        case .enabled: String(localized: "Enabled — verify by running Copy Path in Finder")
        }
    }
}

enum ExecutionNotificationMode: String, CaseIterable, Sendable {
    case all, failures, off
    var title: String {
        switch self {
        case .all: String(localized: "Every completion")
        case .failures: String(localized: "Failures only")
        case .off: String(localized: "Off")
        }
    }
    func shouldNotify(success: Bool) -> Bool { self == .all || (self == .failures && !success) }
    @MainActor static func load(preferences: PreferencesStore) -> Self {
        if let raw = preferences.object(forKey: "notificationMode") as? String, let mode = Self(rawValue: raw) { return mode }
        return (preferences.object(forKey: "notificationsEnabled") as? Bool ?? true) ? .all : .off
    }
    @MainActor func persist(preferences: PreferencesStore) {
        preferences.set(rawValue, forKey: "notificationMode")
        preferences.set(self != .off, forKey: "notificationsEnabled")
    }
}

/// Route data contains identifiers only. The receiving Settings process validates the destination.
enum WorkflowFeedback {
    static let settingsNavigation = Notification.Name("com.finderactions.settingsNavigation")
    static let executionChanged = Notification.Name("com.finderactions.executionChanged")
    @MainActor static func requestNavigation(destination: String, actionID: String?, preferences: PreferencesStore) {
        guard destination == "logs" || destination == "actions" else { return }
        preferences.set(destination, forKey: "settingsDestination")
        preferences.set(actionID ?? "", forKey: "settingsActionID")
        if !preferences.isInMemory {
            DistributedNotificationCenter.default().postNotificationName(settingsNavigation, object: nil, deliverImmediately: true)
        }
        NotificationCenter.default.post(name: settingsNavigation, object: nil)
    }
    static func verifiesSetup(_ log: ExecLogEntry) -> Bool {
        log.source == .finder && log.success && log.actionId == "copy-path"
    }
}

struct ActiveExecution: Identifiable, Sendable {
    let id: String
    let actionID: String
    let actionName: String
    let paths: [String]
    let startedAt: Date
}
