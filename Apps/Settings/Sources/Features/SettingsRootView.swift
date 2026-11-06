import SwiftUI

// MARK: - Navigation Sections

enum SettingsSection: String, CaseIterable, Identifiable {
    case actions
    case applications
    case permissions
    case logs
    case general
    case about

    var id: String { rawValue }

    /// Grouped the way the sidebar renders them: content first, app-level last.
    static let groups: [[SettingsSection]] = [
        [.actions, .applications, .permissions, .logs],
        [.general, .about],
    ]

    var title: LocalizedStringKey {
        switch self {
        case .actions: "Actions"
        case .applications: "Applications"
        case .permissions: "Extensions & Permissions"
        case .logs: "Activity Logs"
        case .general: "General"
        case .about: "About"
        }
    }

    var systemImage: String {
        switch self {
        case .actions: "bolt"
        case .applications: "square.grid.2x2"
        case .permissions: "puzzlepiece.extension"
        case .logs: "list.bullet.rectangle"
        case .general: "gearshape"
        case .about: "info.circle"
        }
    }
}

// MARK: - Root Settings View

/// Root view for the short-lived Settings helper process.
struct SettingsRootView: View {
    @Environment(AppState.self) private var state
    @State private var selection: SettingsSection? = .actions

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(SettingsSection.groups, id: \.self) { group in
                    Section {
                        ForEach(group) { section in
                            Label(section.title, systemImage: section.systemImage)
                                .tag(section)
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 280)
        } detail: {
            switch selection ?? .actions {
            case .actions: ActionsSettingsView()
            case .applications: ApplicationsSettingsView()
            case .permissions: PermissionsSettingsView()
            case .logs: LogsSettingsView()
            case .general: GeneralSettingsView()
            case .about: AboutView()
            }
        }
        .onAppear { consumeNavigation() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in consumeNavigation() }
        .onReceive(NotificationCenter.default.publisher(for: WorkflowFeedback.settingsNavigation)) { _ in consumeNavigation() }
        .onReceive(DistributedNotificationCenter.default().publisher(for: WorkflowFeedback.settingsNavigation)) { _ in consumeNavigation() }
        .safeAreaInset(edge: .bottom) {
            if let error = state.configurationError {
                VStack(alignment: .leading) {
                    Label("Configuration could not be saved or loaded", systemImage: "exclamationmark.triangle")
                    Text(error).font(.caption).textSelection(.enabled)
                    HStack {
                        Button("Reload from Disk") { state.reloadManifest() }
                        if !state.writesBlocked { Button("Retry Save") { state.saveManifest() } }
                    }
                }.padding().frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 900, minHeight: 540)
    }
    private func consumeNavigation() {
        guard let destination = state.preferences.object(forKey: "settingsDestination") as? String,
              let section = SettingsSection(rawValue: destination), section == .logs || section == .actions else { return }
        selection = section
        if let id = state.preferences.object(forKey: "settingsActionID") as? String,
           section == .logs || state.manifest.actions.contains(where: { $0.id == id }) { state.selectedActionID = id }
        state.preferences.set("", forKey: "settingsDestination")
        state.preferences.set("", forKey: "settingsActionID")
    }

}
