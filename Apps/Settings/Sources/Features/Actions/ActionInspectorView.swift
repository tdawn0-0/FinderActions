import SwiftUI
import FinderActionsCore

/// Editor for one action, shown in the trailing inspector.
struct ActionInspectorView: View {
    @Environment(AppState.self) private var state
    @Binding var action: ActionDefinition
    @State private var showSymbolPicker = false
    @State private var isRunningTest = false
    @State private var testResult: ExecResult?

    private static let commonSymbols = [
        "bolt", "bolt.fill", "terminal", "terminal.fill",
        "doc.on.doc", "doc.plaintext", "folder", "link",
        "gearshape", "hammer", "wrench.and.screwdriver", "play.fill",
        "scissors", "trash", "arrow.up.right.square", "shippingbox",
    ]

    /// Only types the executor can run, plus the action's current type so a
    /// legacy value is displayed rather than silently replaced.
    private var selectableTypes: [ActionType] {
        ActionType.userAssignable + (ActionType.userAssignable.contains(action.type) ? [] : [action.type])
    }

    var body: some View {
        Form {
            headerSection
            displaySection
            executionSection
            testSection
        }
        .formStyle(.grouped)
    }

    // MARK: Sections

    private var headerSection: some View {
        Section {
            HStack(spacing: 12) {
                Button {
                    showSymbolPicker.toggle()
                } label: {
                    ActionIconTile(symbol: action.icon?.sfSymbol, size: 44)
                }
                .buttonStyle(.plain)
                .help("Quick Choose Symbol")
                .popover(isPresented: $showSymbolPicker, arrowEdge: .bottom) { symbolPicker }

                VStack(alignment: .leading, spacing: 2) {
                    TextField("Action Name", text: $action.name, prompt: Text("Action Name"))
                        .labelsHidden()
                        .textFieldStyle(.plain)
                        .font(.title3.weight(.semibold))
                    TextField("Subtitle (Optional)", text: optional(\.subtitle), prompt: Text("Subtitle (Optional)"))
                        .labelsHidden()
                        .textFieldStyle(.plain)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)

            Toggle("Enabled", isOn: $action.enabled)
        }
    }

    private var displaySection: some View {
        Section("Display & Matching") {
            Picker("Show When", selection: $action.showWhen) {
                ForEach(ShowWhen.allCases, id: \.self) { Text($0.displayName).tag($0) }
            }

            TextField("Menu Group", text: optional(\.group), prompt: Text("e.g. Develop, Quick Actions"))

            TextField("SF Symbol", text: symbolBinding, prompt: Text(verbatim: "doc.on.clipboard"))
        }
    }

    private var executionSection: some View {
        Section("Execution Logic") {
            Picker("Action Type", selection: $action.type) {
                ForEach(selectableTypes, id: \.self) { Text($0.displayName).tag($0) }
            }

            switch action.type {
            case .shell: shellEditor
            case .application: applicationEditor
            case .terminal: terminalNote
            case .appleScript: appleScriptEditor
            case .builtin:
                LabeledContent("Built-in Identifier") {
                    Text(action.builtinId ?? "—").foregroundStyle(.secondary)
                }
            }
        }
    }

    private var testSection: some View {
        Section {
            HStack(spacing: 10) {
                Button {
                    Task { await runLiveTest() }
                } label: {
                    Label(isRunningTest ? "Running…" : "Run Test", systemImage: "play.fill")
                }
                .disabled(isRunningTest)

                if isRunningTest {
                    ProgressView().controlSize(.small)
                }

                Spacer()

                if let result = testResult {
                    Label(
                        result.success
                            ? "Success (\(String(result.exitCode)))"
                            : "Failed (\(String(result.exitCode)))",
                        systemImage: result.success ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )
                    .foregroundStyle(result.success ? .green : .red)
                }
            }

            if let result = testResult {
                Text(result.summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                if !result.stdout.isEmpty {
                    OutputBlock(title: "STDOUT", text: result.stdout, tint: .secondary)
                }
                if !result.stderr.isEmpty {
                    OutputBlock(title: "STDERR", text: result.stderr, tint: .red)
                }
            }
        } header: {
            Text("Live Test Console")
        } footer: {
            Text("Runs against user home directory.")
        }
    }

    // MARK: Type-specific editors

    @ViewBuilder
    private var shellEditor: some View {
        TextField(
            "Interpreter",
            text: shellBinding(\.interpreter, default: "/bin/zsh"),
            prompt: Text(verbatim: "/bin/zsh")
        )
        TextField(
            "Script File",
            text: shellBinding(\.scriptFile, default: ""),
            prompt: Text(verbatim: "copy-path.zsh")
        )
        Button("Open Scripts Folder") { state.openActionsDirectory() }
            .buttonStyle(.link)

        VStack(alignment: .leading, spacing: 6) {
            Text("Or Inline Script:")
                .font(.callout)
                .foregroundStyle(.secondary)
            ScriptEditor(text: Binding(
                get: { action.shell?.scriptInline ?? "" },
                set: {
                    if action.shell == nil { action.shell = ShellConfig() }
                    action.shell?.scriptInline = $0.isEmpty ? nil : $0
                }
            ))
        }
    }

    @ViewBuilder
    private var applicationEditor: some View {
        TextField(
            "Bundle ID",
            text: Binding(
                get: { action.application?.bundleId ?? "" },
                set: {
                    action.application = ApplicationConfig(
                        bundleId: $0,
                        pathFallback: action.application?.pathFallback
                    )
                }
            ),
            prompt: Text(verbatim: "com.example.app")
        )
        TextField(
            "Fallback Path",
            text: Binding(
                get: { action.application?.pathFallback ?? "" },
                set: {
                    action.application = ApplicationConfig(
                        bundleId: action.application?.bundleId ?? "",
                        pathFallback: $0.isEmpty ? nil : $0
                    )
                }
            ),
            prompt: Text(verbatim: "/Applications/App.app")
        )
    }

    private var terminalNote: some View {
        Label("Configure default terminal in the Applications tab.", systemImage: "info.circle")
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var appleScriptEditor: some View {
        TextField(
            "Script File",
            text: Binding(
                get: { action.appleScript?.scriptFile ?? "" },
                set: {
                    if action.appleScript == nil { action.appleScript = AppleScriptConfig() }
                    action.appleScript?.scriptFile = $0
                }
            ),
            prompt: Text(verbatim: "script.applescript")
        )

        VStack(alignment: .leading, spacing: 6) {
            Text("Or Inline Script:")
                .font(.callout)
                .foregroundStyle(.secondary)
            ScriptEditor(text: Binding(
                get: { action.appleScript?.scriptInline ?? "" },
                set: {
                    if action.appleScript == nil { action.appleScript = AppleScriptConfig() }
                    action.appleScript?.scriptInline = $0.isEmpty ? nil : $0
                }
            ))
        }
    }

    // MARK: Symbol picker

    private var symbolPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Choose Symbol")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 8), count: 4), spacing: 8) {
                ForEach(Self.commonSymbols, id: \.self) { symbol in
                    Button {
                        symbolBinding.wrappedValue = symbol
                        showSymbolPicker = false
                    } label: {
                        Image(systemName: symbol)
                            .frame(width: 36, height: 36)
                            .background(
                                action.icon?.sfSymbol == symbol ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
    }

    // MARK: Bindings

    private func optional(_ keyPath: WritableKeyPath<ActionDefinition, String?>) -> Binding<String> {
        Binding(
            get: { action[keyPath: keyPath] ?? "" },
            set: { action[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
        )
    }

    private var symbolBinding: Binding<String> {
        Binding(
            get: { action.icon?.sfSymbol ?? "" },
            set: {
                if action.icon == nil { action.icon = ActionIcon() }
                action.icon?.sfSymbol = $0.isEmpty ? nil : $0
            }
        )
    }

    private func shellBinding(_ keyPath: WritableKeyPath<ShellConfig, String>, default fallback: String) -> Binding<String> {
        Binding(
            get: { action.shell?[keyPath: keyPath] ?? fallback },
            set: {
                if action.shell == nil { action.shell = ShellConfig() }
                action.shell?[keyPath: keyPath] = $0
            }
        )
    }

    private func shellBinding(_ keyPath: WritableKeyPath<ShellConfig, String?>, default fallback: String) -> Binding<String> {
        Binding(
            get: { action.shell?[keyPath: keyPath] ?? fallback },
            set: {
                if action.shell == nil { action.shell = ShellConfig() }
                action.shell?[keyPath: keyPath] = $0
            }
        )
    }

    // MARK: Live test

    private func runLiveTest() async {
        isRunningTest = true
        defer { isRunningTest = false }

        let currentAction = action
        let executor = state.executor
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        let result = await Task.detached {
            executor.execute(action: currentAction, paths: [homePath], containerPath: homePath)
        }.value

        state.recordLog(ExecLogEntry(
            actionId: currentAction.id,
            success: result.success,
            summary: "Test Run: \(result.summary)",
            paths: [homePath],
            stderrTail: OutputTail.tail(result.stderr)
        ))
        testResult = result
    }
}

// MARK: - Components

private struct ScriptEditor: View {
    @Binding var text: String

    var body: some View {
        TextEditor(text: $text)
            .font(.body.monospaced())
            .autocorrectionDisabled()
            .scrollContentBackground(.hidden)
            .padding(6)
            .frame(minHeight: 140)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct OutputBlock: View {
    let title: String
    let text: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            ScrollView {
                Text(text)
                    .font(.callout.monospaced())
                    .foregroundStyle(tint == .secondary ? .primary : tint)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(maxHeight: 120)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}
