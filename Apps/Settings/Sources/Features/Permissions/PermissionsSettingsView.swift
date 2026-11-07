import AppKit
import SwiftUI

struct PermissionsSettingsView: View {
    @Environment(AppState.self) private var state
    @State private var copiedCommands = false

    private static let resetCommands = """
        pluginkit -a "/Applications/FinderActions.app/Contents/PlugIns/FAFinderSync.appex"
        pluginkit -e use -i com.finderactions.host.FinderSync
        killall Finder
        """

    var body: some View {
        Form {
            extensionSection
            fullDiskAccessSection
            diagnosticsSection
        }
        .formStyle(.grouped)
        .navigationTitle("Permissions")
        .task { state.refreshExtensionStatus(); state.refreshLogs() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            state.refreshExtensionStatus(); state.refreshLogs()
        }
        .onReceive(DistributedNotificationCenter.default().publisher(for: WorkflowFeedback.executionChanged)) { _ in
            state.refreshLogs()
        }
    }

    private var extensionSection: some View {
        Section("Finder Extension") {
            LabeledContent("Status") {
                HStack(spacing: 6) {
                    Image(systemName: state.finderSetupVerified ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(state.finderSetupVerified ? .green : .orange)
                    Text(state.finderSetupVerified ? String(localized: "Verified") : state.extensionRegistration.message)
                        .textSelection(.enabled)
                }
            }

            HStack {
                Button("Extension Settings…") { state.openExtensionSettings() }
                Button("Restart Finder") { state.restartFinder() }
                Spacer()
                Button {
                    state.refreshExtensionStatus()
                    state.refreshLogs()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh")
            }
        }
    }

    private var fullDiskAccessSection: some View {
        Section("Full Disk Access") {
            FullDiskAccessGuideView()
        }
    }

    private var diagnosticsSection: some View {
        Section {
            DisclosureGroup("Terminal Reset Commands") {
                VStack(alignment: .trailing, spacing: 6) {
                    Text(Self.resetCommands)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

                    Button(copiedCommands ? "Copied" : "Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(Self.resetCommands, forType: .string)
                        copiedCommands = true
                    }
                    .controlSize(.small)
                }
                .padding(.top, 4)
            }
        }
    }
}
