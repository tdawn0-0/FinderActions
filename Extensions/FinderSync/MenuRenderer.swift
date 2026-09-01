import AppKit
import FinderActionsCore

/// Finder menu adapter. It hides Finder's restricted NSMenuItem transport and
/// exposes action routes through integer tags, the identifier Finder preserves.
final class MenuRenderer: @unchecked Sendable {
    private let actionTags = MenuActionTagRegistry()

    /// Build NSMenu from snapshot items with optional group submenus.
    func populate(
        menu: NSMenu,
        items: [MenuSnapshotItem],
        action: Selector,
        menuKind: MenuKind
    ) {
        // Group by group name; nil group → top level
        var groups: [String: [MenuSnapshotItem]] = [:]
        var topLevel: [MenuSnapshotItem] = []
        var groupOrder: [String] = []

        for item in items {
            if item.isSeparator {
                topLevel.append(item)
                continue
            }
            if let g = item.group, !g.isEmpty {
                if groups[g] == nil {
                    groups[g] = []
                    groupOrder.append(g)
                }
                groups[g]?.append(item)
            } else {
                topLevel.append(item)
            }
        }

        for item in topLevel {
            if item.isSeparator {
                menu.addItem(.separator())
            } else {
                menu.addItem(makeItem(item, action: action, menuKind: menuKind))
            }
        }

        for g in groupOrder {
            guard let groupItems = groups[g], !groupItems.isEmpty else { continue }
            let submenu = NSMenu(title: g)
            for item in groupItems {
                submenu.addItem(makeItem(item, action: action, menuKind: menuKind))
            }
            let parent = NSMenuItem(title: g, action: nil, keyEquivalent: "")
            parent.submenu = submenu
            menu.addItem(parent)
        }
    }

    /// Recover the route from the reconstructed menu item passed by Finder.
    func route(for sender: NSMenuItem) -> MenuActionRoute? {
        actionTags.route(for: sender.tag)
    }

    private func makeItem(
        _ item: MenuSnapshotItem,
        action: Selector,
        menuKind: MenuKind
    ) -> NSMenuItem {
        let title: String
        if let subtitle = item.subtitle, !subtitle.isEmpty {
            // Two-line style within single title when system allows
            title = "\(item.title) — \(subtitle)"
        } else {
            title = item.title
        }
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
        menuItem.tag = actionTags.tag(for: MenuActionRoute(
            actionId: item.actionId,
            menuKind: menuKind
        ))
        menuItem.isEnabled = item.enabled
        if let symbol = item.sfSymbol,
           let image = NSImage(systemSymbolName: symbol, accessibilityDescription: item.title) {
            menuItem.image = image
        }
        return menuItem
    }
}
