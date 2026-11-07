import SwiftUI

struct SettingsRootView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var bindableState = state

        NavigationSplitView {
            List(selection: $bindableState.selectedSection) {
                ForEach(SettingsSection.groups, id: \.self) { group in
                    Section {
                        ForEach(group) { section in
                            sidebarRow(for: section)
                                .tag(section)
                                .accessibilityIdentifier(SettingsAccessibilityID.sidebar(section))
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 205, max: 240)
        } detail: {
            switch state.selectedSection {
            case .actions: ActionsSettingsView()
            case .applications: ApplicationsSettingsView()
            case .logs: LogsSettingsView()
            case .permissions: PermissionsSettingsView()
            case .general: GeneralSettingsView()
            }
        }
        .onAppear { state.consumePendingNavigation() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            state.consumePendingNavigation()
        }
        .onReceive(NotificationCenter.default.publisher(for: WorkflowFeedback.settingsNavigation)) { _ in
            state.consumePendingNavigation()
        }
        .onReceive(DistributedNotificationCenter.default().publisher(for: WorkflowFeedback.settingsNavigation)) { _ in
            state.consumePendingNavigation()
        }
        .safeAreaInset(edge: .bottom) {
            if let error = state.configurationError {
                errorBar(error)
            }
        }
        .frame(minWidth: 880, minHeight: 540)
    }

    @ViewBuilder
    private func sidebarRow(for section: SettingsSection) -> some View {
        HStack {
            Label(section.title, systemImage: section.systemImage)
            if section == .permissions && !state.finderSetupVerified {
                Spacer()
                Circle()
                    .fill(.orange)
                    .frame(width: 7, height: 7)
                    .accessibilityLabel("Attention Required")
            }
        }
    }

    private func errorBar(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(error)
                .font(.callout)
                .lineLimit(2)
                .textSelection(.enabled)
            Spacer()
            Button("Reload") { state.reloadManifest() }
            if !state.writesBlocked && state.isDirty {
                Button("Retry") { state.saveManifest() }
            }
            if !state.writesBlocked && !state.isDirty {
                Button {
                    state.configurationError = nil
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Dismiss")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .overlay(alignment: .top) { Divider() }
    }
}
