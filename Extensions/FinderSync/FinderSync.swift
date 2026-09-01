import Cocoa
import FinderSync // Apple framework (module name differs from our target FAFinderSync)
import FinderActionsCore

/// Extremely thin FinderSync: render snapshot menus, forward clicks to Host.
/// No Process, no script execution, no file-content reads, no long-term bookmarks.
///
/// Note: FIFinderSync is a legacy ObjC entry point (not MainActor-isolated by the system),
/// so this class stays nonisolated and keeps IPC behind a lock/`@unchecked Sendable` client.
final class FinderSync: FIFinderSync {

    private let ipc = IPCClient()
    private let menuRenderer = MenuRenderer()
    private let stateLock = NSLock()
    private var _snapshot: MenuSnapshot?

    private var snapshot: MenuSnapshot? {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _snapshot
        }
        set {
            stateLock.lock()
            _snapshot = newValue
            stateLock.unlock()
        }
    }

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
        ipc.onSnapshot = { [weak self] snap in
            self?.snapshot = snap
        }
        ipc.start()
        snapshot = ipc.loadCachedSnapshot()
    }

    // MARK: - Primary menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "")
        let kind = mapKind(menuKind)
        let context = currentSelectionContext()

        // Live Host process check — do NOT trust cached snap.hostRunning
        let hostUp = ipc.isHostRunning()
        guard MenuAvailability.shouldShowActionMenu(
            hostProcessRunning: hostUp,
            snapshot: snapshot
        ), let snap = snapshot else {
            return offlineMenu()
        }

        let filtered = SnapshotBuilder.filter(snap, context: context)
        menuRenderer.populate(
            menu: menu,
            items: filtered.items,
            action: #selector(runAction(_:)),
            menuKind: kind
        )
        return menu
    }

    private func offlineMenu() -> NSMenu {
        let menu = NSMenu(title: "")
        let item = NSMenuItem(
            title: String(localized: "FinderActions: Host not running"),
            action: #selector(openHost(_:)),
            keyEquivalent: ""
        )
        menu.addItem(item)

        let open = NSMenuItem(
            title: String(localized: "Open FinderActions"),
            action: #selector(openHost(_:)),
            keyEquivalent: ""
        )
        menu.addItem(open)
        return menu
    }

    /// Finder invokes menu selectors from its XPC endpoint queue, not necessarily
    /// the main queue. Keep this legacy ObjC entry point nonisolated so Swift 6
    /// does not install a MainActor precondition in the generated thunk.
    @IBAction nonisolated func runAction(_ sender: NSMenuItem) {
        guard let route = menuRenderer.route(for: sender) else { return }
        let paths = selectedPaths()
        let container = FIFinderSyncController.default().targetedURL()?.path
        let request = ExecuteRequest(
            actionId: route.actionId,
            paths: paths.isEmpty ? (container.map { [$0] } ?? []) : paths,
            containerPath: container,
            menuKind: route.menuKind
        )
        ipc.sendExecute(request)
    }

    @IBAction nonisolated func openHost(_ sender: NSMenuItem) {
        ipc.launchHost()
    }

    // MARK: - Selection helpers (paths only — no content reads)

    private func selectedPaths() -> [String] {
        let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
        return urls.map(\.path)
    }

    private func currentSelectionContext() -> SelectionContext {
        let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
        let paths = urls.map(\.path)
        let isDir: [Bool] = urls.map { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        }
        return SelectionContext(paths: paths, isDirectory: isDir)
    }

    private func mapKind(_ kind: FIMenuKind) -> MenuKind {
        switch kind {
        case .contextualMenuForItems: return .contextualMenuForItems
        case .contextualMenuForContainer: return .contextualMenuForContainer
        case .contextualMenuForSidebar: return .contextualMenuForSidebar
        case .toolbarItemMenu: return .toolbarItemMenu
        @unknown default: return .contextualMenuForItems
        }
    }
}
