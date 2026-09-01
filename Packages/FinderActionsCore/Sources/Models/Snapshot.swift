import Foundation

// MARK: - Menu Snapshot (Host → Extension)

public struct MenuSnapshotItem: Codable, Sendable, Equatable, Identifiable {
    public var actionId: String
    public var title: String
    public var subtitle: String?
    public var sfSymbol: String?
    public var group: String?
    public var showWhen: ShowWhen
    public var enabled: Bool
    public var isSeparator: Bool
    public var extRules: ExtRules?

    public var id: String { actionId }

    public init(
        actionId: String,
        title: String,
        subtitle: String? = nil,
        sfSymbol: String? = nil,
        group: String? = nil,
        showWhen: ShowWhen = .always,
        enabled: Bool = true,
        isSeparator: Bool = false,
        extRules: ExtRules? = nil
    ) {
        self.actionId = actionId
        self.title = title
        self.subtitle = subtitle
        self.sfSymbol = sfSymbol
        self.group = group
        self.showWhen = showWhen
        self.enabled = enabled
        self.isSeparator = isSeparator
        self.extRules = extRules
    }
}

public struct MenuSnapshot: Codable, Sendable, Equatable {
    public var v: Int
    public var generatedAt: String
    public var hostRunning: Bool
    public var items: [MenuSnapshotItem]

    public init(
        v: Int = 1,
        generatedAt: String = ISO8601DateFormatter().string(from: Date()),
        hostRunning: Bool = true,
        items: [MenuSnapshotItem] = []
    ) {
        self.v = v
        self.generatedAt = generatedAt
        self.hostRunning = hostRunning
        self.items = items
    }
}

// MARK: - Execute Request (Extension → Host)

public enum MenuKind: String, Codable, Sendable, Hashable {
    case contextualMenuForItems
    case contextualMenuForContainer
    case contextualMenuForSidebar
    case toolbarItemMenu
}

public struct ExecuteRequest: Codable, Sendable, Equatable {
    public var v: Int
    public var requestId: String
    public var actionId: String
    public var paths: [String]
    public var containerPath: String?
    public var menuKind: MenuKind?

    public init(
        v: Int = 1,
        requestId: String = UUID().uuidString,
        actionId: String,
        paths: [String],
        containerPath: String? = nil,
        menuKind: MenuKind? = nil
    ) {
        self.v = v
        self.requestId = requestId
        self.actionId = actionId
        self.paths = paths
        self.containerPath = containerPath
        self.menuKind = menuKind
    }
}

// MARK: - IPC constants

public enum IPCConstants {
    /// DistributedNotification name: Host → Extension (menu snapshot payload)
    public static let snapshotNotification = "com.finderactions.host.snapshot"
    /// DistributedNotification name: Extension → Host (execute request)
    public static let executeNotification = "com.finderactions.extension.execute"
    /// DistributedNotification name: Extension → Host (request latest snapshot)
    public static let snapshotRequestNotification = "com.finderactions.extension.snapshot-request"
    /// DistributedNotification name: Host ready ping
    public static let hostReadyNotification = "com.finderactions.host.ready"
    /// DistributedNotification name: Settings helper → Host configuration reload
    public static let configurationChangedNotification = "com.finderactions.settings.configuration-changed"
    /// UserDefaults / App Group suite (optional cold-start fallback)
    public static let appGroupId = "group.com.finderactions.shared"
    public static let snapshotFileName = "menu-snapshot.json"
    /// Host bundle id
    public static let hostBundleId = "com.finderactions.host"
    /// On-demand Settings helper bundle id
    public static let settingsBundleId = "com.finderactions.host.Settings"
    /// Extension bundle id
    public static let extensionBundleId = "com.finderactions.host.FinderSync"
}
