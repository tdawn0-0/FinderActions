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
        .task { state.refreshExtensionStatus() }
    }

    private var extensionSection: some View {
        Section {
            Label {
                Text(state.extensionEnabledHint)
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
            Text("Grants permission for scripts to access protected folders without prompts.")
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
        state.extensionEnabledHint.contains("Registered") && !state.extensionEnabledHint.contains("Not")
    }
}
