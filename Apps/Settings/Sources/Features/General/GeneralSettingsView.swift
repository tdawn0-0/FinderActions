import SwiftUI

struct GeneralSettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.openURL) private var openURL
    @State private var showResetConfirm = false

    var body: some View {
        @Bindable var state = state

        Form {
            Section("Preferences") {
                Toggle("Show system notifications upon execution completion", isOn: $state.notificationsEnabled)
            }

            Section("Storage & Configurations") {
                PathRow(
                    title: "Manifest Config",
                    path: state.store.fileURL.path,
                    buttonTitle: "Reveal in Finder"
                ) {
                    openURL(state.store.fileURL.deletingLastPathComponent())
                }
                PathRow(
                    title: "Scripts Folder",
                    path: state.store.actionsDirectoryURL.path,
                    buttonTitle: "Open Folder"
                ) {
                    openURL(state.store.actionsDirectoryURL)
                }
            }

            Section("Factory Reset") {
                LabeledContent {
                    Button("Reset to Defaults", role: .destructive) {
                        showResetConfirm = true
                    }
                } label: {
                    Text("Reset actions and application configurations back to the initial defaults.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Privacy & Offline") {
                Label(
                    "FinderActions is completely offline. No telemetry, no accounts, and no data leaves your device.",
                    systemImage: "hand.raised.fill"
                )
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
        .onChange(of: state.notificationsEnabled) { _, _ in state.persistSettings() }
        .alert("Reset all actions to default?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) { state.seedDefaults() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will restore the default manifest and bundled scripts.")
        }
    }
}

private struct PathRow: View {
    let title: LocalizedStringKey
    let path: String
    let buttonTitle: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        LabeledContent {
            Button(buttonTitle, action: action)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
        }
    }
}
