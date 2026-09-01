import Foundation

/// The action identity that must survive Finder's reconstruction of an NSMenuItem.
public struct MenuActionRoute: Sendable, Hashable {
    public let actionId: String
    public let menuKind: MenuKind

    public init(actionId: String, menuKind: MenuKind) {
        self.actionId = actionId
        self.menuKind = menuKind
    }
}

/// Assigns stable, non-zero integer tags to Finder menu action routes.
///
/// Finder does not preserve `NSMenuItem.representedObject`, but it does preserve
/// `tag`. Tags remain stable for the registry lifetime so concurrently open menus
/// cannot invalidate one another. All state is protected because Finder Sync can
/// call the extension from arbitrary queues.
public final class MenuActionTagRegistry: @unchecked Sendable {
    private var tagByRoute: [MenuActionRoute: Int] = [:]
    private var routeByTag: [Int: MenuActionRoute] = [:]
    private var nextTag = 1
    private let lock = NSLock()

    public init() {}

    public func tag(for route: MenuActionRoute) -> Int {
        lock.lock()
        defer { lock.unlock() }

        if let existing = tagByRoute[route] {
            return existing
        }

        let tag = nextTag
        nextTag += 1
        tagByRoute[route] = tag
        routeByTag[tag] = route
        return tag
    }

    public func route(for tag: Int) -> MenuActionRoute? {
        lock.lock()
        defer { lock.unlock() }
        return routeByTag[tag]
    }
}
