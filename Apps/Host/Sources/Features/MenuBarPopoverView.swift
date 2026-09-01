import SwiftUI
import AppKit
import FinderActionsCore

struct MenuBarPopoverView: View {
    @Environment(AppState.self) private var state
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("FinderActions")
                    .font(.headline)
                Spacer()
                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .help("Open Settings")
            }
            .padding(12)

            Picker("", selection: $selectedTab) {
                Text("Actions").tag(0)
                Text("Logs").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if selectedTab == 0 {
                actionsList
            } else {
                logsList
            }

            Divider()
            HStack {
                SettingsLink {
                    Text("Settings…")
                }
                Spacer()
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
            .padding(10)
            .font(.caption)
        }
        .frame(width: 320, height: 420)
    }

    private var actionsList: some View {
        List {
            ForEach(state.manifest.actions.sorted(by: { $0.sortIndex < $1.sortIndex })) { action in
                HStack {
                    Image(systemName: action.icon?.sfSymbol ?? "bolt")
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(action.name)
                            .font(.body)
                        if let sub = action.subtitle {
                            Text(sub)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { action.enabled },
                            set: { state.setEnabled(actionId: action.id, enabled: $0) }
                        )
                    )
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
            }
        }
        .listStyle(.plain)
    }

    private var logsList: some View {
        List {
            if state.logs.isEmpty {
                ContentUnavailableView(
                    "No executions yet",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Run an action from Finder to see logs here.")
                )
            } else {
                ForEach(state.logs) { log in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Image(systemName: log.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(log.success ? .green : .red)
                            Text(log.actionId)
                                .fontWeight(.medium)
                            Spacer()
                            Text(log.timestamp)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text(log.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}
