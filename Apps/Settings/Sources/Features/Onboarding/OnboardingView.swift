import SwiftUI
import FinderActionsCore

struct OnboardingView: View {
    @Environment(AppState.self) private var state
    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Text("Set up FinderActions").font(.title2.weight(.semibold))
                    Text("Choose your tools, enable the extension, then try one action in Finder.")
                        .foregroundStyle(.secondary)
                }
                Section("1. Choose your tools") {
                    LabeledContent("Terminal", value: state.openWithSettings.terminal.name)
                    Button("Choose Other Terminal…") { state.chooseApplications(kind: .terminal) }
                    LabeledContent("Editors", value: state.openWithSettings.editors.map(\.name).joined(separator: ", "))
                    Button("Add Custom Editor…") { state.chooseApplications(kind: .editor) }
                }
                Section("2. Enable the Finder extension") {
                    Text(state.extensionRegistration.message).foregroundStyle(.secondary)
                    Button("Open Extension Settings") { state.openExtensionSettings() }
                }
                Section("3. Try Copy Path in Finder") {
                    Text("Open Finder, select a file, then right-click and choose Copy Path. This copies its path to your clipboard.")
                    Button("Open Finder") { state.openActionsDirectory() }
                    Label(state.finderSetupVerified ? "Verified — Copy Path completed in Finder" : "Waiting for a successful Finder action",
                          systemImage: state.finderSetupVerified ? "checkmark.circle.fill" : "circle.dotted")
                    Button("Refresh Status") { state.refreshLogs(); state.refreshExtensionStatus() }
                }
                Section("Protected folders (optional)") {
                    Text("Full Disk Access is needed only for scripts that access protected folders. Enable it when your workflow needs that access.")
                        .foregroundStyle(.secondary)
                    DisclosureGroup("Full Disk Access (FDA)") { FullDiskAccessGuideView() }
                }
            }
            .formStyle(.grouped)
            Divider()
            HStack {
                Button("Skip for Now") { state.completeOnboarding(skipped: true); onDismiss() }
                Spacer()
                Button("Finish Setup") { state.completeOnboarding(); onDismiss() }
                    .disabled(!state.finderSetupVerified)
                    .keyboardShortcut(.defaultAction)
            }.padding()
        }
        .frame(width: 580, height: 680)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            state.refreshLogs(); state.refreshExtensionStatus()
        }
        .onReceive(DistributedNotificationCenter.default().publisher(for: WorkflowFeedback.executionChanged)) { _ in
            state.refreshLogs()
        }
    }
}
