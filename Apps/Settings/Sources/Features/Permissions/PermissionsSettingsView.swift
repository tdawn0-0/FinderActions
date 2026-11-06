import SwiftUI

struct PermissionsSettingsView: View {
    @Environment(AppState.self) private var state

    private static let troubleshootingCommands = """
        pluginkit -a "/Applications/FinderActions.app/Contents/PlugIns/FAFinderSync.appex"
        pluginkit -e use -i com.finderactions.host.FinderSync
        killall Finder
        """

    var body: some View {
        Form {
            extensionSection
            fullDiskAccessSection
            troubleshootingSection
        }
        .formStyle(.grouped)
        .navigationTitle("Extensions & Permissions")
        .task { state.refreshExtensionStatus(); state.refreshLogs() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            state.refreshExtensionStatus(); state.refreshLogs()
        }
        .onReceive(DistributedNotificationCenter.default().publisher(for: WorkflowFeedback.executionChanged)) { _ in
            state.refreshLogs()
        }
    }

    private var extensionSection: some View {
        Section {
            Label {
                Text(state.finderSetupVerified ? String(localized: "Verified — Copy Path completed in Finder") : state.extensionRegistration.message)
                    .textSelection(.enabled)
            } icon: {
                Image(systemName: isExtensionReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(isExtensionReady ? .green : .orange)
            }

            HStack {
                Button("Open System Settings → Extensions") { state.openExtensionSettings() }
                Button("Restart Finder") { state.restartFinder() }
                Spacer()
                Button("Refresh Status") { state.refreshExtensionStatus() }
            }
        } header: {
            Text("FinderSync Extension")
        } footer: {
            Text("Displays right-click action items in Finder.")
        }
    }

    private var fullDiskAccessSection: some View {
        Section {
            FullDiskAccessGuideView()
        } header: {
            Text("Full Disk Access (FDA)")
        } footer: {
            Text("Full Disk Access is needed only for scripts that access protected folders. Enable it when your workflow needs that access.")
        }
    }

    private var troubleshootingSection: some View {
        Section {
            DisclosureGroup("Troubleshooting Terminal Commands") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("If the menu does not show after enabling in System Settings:")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(Self.troubleshootingCommands)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .padding(.top, 4)
            }
        }
    }

    private var isExtensionReady: Bool {
        state.finderSetupVerified
    }
}
