import SwiftUI
import FinderActionsCore

/// Master list of actions with the selected action's editor in a trailing inspector.
struct ActionsSettingsView: View {
    @Environment(AppState.self) private var state
    @State private var selection: String?
    @State private var searchText = ""
    @State private var showInspector = true
    @State private var pendingDeletion: [String] = []

    private var sortedActions: [ActionDefinition] {
        state.manifest.actions.sorted { $0.sortIndex < $1.sortIndex }
    }

    private var visibleActions: [ActionDefinition] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return sortedActions }
        return sortedActions.filter { action in
            action.name.localizedCaseInsensitiveContains(query)
                || (action.subtitle?.localizedCaseInsensitiveContains(query) ?? false)
                || (action.group?.localizedCaseInsensitiveContains(query) ?? false)
                || action.id.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        content
            .navigationTitle("Actions")
            .searchable(text: $searchText, placement: .toolbar, prompt: "Search actions…")
            .toolbar { toolbarContent }
            .inspector(isPresented: $showInspector) { inspector }
            .confirmationDialog(
                "Delete Selected Action",
                isPresented: Binding(
                    get: { !pendingDeletion.isEmpty },
                    set: { if !$0 { pendingDeletion = [] } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { delete(pendingDeletion) }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                if selection == nil { selection = sortedActions.first?.id }
            }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if visibleActions.isEmpty {
            if searchText.isEmpty {
                ContentUnavailableView("No actions found", systemImage: "bolt.slash")
            } else {
                ContentUnavailableView.search(text: searchText)
            }
        } else {
            List(selection: $selection) {
                ForEach(visibleActions) { action in
                    ActionRow(action: action) { state.setEnabled(actionId: action.id, enabled: $0) }
                        .tag(action.id)
                }
                // Indices of a filtered list do not map onto the full manifest.
                .onMove(perform: searchText.isEmpty ? { state.moveAction(from: $0, to: $1) } : nil)
            }
            .contextMenu(forSelectionType: String.self) { ids in
                if !ids.isEmpty {
                    Button("Duplicate Action") { duplicate(ids.first) }
                        .disabled(ids.count != 1)
                    Divider()
                    Button("Delete Selected Action", role: .destructive) {
                        pendingDeletion = Array(ids)
                    }
                }
            }
            .onDeleteCommand {
                if let selection { pendingDeletion = [selection] }
            }
        }
    }

    @ViewBuilder
    private var inspector: some View {
        Group {
            if let id = selection, let binding = binding(for: id) {
                ActionInspectorView(action: binding)
                    .id(id)
            } else {
                ContentUnavailableView(
                    "No Action Selected",
                    systemImage: "bolt.badge.automatic",
                    description: Text("Select an action to inspect its settings, edit scripts, and test run.")
                )
            }
        }
        .inspectorColumnWidth(min: 340, ideal: 400, max: 560)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            Button {
                selection = state.addNewAction().id
                showInspector = true
            } label: {
                Label("Add New Action", systemImage: "plus")
            }
            .help("Add New Action")

            Button {
                duplicate(selection)
            } label: {
                Label("Duplicate Action", systemImage: "plus.square.on.square")
            }
            .disabled(selection == nil)
            .help("Duplicate Action")

            Button {
                if let selection { pendingDeletion = [selection] }
            } label: {
                Label("Delete Selected Action", systemImage: "trash")
            }
            .disabled(selection == nil)
            .help("Delete Selected Action")
        }

        ToolbarItemGroup {
            Button {
                state.openActionsDirectory()
            } label: {
                Label("Open Scripts Folder", systemImage: "folder")
            }
            .help("Open Scripts Directory in Finder")

            Button {
                showInspector.toggle()
            } label: {
                Label("Inspector", systemImage: "sidebar.trailing")
            }
        }
    }

    // MARK: Mutations

    private func duplicate(_ id: String?) {
        guard let id, let copy = state.duplicateAction(id: id) else { return }
        selection = copy.id
    }

    private func delete(_ ids: [String]) {
        for id in ids { state.deleteAction(id: id) }
        pendingDeletion = []
        if let current = selection, ids.contains(current) {
            selection = sortedActions.first?.id
        }
    }

    /// Binding into the manifest by id, resilient to the action disappearing
    /// while the inspector is still on screen.
    private func binding(for id: String) -> Binding<ActionDefinition>? {
        guard let current = state.manifest.actions.first(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { state.manifest.actions.first(where: { $0.id == id }) ?? current },
            set: { newValue in
                guard let index = state.manifest.actions.firstIndex(where: { $0.id == id }) else { return }
                state.manifest.actions[index] = newValue
                state.scheduleManifestSave()
            }
        )
    }
}

// MARK: - Row

private struct ActionRow: View {
    let action: ActionDefinition
    var onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ActionIconTile(symbol: action.icon?.sfSymbol, isActive: action.enabled, size: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(action.name)
                    .lineLimit(1)
                    .foregroundStyle(action.enabled ? .primary : .secondary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Toggle("Enabled", isOn: Binding(get: { action.enabled }, set: { onToggle($0) }))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.vertical, 2)
    }

    private var detail: String {
        let type = String(localized: action.type.displayName)
        guard let subtitle = action.subtitle, !subtitle.isEmpty else { return type }
        return "\(type) · \(subtitle)"
    }
}

struct ActionIconTile: View {
    let symbol: String?
    var isActive = true
    var size: CGFloat = 30

    var body: some View {
        Image(systemName: symbol ?? "bolt")
            .font(.system(size: size * 0.46, weight: .medium))
            .foregroundStyle(isActive ? Color.accentColor : .secondary)
            .frame(width: size, height: size)
            .background(
                (isActive ? Color.accentColor : .secondary).opacity(0.14),
                in: RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}
