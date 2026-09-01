import Foundation

public enum SnapshotBuilder {
    /// Build a menu snapshot from enabled actions (Host side).
    /// Does not filter by live selection — extension applies showWhen/extRules lightly.
    public static func build(from manifest: ActionManifest, hostRunning: Bool = true) -> MenuSnapshot {
        let items = manifest.actions
            .filter(\.enabled)
            .sorted { $0.sortIndex < $1.sortIndex }
            .map { action -> MenuSnapshotItem in
                MenuSnapshotItem(
                    actionId: action.id,
                    title: action.name,
                    subtitle: action.subtitle,
                    sfSymbol: action.icon?.sfSymbol,
                    group: action.group,
                    showWhen: action.showWhen,
                    enabled: action.enabled,
                    isSeparator: false,
                    extRules: action.extRules
                )
            }
        return MenuSnapshot(
            v: 1,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            hostRunning: hostRunning,
            items: items
        )
    }

    /// Filter snapshot items for a live selection (extension or host "run for selection").
    public static func filter(_ snapshot: MenuSnapshot, context: SelectionContext) -> MenuSnapshot {
        var copy = snapshot
        copy.items = snapshot.items.filter { item in
            if item.isSeparator { return true }
            return ShowWhenMatcher.shouldShow(
                showWhen: item.showWhen,
                extRules: item.extRules,
                context: context
            )
        }
        return copy
    }
}
