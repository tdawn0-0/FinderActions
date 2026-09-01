import AppKit

/// Minimal, always-resident menu bar UI. Configuration lives in the lazy settings window.
@MainActor
final class StatusMenuController: NSObject, NSMenuDelegate {
    private let appState: AppState
    private let openSettings: @MainActor () -> Void
    private let statusItem: NSStatusItem
    private let summaryItem = NSMenuItem()

    init(
        appState: AppState,
        openSettings: @escaping @MainActor () -> Void
    ) {
        self.appState = appState
        self.openSettings = openSettings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureStatusItem()
    }

    func menuWillOpen(_ menu: NSMenu) {
        let enabledCount = Int64(appState.manifest.actions.lazy.filter(\.enabled).count)
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
