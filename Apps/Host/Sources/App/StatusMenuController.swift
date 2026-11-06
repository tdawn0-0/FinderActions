import AppKit

/// Minimal, always-resident menu bar UI. Configuration lives in a separate process.
@MainActor
final class StatusMenuController: NSObject, NSMenuDelegate {
    private let appState: HostRuntimeState
    private let openSettings: @MainActor () -> Void
    private let statusItem: NSStatusItem
    private let summaryItem = NSMenuItem()
    private let activityItem = NSMenuItem(title: String(localized: "Recent Activity"), action: nil, keyEquivalent: "")

    init(
        appState: HostRuntimeState,
        openSettings: @escaping @MainActor () -> Void
    ) {
        self.appState = appState
        self.openSettings = openSettings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureStatusItem()
        appState.onActivityChanged = { [weak self] in self?.refreshActivity() }
        refreshActivity()
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshActivity()
        let enabledCount = Int64(appState.effectiveManifest.actions.lazy.filter(\.enabled).count)
        summaryItem.title = String.localizedStringWithFormat(
            NSLocalizedString("%lld actions ready in Finder", comment: "Enabled action count"),
            enabledCount
        )
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "hammer.fill",
                accessibilityDescription: NSLocalizedString("FinderActions", comment: "App name")
            )
            button.toolTip = NSLocalizedString("FinderActions", comment: "App name")
            button.setAccessibilityLabel(NSLocalizedString("FinderActions", comment: "App name"))
        }

        let menu = NSMenu()
        menu.delegate = self

        summaryItem.isEnabled = false
        menu.addItem(summaryItem)
        menu.addItem(activityItem)
        menu.addItem(.separator())
        menu.addItem(makeItem(
            title: NSLocalizedString("Open Settings", comment: "Open settings menu item"),
            action: #selector(openSettingsSelected),
            keyEquivalent: ","
        ))
        menu.addItem(makeItem(
            title: NSLocalizedString("Open Scripts Folder", comment: "Open scripts menu item"),
            action: #selector(openScriptsSelected)
        ))
        menu.addItem(.separator())
        menu.addItem(makeItem(
            title: NSLocalizedString("Restart Finder", comment: "Restart Finder menu item"),
            action: #selector(restartFinderSelected)
        ))
        menu.addItem(.separator())
        menu.addItem(makeItem(
            title: NSLocalizedString("Quit", comment: "Quit menu item"),
            action: #selector(quitSelected),
            keyEquivalent: "q"
        ))

        statusItem.menu = menu
    }

    private func refreshActivity() {
        let count = appState.activeExecutions.count
        statusItem.length = count == 0 ? NSStatusItem.squareLength : NSStatusItem.variableLength
        statusItem.button?.title = count == 0 ? "" : " \(count)"
        statusItem.button?.toolTip = count == 0 ? String(localized: "FinderActions") : String(localized: "Running tasks: \(count)")
        let submenu = NSMenu()
        for run in appState.activeExecutions.values.sorted(by: { $0.startedAt > $1.startedAt }).prefix(10) {
            let item = NSMenuItem(title: String(localized: "Running: \(run.actionName) · \(run.paths.count) paths"), action: nil, keyEquivalent: "")
            item.isEnabled = false
            submenu.addItem(item)
        }
        for log in appState.logStore.recent(limit: 10) {
            let symbol = log.success ? "✓" : "✕"
            let duration = log.durationSeconds.map { String(format: " · %.1fs", $0) } ?? ""
            let item = makeItem(title: "\(symbol) \(log.actionName ?? log.actionId) · \(log.paths.count)\(duration)", action: #selector(openActivitySelected(_:)))
            item.representedObject = log.actionId
            submenu.addItem(item)
        }
        if submenu.items.isEmpty {
            let item = NSMenuItem(title: String(localized: "No execution logs yet"), action: nil, keyEquivalent: "")
            item.isEnabled = false
            submenu.addItem(item)
        }
        submenu.addItem(.separator())
        submenu.addItem(makeItem(title: String(localized: "Activity Logs"), action: #selector(openActivitySelected(_:))))
        activityItem.submenu = submenu
    }

    @objc private func openActivitySelected(_ sender: NSMenuItem) {
        WorkflowFeedback.requestNavigation(destination: "logs", actionID: sender.representedObject as? String, preferences: appState.preferences)
        openSettings()
    }

    private func makeItem(
        title: String,
        action: Selector,
        keyEquivalent: String = ""
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    @objc private func openSettingsSelected() {
        openSettings()
    }

    @objc private func openScriptsSelected() {
        appState.openActionsDirectory()
    }

    @objc private func restartFinderSelected() {
        appState.restartFinder()
    }

    @objc private func quitSelected() {
        NSApp.terminate(nil)
    }
}
