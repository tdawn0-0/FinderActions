import SwiftUI
import AppKit
import FinderActionsCore

struct LiveTestConsole: View {
    @Environment(AppState.self) private var state
    let action: ActionDefinition

    private var session: LiveTestSession { state.liveTest }

    private var validationKey: String {
        ((try? JSONCoding.encodeToString(action)) ?? action.id)
            + session.paths.joined(separator: "\u{0}")
            + (session.container ?? "")
    }

    var body: some View {
        Section("Test") {
            inputsBlock
            directoryRow

            if let error = session.validationError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            if let preview = session.preview {
                HStack {
                    Label(
                        String(localized: String.LocalizationValue(preview.visibilityReason)),
                        systemImage: preview.visible ? "eye" : "eye.slash"
                    )
                    .font(.callout)
                    .foregroundStyle(preview.visible ? Color.secondary : Color.orange)
                    Spacer()
                }

                DisclosureGroup("Command") {
                    Text(preview.description)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
            }

            HStack {
                Button {
                    Task { await session.run(action: action, executor: state.executor, record: state.recordLog) }
                } label: {
                    Label(session.isRunning ? "Running…" : "Run on Inputs", systemImage: "play.fill")
                }
                .disabled(session.preview == nil || session.isRunning || session.isValidating)
                .accessibilityIdentifier(SettingsAccessibilityID.liveTestRun)

                if session.isRunning || session.isValidating {
                    ProgressView()
                        .controlSize(.small)
                }
                Spacer()
            }

            if session.resultActionId == action.id, let result = session.result {
                resultBlock(result)
            }
        }
        .task(id: validationKey) {
            await session.validate(action: action, store: state.store)
        }
    }

    private var inputsBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Inputs")
                Spacer()
                if !session.paths.isEmpty {
                    Button("Clear") { session.paths = [] }
                        .controlSize(.small)
                }
                Button("Add…") { chooseInputs() }
                    .controlSize(.small)
            }

            if session.paths.isEmpty {
                Button {
                    chooseInputs()
                } label: {
                    HStack {
                        Image(systemName: "plus.rectangle.on.folder")
                        Text("Drop or Choose Files…")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 4) {
                    ForEach(Array(session.paths.enumerated()), id: \.offset) { index, path in
                        HStack(spacing: 6) {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                                .resizable()
                                .frame(width: 16, height: 16)
                                .accessibilityHidden(true)
                            Text(URL(fileURLWithPath: path).lastPathComponent)
                                .font(.callout.monospaced())
                                .lineLimit(1)
                                .help(path)
                            Spacer()
                            Button {
                                session.paths.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove Input")
                        }
                    }
                }
                .padding(8)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard !session.isRunning, urls.allSatisfy(\.isFileURL) else { return false }
            session.paths = urls.map(\.path)
            return true
        }
    }

    private var directoryRow: some View {
        let activeDirectory = session.container ?? session.preview?.workingDirectory ?? "—"
        return LabeledContent("Directory") {
            HStack(spacing: 6) {
                Text(URL(fileURLWithPath: activeDirectory).lastPathComponent.isEmpty ? activeDirectory : URL(fileURLWithPath: activeDirectory).lastPathComponent)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .help(activeDirectory)
                if session.container != nil {
                    Button {
                        session.container = nil
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .controlSize(.small)
                    .accessibilityLabel("Reset Directory")
                }
                Button("Choose…") { chooseContainer() }
                    .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private func resultBlock(_ result: ExecResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(result.success ? .green : .red)
                Text(result.summary)
                    .font(.callout)
                    .textSelection(.enabled)
            }
            if !result.stdout.isEmpty { output("stdout", result.stdout) }
            if !result.stderr.isEmpty { output("stderr", result.stderr) }
        }
    }

    private func output(_ title: String, _ text: String) -> some View {
        DisclosureGroup(title) {
            ScrollView {
                Text(text)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 140)
        }
    }

    private func chooseInputs() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK {
            session.paths = panel.urls.map(\.path)
        }
    }

    private func chooseContainer() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            session.container = panel.url?.path
        }
    }
}
