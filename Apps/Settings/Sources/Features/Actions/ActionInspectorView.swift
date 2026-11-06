import SwiftUI
import FinderActionsCore

/// Editor for one action, shown in the trailing inspector.
struct ActionInspectorView: View {
    @Environment(AppState.self) private var state
    @Binding var action: ActionDefinition
    @State private var showSymbolPicker = false
    @State private var extensionText = ""
    @State private var shellFileMode = false
    @State private var appleScriptFileMode = false

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
            LiveTestConsole(action: action)
        }
        .formStyle(.grouped)
        .onAppear {
            extensionText = action.extRules?.pathExtensions.joined(separator: ", ") ?? ""
            shellFileMode = !(action.shell?.scriptFile ?? "").isEmpty
            appleScriptFileMode = !(action.appleScript?.scriptFile ?? "").isEmpty
        }
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

            Toggle("Enabled", isOn: Binding(get: { action.enabled }, set: { enabled in
                if !enabled || ActionAuthoring.validationError(action) == nil { action.enabled = enabled }
            }))
            if let error = ActionAuthoring.validationError(action) { Text(String(localized: String.LocalizationValue(error))).font(.caption).foregroundStyle(.orange) }
            if !action.enabled { Text("Draft — enable when ready to use in Finder.").font(.caption).foregroundStyle(.secondary) }
        }
    }

    private var displaySection: some View {
        Section("Display & Matching") {
            Picker("Show When", selection: $action.showWhen) {
                ForEach(ShowWhen.allCases, id: \.self) { Text($0.displayName).tag($0) }
            }

            TextField("File Extensions", text: Binding(
                get: { extensionText },
                set: { value in
                    extensionText = value
                    var rules = action.extRules ?? ExtRules()
                    rules.pathExtensions = ActionAuthoring.normalizedExtensions(value)
                    action.extRules = rules
                }
            ), prompt: Text("e.g. png, jpg"))
            Picker("Input Kind", selection: Binding(
                get: { action.extRules?.foldersOnly == true ? "folders" : action.extRules?.filesOnly == true ? "files" : "any" },
                set: { value in
                    var rules = action.extRules ?? ExtRules()
                    rules.foldersOnly = value == "folders"; rules.filesOnly = value == "files"
                    action.extRules = rules
                }
            )) {
                Text("Files and Folders").tag("any")
                Text("Files Only").tag("files")
                Text("Folders Only").tag("folders")
            }
            LabeledContent("Rule Summary", value: ruleSummary)
            Text("Every selected file must match. Show When controls selection count independently.")
                .font(.caption).foregroundStyle(.secondary)
            TextField("Menu Group", text: optional(\.group), prompt: Text("e.g. Develop, Quick Actions"))

            TextField("SF Symbol", text: symbolBinding, prompt: Text(verbatim: "doc.on.clipboard"))
        }
    }

    private var ruleSummary: String {
        var parts = [String(localized: action.showWhen.displayName)]
        if let rules = action.extRules {
            if rules.filesOnly { parts.append(String(localized: "Files Only")) }
            if rules.foldersOnly { parts.append(String(localized: "Folders Only")) }
            if !rules.pathExtensions.isEmpty { parts.append(rules.pathExtensions.map { "." + $0 }.joined(separator: ", ")) }
        }
        return parts.joined(separator: " · ")
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

    // MARK: Type-specific editors

    @ViewBuilder
    private var shellEditor: some View {
        TextField("Interpreter", text: shellBinding(\.interpreter, default: "/bin/zsh"))
        Toggle("Use External Script File", isOn: $shellFileMode)
            .onChange(of: shellFileMode) { _, file in
                if !file { ActionAuthoring.useInline(&action) }
                else if (action.shell?.scriptFile ?? "").isEmpty {
                    chooseScript(appleScript: false)
                    if (action.shell?.scriptFile ?? "").isEmpty { shellFileMode = false }
                }
            }
        if shellFileMode {
            Button("Choose Script File…") { chooseScript(appleScript: false) }
            if let file = action.shell?.scriptFile, !file.isEmpty {
                Text(state.store.resolveScriptPath(file).path).font(.caption).textSelection(.enabled)
                Button("Open in Editor") { NSWorkspace.shared.open(state.store.resolveScriptPath(file)) }
            }
            Text("The external file takes priority. Your inline draft is preserved.").font(.caption)
        } else {
            ScriptEditor(text: Binding(
                get: { action.shell?.scriptInline ?? "" },
                set: { if action.shell == nil { action.shell = ShellConfig() }; action.shell?.scriptInline = $0 }
            ))
        }
    }

    @ViewBuilder
    private var applicationEditor: some View {
        Button("Choose Application…") { chooseApplication() }
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
        Toggle("Use External Script File", isOn: $appleScriptFileMode)
            .onChange(of: appleScriptFileMode) { _, file in
                if !file { ActionAuthoring.useInline(&action) }
                else if (action.appleScript?.scriptFile ?? "").isEmpty {
                    chooseScript(appleScript: true)
                    if (action.appleScript?.scriptFile ?? "").isEmpty { appleScriptFileMode = false }
                }
            }
        if appleScriptFileMode {
            Button("Choose Script File…") { chooseScript(appleScript: true) }
            if let file = action.appleScript?.scriptFile, !file.isEmpty {
                Text(state.store.resolveScriptPath(file).path).font(.caption).textSelection(.enabled)
                Button("Open in Editor") { NSWorkspace.shared.open(state.store.resolveScriptPath(file)) }
            }
            Text("The external file takes priority. Your inline draft is preserved.").font(.caption)
        } else {
            ScriptEditor(text: Binding(get: { action.appleScript?.scriptInline ?? "" }, set: {
                if action.appleScript == nil { action.appleScript = AppleScriptConfig() }
                action.appleScript?.scriptInline = $0
            }))
        }
    }

    private func chooseScript(appleScript: Bool) {
        let panel = NSOpenPanel(); panel.canChooseFiles = true; panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if appleScript {
            if action.appleScript == nil { action.appleScript = AppleScriptConfig() }
            action.appleScript?.scriptFile = url.path
        } else {
            if action.shell == nil { action.shell = ShellConfig() }
            action.shell?.scriptFile = url.path
        }
    }

    private func chooseApplication() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.applicationBundle]; panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url, let bundle = Bundle(url: url) else { return }
        action.application = ApplicationConfig(bundleId: bundle.bundleIdentifier ?? "", pathFallback: url.path)
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
