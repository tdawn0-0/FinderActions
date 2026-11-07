import SwiftUI
import FinderActionsCore

struct ApplicationsSettingsView: View {
    @Environment(AppState.self) private var state

    private var terminalChoices: [ExternalApplication] {
        var choices = ExternalApplicationCatalog.terminals
        if !choices.contains(where: { $0.bundleId == state.openWithSettings.terminal.bundleId }) {
            choices.append(state.openWithSettings.terminal)
        }
        return choices
    }

    private var editors: [ExternalApplication] {
        ExternalApplicationCatalog.editors + state.customEditors
    }

    var body: some View {
        Form {
            terminalSection
            editorsSection
        }
        .formStyle(.grouped)
        .navigationTitle("Applications")
    }

    private var terminalSection: some View {
        Section("Open in Terminal") {
            Picker("Terminal", selection: terminalSelection) {
                ForEach(terminalChoices) { terminal in
                    if state.isApplicationInstalled(terminal) {
                        Text(terminal.name).tag(terminal.bundleId)
                    } else {
                        Text("\(terminal.name) (\(String(localized: "Not Installed")))")
                            .tag(terminal.bundleId)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Choose Application…") {
                    state.chooseApplications(kind: .terminal)
                }
                .controlSize(.small)
            }
        }
    }

    private var editorsSection: some View {
        Section("Open with Editor") {
            ForEach(editors) { editor in
                EditorRow(
                    application: editor,
                    icon: state.applicationIcon(for: editor),
                    isInstalled: state.isApplicationInstalled(editor),
                    isOn: Binding(
                        get: { state.isEditorEnabled(editor) },
                        set: { state.setEditor(editor, enabled: $0) }
                    )
                )
            }

            HStack {
                Spacer()
                Button("Add Application…") {
                    state.chooseApplications(kind: .editor)
                }
                .controlSize(.small)
            }
        }
    }

    private var terminalSelection: Binding<String> {
        Binding(
            get: { state.openWithSettings.terminal.bundleId },
            set: { bundleId in
                if let terminal = terminalChoices.first(where: { $0.bundleId == bundleId }) {
                    state.selectTerminal(terminal)
                }
            }
        )
    }
}

private struct EditorRow: View {
    let application: ExternalApplication
    let icon: NSImage?
    let isInstalled: Bool
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 22, height: 22)
                    .accessibilityHidden(true)
            } else {
                Image(systemName: application.sfSymbol)
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .accessibilityHidden(true)
            }

            Text(application.name)
                .foregroundStyle(isInstalled ? .primary : .secondary)

            Spacer()

            if !isInstalled {
                Text("Not Installed")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Toggle(application.name, isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .accessibilityLabel(application.name)
        }
    }
}
