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
            return log.actionId.localizedCaseInsensitiveContains(searchText)
                || log.summary.localizedCaseInsensitiveContains(searchText)
                || (log.stderrTail?.localizedCaseInsensitiveContains(searchText) ?? false)
                || log.paths.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        content
            .navigationTitle("Activity Logs")
            .searchable(text: $searchText, placement: .toolbar, prompt: "Search logs…")
            .toolbar {
                ToolbarItem {
                    Picker("Status Filter", selection: $filter) {
                        ForEach(LogFilter.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                ToolbarItem {
                    Button(role: .destructive) {
                        state.clearLogs()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .help("Clear")
                    .disabled(state.logs.isEmpty)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if state.logs.isEmpty {
            ContentUnavailableView(
                "No execution logs yet",
                systemImage: "tray",
                description: Text("Actions run from Finder will be recorded here.")
            )
        } else if filteredLogs.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            List(filteredLogs) { LogRow(log: $0) }
        }
    }
}

private struct LogRow: View {
    let log: ExecLogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: log.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(log.success ? .green : .red)
                .imageScale(.large)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(log.actionId).fontWeight(.medium)
                    Spacer()
                    timestamp
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(log.summary)
                    .foregroundStyle(.secondary)

                if let stderrTail = log.stderrTail, !stderrTail.isEmpty {
                    Text(stderrTail)
                        .font(.caption.monospaced())
                        .foregroundStyle(.red)
                        .lineLimit(6)
                        .textSelection(.enabled)
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
        .padding(.vertical, 4)
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
