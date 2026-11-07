import SwiftUI
import FinderActionsCore

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
                || (action.group?.localizedCaseInsensitiveContains(query) ?? false)
                || action.id.localizedCaseInsensitiveContains(query)
        }
    }

    private var selectedAction: ActionDefinition? {
        sortedActions.first { $0.id == selection }
    }

    var body: some View {
        content
            .navigationTitle("Actions")
            .searchable(text: $searchText, placement: .toolbar, prompt: "Filter")
            .toolbar { toolbarContent }
            .disabled(state.liveTest.isRunning)
            .inspector(isPresented: $showInspector) { inspector }
            .confirmationDialog(
                "Delete Action?",
                isPresented: Binding(
                    get: { !pendingDeletion.isEmpty },
                    set: { if !$0 { pendingDeletion = [] } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { delete(pendingDeletion) }
                Button("Cancel", role: .cancel) {}
            }
            .onChange(of: state.selectedActionID) { _, id in
                if let id, sortedActions.contains(where: { $0.id == id }) {
                    selection = id
                    showInspector = true
                }
            }
            .onAppear {
                if let id = state.selectedActionID, sortedActions.contains(where: { $0.id == id }) {
                    selection = id
                }
                if selection == nil {
                    selection = sortedActions.first?.id
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if visibleActions.isEmpty {
            if searchText.isEmpty {
                ContentUnavailableView {
                    Label("No Actions", systemImage: "bolt.slash")
                } actions: {
                    addMenu
                }
            } else {
                ContentUnavailableView.search(text: searchText)
            }
        } else {
            List(selection: $selection) {
                ForEach(visibleActions) { action in
                    ActionRow(action: action) { state.setEnabled(actionId: action.id, enabled: $0) }
                        .tag(action.id)
                }
                .onMove(perform: searchText.isEmpty ? { state.moveAction(from: $0, to: $1) } : nil)
            }
            .accessibilityIdentifier(SettingsAccessibilityID.actionsList)
            .contextMenu(forSelectionType: String.self) { ids in
                if !ids.isEmpty {
                    Button("Duplicate") { duplicate(ids.first) }
                        .disabled(ids.count != 1)
                    Divider()
                    Button("Delete", role: .destructive) {
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
                ContentUnavailableView("No Selection", systemImage: "sidebar.trailing")
            }
        }
        .inspectorColumnWidth(min: 330, ideal: 390, max: 520)
    }

    private var addMenu: some View {
        Menu {
            ForEach(ActionTemplate.allCases, id: \.self) { template in
                Button {
                    selection = state.addAction(template: template).id
                    showInspector = true
                } label: {
                    Label(templateTitle(template), systemImage: templateSymbol(template))
                }
            }
        } label: {
            Label("New Action", systemImage: "plus")
        }
        .accessibilityIdentifier(SettingsAccessibilityID.actionsAddMenu)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            addMenu

            Button {
                duplicate(selection)
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            .disabled(selection == nil)

            Button {
                if let selection { pendingDeletion = [selection] }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .disabled(selection == nil)
        }

        ToolbarItemGroup {
            ActionTransferView(action: selectedAction, store: state.store) { package in
                state.flushPendingManifestSave()
                guard !state.writesBlocked && !state.isDirty else {
                    throw ManifestError.writeFailed("Resolve configuration errors before importing.")
                }
                state.manifest = try package.install(into: state.store, manifest: state.manifest)
                state.onManifestChanged?()
                selection = state.manifest.actions.last?.id
            }

            Button {
                state.openActionsDirectory()
            } label: {
                Label("Scripts Folder", systemImage: "folder")
            }

            Button {
                showInspector.toggle()
            } label: {
                Label("Inspector", systemImage: "sidebar.trailing")
            }
        }
    }

    private func templateTitle(_ template: ActionTemplate) -> LocalizedStringKey {
        switch template {
        case .perFile: "Process Selected Files"
        case .currentDirectory: "Run in Current Directory"
        case .application: "Open with Application"
        case .blank: "Blank Script"
        }
    }

    private func templateSymbol(_ template: ActionTemplate) -> String {
        switch template {
        case .perFile: "doc.on.doc"
        case .currentDirectory: "terminal"
        case .application: "app.badge"
        case .blank: "chevron.left.forwardslash.chevron.right"
        }
    }

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

    private func binding(for id: String) -> Binding<ActionDefinition>? {
        guard let current = state.manifest.actions.first(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { state.manifest.actions.first(where: { $0.id == id }) ?? current },
            set: { newValue in
                guard let index = state.manifest.actions.firstIndex(where: { $0.id == id }) else { return }
                guard !state.liveTest.isRunning else { return }
                state.manifest.actions[index] = newValue
                state.scheduleManifestSave()
            }
        )
    }
}

private struct ActionRow: View {
    let action: ActionDefinition
    var onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ActionIconTile(symbol: action.icon?.sfSymbol, isActive: action.enabled, size: 28)

            Text(action.name)
                .lineLimit(1)
                .foregroundStyle(action.enabled ? .primary : .secondary)

            Spacer(minLength: 8)

            if let badge = trailingBadge {
                Text(badge)
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Toggle(action.name, isOn: Binding(get: { action.enabled }, set: { onToggle($0) }))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .accessibilityLabel(action.name)
        }
        .padding(.vertical, 2)
    }

    private var trailingBadge: String? {
        if let exts = action.extRules?.pathExtensions, !exts.isEmpty {
            return exts.prefix(2).map { ".\($0)" }.joined(separator: " ")
        }
        if let group = action.group, !group.isEmpty {
            return group
        }
        return nil
    }
}

struct ActionIconTile: View {
    let symbol: String?
    var isActive = true
    var size: CGFloat = 28

    var body: some View {
        Image(systemName: symbol ?? "bolt")
            .font(.system(size: size * 0.46, weight: .medium))
            .foregroundStyle(isActive ? Color.accentColor : .secondary)
            .frame(width: size, height: size)
            .background(
                (isActive ? Color.accentColor : .secondary).opacity(0.14),
                in: RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}
