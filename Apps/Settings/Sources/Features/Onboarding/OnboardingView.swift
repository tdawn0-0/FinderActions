import SwiftUI
import FinderActionsCore

struct OnboardingView: View {
    @Environment(AppState.self) private var state
    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }

    private var terminalChoices: [ExternalApplication] {
        var choices = ExternalApplicationCatalog.terminals
        if !choices.contains(where: { $0.bundleId == state.openWithSettings.terminal.bundleId }) {
            choices.append(state.openWithSettings.terminal)
        }
        return choices
    }

    var body: some View {
        Form {
                Section("1. Applications") {
                    Picker("Terminal", selection: Binding(
                        get: { state.openWithSettings.terminal.bundleId },
                        set: { bundleId in
                            if let terminal = terminalChoices.first(where: { $0.bundleId == bundleId }) {
                                state.selectTerminal(terminal)
                            }
                        }
                    )) {
                        ForEach(terminalChoices) { terminal in
                            Text(terminal.name).tag(terminal.bundleId)
                        }
                    }

                    LabeledContent("Editors") {
                        HStack(spacing: 8) {
                            Text(state.openWithSettings.editors.isEmpty
                                 ? String(localized: "None")
                                 : state.openWithSettings.editors.map(\.name).joined(separator: ", "))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Button("Add…") { state.chooseApplications(kind: .editor) }
                                .controlSize(.small)
                        }
                    }
                }

                Section("2. Finder Extension") {
                    LabeledContent("Status") {
                        HStack(spacing: 8) {
                            Text(state.extensionRegistration.message)
                                .foregroundStyle(.secondary)
                            Button("Extension Settings…") { state.openExtensionSettings() }
                                .controlSize(.small)
                        }
                    }
                }

                Section("3. Verify Copy Path in Finder") {
                    LabeledContent {
                        Button("Open Finder") { state.openActionsDirectory() }
                            .controlSize(.small)
                    } label: {
                        Label(
                            state.finderSetupVerified ? "Verified" : "Waiting for Copy Path",
                            systemImage: state.finderSetupVerified ? "checkmark.circle.fill" : "circle.dotted"
                        )
                        .foregroundStyle(state.finderSetupVerified ? .green : .primary)
                    }
                }

                Section("Protected Folders") {
                    LabeledContent("Full Disk Access") {
                        Button("Open Settings…") { FullDiskAccessSettings.openSystemSettings() }
                            .controlSize(.small)
                    }
                }
        }
        .formStyle(.grouped)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Button("Skip") {
                        state.completeOnboarding(skipped: true)
                        onDismiss()
                    }
                    Spacer()
                    Button("Done") {
                        state.completeOnboarding()
                        onDismiss()
                    }
                    .disabled(!state.finderSetupVerified)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(.bar)
        }
        .frame(width: 480, height: 520)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            state.refreshLogs()
            state.refreshExtensionStatus()
        }
        .onReceive(DistributedNotificationCenter.default().publisher(for: WorkflowFeedback.executionChanged)) { _ in
            state.refreshLogs()
        }
    }
}
