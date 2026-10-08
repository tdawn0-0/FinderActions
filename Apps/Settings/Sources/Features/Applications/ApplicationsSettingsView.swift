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
        Section {
            Picker("Default Terminal", selection: terminalSelection) {
                ForEach(terminalChoices) { terminal in
                    if state.isApplicationInstalled(terminal) {
                        Text(terminal.name).tag(terminal.bundleId)
                    } else {
                        Text("\(terminal.name) (\(String(localized: "Not Installed")))")
                            .tag(terminal.bundleId)
                    }
                }
            }

            Button("Choose Other Terminal…") {
                state.chooseApplications(kind: .terminal)
            }
            .buttonStyle(.link)
        } header: {
            Text("Terminal")
        } footer: {
            Text("Finder always renders one single “Open in Terminal” menu item. Selected terminal will launch with the working directory.")
        }
    }

    private var editorsSection: some View {
        Section {
            ForEach(editors) { editor in
                EditorRow(
                    application: editor,
                    isInstalled: state.isApplicationInstalled(editor),
                    isOn: Binding(
                        get: { state.isEditorEnabled(editor) },
                        set: { state.setEditor(editor, enabled: $0) }
                    )
                )
            }

            Button("Add Custom Editor…") {
                state.chooseApplications(kind: .editor)
            }
            .buttonStyle(.link)
        } header: {
            Text("Code Editors & IDEs")
        } footer: {
            Text("Each enabled editor creates its own dedicated menu entry in Finder.")
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
    let isInstalled: Bool
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label {
                VStack(alignment: .leading, spacing: 1) {
                    Text(application.name)
                    if isInstalled {
                        Text(application.bundleId)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not Installed")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            } icon: {
                Image(systemName: application.sfSymbol)
                    .foregroundStyle(isOn ? Color.accentColor : .secondary)
            }
        }
        .toggleStyle(.switch)
    }
}
