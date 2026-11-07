import AppKit
import SwiftUI

struct GeneralSettingsView: View {
    private static let repositoryURL = URL(string: "https://github.com/tdawn0-0/FinderActions")!

    @Environment(AppState.self) private var state
    @Environment(\.openURL) private var openURL
    @State private var showResetConfirm = false

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "—"
        guard let build = info?["CFBundleVersion"] as? String else { return short }
        return "\(short) (\(build))"
    }

    var body: some View {
        @Bindable var bindableState = state

        Form {
            Section("Behavior") {
                Picker("Notifications", selection: $bindableState.notificationMode) {
                    ForEach(ExecutionNotificationMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
            }

            Section("Storage") {
                LabeledContent("Configuration") {
                    HStack(spacing: 8) {
                        Text(state.store.fileURL.lastPathComponent)
                            .font(.callout.monospaced())
                            .foregroundStyle(.secondary)
                            .help(state.store.fileURL.path)
                        Button("Show in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([state.store.fileURL])
                        }
                        .controlSize(.small)
                    }
                }

                LabeledContent("Scripts") {
                    HStack(spacing: 8) {
                        Text(state.store.actionsDirectoryURL.lastPathComponent)
                            .font(.callout.monospaced())
                            .foregroundStyle(.secondary)
                            .help(state.store.actionsDirectoryURL.path)
                        Button("Open") {
                            openURL(state.store.actionsDirectoryURL)
                        }
                        .controlSize(.small)
                    }
                }

                LabeledContent("Defaults") {
                    Button("Reset…", role: .destructive) {
                        showResetConfirm = true
                    }
                    .controlSize(.small)
                }
            }

            Section("About") {
                LabeledContent("Version", value: version)
                LabeledContent("License", value: "MIT")
                LabeledContent("Source") {
                    Link("GitHub", destination: Self.repositoryURL)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
        .onChange(of: state.notificationMode) { _, _ in state.persistSettings() }
        .alert("Reset Defaults?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) { state.seedDefaults() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
