import SwiftUI
import FinderActionsCore

struct LogsSettingsView: View {
    @Environment(AppState.self) private var state
    @State private var filter: LogFilter = .all
    @State private var searchText = ""

    private enum LogFilter: CaseIterable {
        case all, success, failed

        var title: LocalizedStringKey {
            switch self {
            case .all: "All"
            case .success: "Success"
            case .failed: "Failed"
            }
        }
    }

    private var filteredLogs: [ExecLogEntry] {
        state.logs.filter { log in
            switch filter {
            case .all: break
            case .success: if !log.success { return false }
            case .failed: if log.success { return false }
            }
            guard !searchText.isEmpty else { return true }
            return (log.actionName?.localizedCaseInsensitiveContains(searchText) ?? false)
                || log.actionId.localizedCaseInsensitiveContains(searchText)
                || log.summary.localizedCaseInsensitiveContains(searchText)
                || (log.stderrTail?.localizedCaseInsensitiveContains(searchText) ?? false)
                || log.paths.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        content
            .navigationTitle("Logs")
            .searchable(text: $searchText, placement: .toolbar, prompt: "Filter")
            .onAppear { state.refreshLogs(); searchText = state.selectedActionID ?? "" }
            .onChange(of: state.selectedActionID) { _, id in searchText = id ?? "" }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                state.refreshLogs()
            }
            .onReceive(DistributedNotificationCenter.default().publisher(for: WorkflowFeedback.executionChanged)) { _ in
                state.refreshLogs()
            }
            .toolbar {
                ToolbarItem {
                    Picker("Filter", selection: $filter) {
                        ForEach(LogFilter.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier(SettingsAccessibilityID.logsFilter)
                }
                ToolbarItem {
                    Button { state.refreshLogs() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                }
                ToolbarItem {
                    Button(role: .destructive) {
                        state.clearLogs()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(state.logs.isEmpty)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if state.logs.isEmpty {
            ContentUnavailableView("No Activity", systemImage: "clock")
        } else if filteredLogs.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            List(filteredLogs) { LogRow(log: $0) }
        }
    }
}

private struct LogRow: View {
    @Environment(AppState.self) private var state
    let log: ExecLogEntry

    private var isCustomAction: Bool {
        state.manifest.actions.contains { $0.id == log.actionId }
    }

    private var isOpenWithAction: Bool {
        log.actionId == OpenWithActions.terminalActionId || log.actionId.hasPrefix(OpenWithActions.editorActionPrefix)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: log.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(log.success ? .green : .red)
                .padding(.top, 2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(log.actionName ?? log.actionId)
                        .fontWeight(.medium)

                    if log.source == .test {
                        Text("Test")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(.quaternary, in: Capsule())
                    }

                    Spacer()

                    if let duration = log.durationSeconds {
                        Text("\(duration, specifier: "%.1f")s")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }

                    timestamp
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)

                    if isCustomAction || isOpenWithAction {
                        Button {
                            if isCustomAction {
                                state.navigate(to: .actions, actionID: log.actionId)
                            } else {
                                state.navigate(to: .applications)
                            }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                        .accessibilityLabel("Configure Action")
                    }
                }

                if !log.summary.isEmpty {
                    Text(log.summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                if let stderrTail = log.stderrTail, !stderrTail.isEmpty {
                    Text(stderrTail)
                        .font(.caption.monospaced())
                        .foregroundStyle(.red)
                        .lineLimit(6)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                }

                if !log.paths.isEmpty {
                    Text(log.paths.joined(separator: "\n"))
                        .font(.caption.monospaced())
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
            }
        }
        .padding(.vertical, 3)
    }

    @ViewBuilder
    private var timestamp: some View {
        if let date = try? Date(log.timestamp, strategy: .iso8601) {
            Text(date, format: .dateTime.month().day().hour().minute().second())
        } else {
            Text(log.timestamp)
        }
    }
}
