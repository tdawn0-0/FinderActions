import SwiftUI
import AppKit
import FinderActionsCore

struct LiveTestConsole: View {
    @Environment(AppState.self) private var state
    let action: ActionDefinition
    private var session: LiveTestSession { state.liveTest }
    private var validationKey: String {
        ((try? JSONCoding.encodeToString(action)) ?? action.id)
            + session.paths.joined(separator: "\u{0}") + (session.container ?? "")
    }
    var body: some View {
        Section {
            Text("Runs the script for real and can change your files.").foregroundStyle(.secondary)
            HStack {
                Button("Choose Files or Folders…") { chooseInputs() }
                Button("Clear Selection") { session.paths = [] }
            }
            Text("Drop files or folders here. All selected files must match the menu rule.")
                .font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                .dropDestination(for: URL.self) { urls, _ in
                    guard !session.isRunning, urls.allSatisfy(\.isFileURL) else { return false }
                    session.paths = urls.map(\.path); return true
                }
            ForEach(Array(session.paths.enumerated()), id: \.offset) { index, path in
                HStack {
                    Text(path).font(.caption.monospaced()).textSelection(.enabled)
                    Spacer()
                    Button { session.paths.remove(at: index) } label: { Image(systemName: "minus.circle") }
                        .accessibilityLabel("Remove Input")
                }
            }
            HStack {
                Button("Choose Working Directory…") { chooseContainer() }
                if session.container != nil { Button("Use Selection Context") { session.container = nil } }
            }
            if let container = session.container { Text(container).font(.caption.monospaced()).textSelection(.enabled) }
            if session.isValidating { ProgressView("Validating…") }
            if let error = session.validationError { Text(error).foregroundStyle(.red).textSelection(.enabled) }
            if let preview = session.preview {
                LabeledContent("Working Directory") { Text(preview.workingDirectory).textSelection(.enabled) }
                Label(preview.visible ? "Visible in Finder for these inputs" : "Hidden in Finder for these inputs; explicit testing is allowed",
                      systemImage: preview.visible ? "eye" : "eye.slash")
                    .font(.caption)
                Text(String(localized: String.LocalizationValue(preview.visibilityReason))).font(.caption).foregroundStyle(.secondary)
                DisclosureGroup("Execution Preview") {
                    Text(preview.description).font(.caption.monospaced()).textSelection(.enabled)
                }
            }
            Button {
                Task { await session.run(action: action, executor: state.executor, record: state.recordLog) }
            } label: {
                Label(session.isRunning ? "Running…" : "Run Test", systemImage: "play.fill")
            }
            .disabled(session.preview == nil || session.isRunning || session.isValidating)
            if session.isRunning { ProgressView(); Text("Keep Settings open until the test finishes.").font(.caption) }
            if session.resultActionId == action.id, let result = session.result {
                Label(result.success ? "Test succeeded" : "Test failed", systemImage: result.success ? "checkmark.circle" : "xmark.circle")
                Text(result.summary).textSelection(.enabled)
                if !result.stdout.isEmpty { output("STDOUT", result.stdout) }
                if !result.stderr.isEmpty { output("STDERR", result.stderr) }
            }
        } header: { Text("Live Test Console") }
        .task(id: validationKey) { await session.validate(action: action, store: state.store) }
    }
    private func output(_ title: String, _ text: String) -> some View {
        DisclosureGroup(title) { ScrollView { Text(text).font(.caption.monospaced()).textSelection(.enabled) }.frame(maxHeight: 160) }
    }
    private func chooseInputs() {
        let panel = NSOpenPanel(); panel.canChooseFiles = true; panel.canChooseDirectories = true; panel.allowsMultipleSelection = true
        if panel.runModal() == .OK { session.paths = panel.urls.map(\.path) }
    }
    private func chooseContainer() {
        let panel = NSOpenPanel(); panel.canChooseFiles = false; panel.canChooseDirectories = true
        if panel.runModal() == .OK { session.container = panel.url?.path }
    }
}
