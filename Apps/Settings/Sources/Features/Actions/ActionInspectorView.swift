import SwiftUI
import FinderActionsCore

struct ActionInspectorView: View {
    @Environment(AppState.self) private var state
    @Binding var action: ActionDefinition
    @State private var showSymbolPicker = false
    @State private var extensionText = ""

    private static let commonSymbols = [
        "bolt", "bolt.fill", "terminal", "doc.on.clipboard",
        "doc.on.doc", "doc.plaintext", "folder", "link",
        "gearshape", "hammer", "wrench.and.screwdriver", "play.fill",
        "scissors", "trash", "arrow.up.right.square", "shippingbox",
    ]

    private var selectableTypes: [ActionType] {
        ActionType.userAssignable + (ActionType.userAssignable.contains(action.type) ? [] : [action.type])
    }

    private var targetRule: SelectionTargetRule {
        ActionAuthoring.selectionTarget(for: action)
    }

    private var countRule: SelectionCountRule {
        ActionAuthoring.selectionCount(for: action)
    }

    var body: some View {
        Form {
            headerSection
            menuSection
            executionSection
            LiveTestConsole(action: action)
        }
        .formStyle(.grouped)
        .onAppear {
            extensionText = action.extRules?.pathExtensions.joined(separator: ", ") ?? ""
        }
    }

    private var headerSection: some View {
        Section {
            HStack(spacing: 10) {
                Button {
                    showSymbolPicker.toggle()
                } label: {
                    ActionIconTile(symbol: action.icon?.sfSymbol, isActive: action.enabled, size: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Icon")
                .popover(isPresented: $showSymbolPicker, arrowEdge: .bottom) { symbolPicker }

                TextField("Name", text: $action.name, prompt: Text("Action Name"))
                    .labelsHidden()
                    .textFieldStyle(.plain)
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier(SettingsAccessibilityID.inspectorName)

                Spacer(minLength: 8)

                Toggle("Enabled", isOn: Binding(
                    get: { action.enabled },
                    set: { enabled in
                        if !enabled || ActionAuthoring.validationError(action) == nil {
                            action.enabled = enabled
                        }
                    }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .accessibilityLabel("Enabled")
                .accessibilityIdentifier(SettingsAccessibilityID.inspectorEnabled)
            }

            if let error = ActionAuthoring.validationError(action) {
                Label(String(localized: String.LocalizationValue(error)), systemImage: "exclamationmark.circle")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var menuSection: some View {
        Section("Menu") {
            TextField("Submenu", text: optional(\.group), prompt: Text("Top Level"))

            Picker("Items", selection: Binding(
                get: { targetRule },
                set: { newTarget in
                    ActionAuthoring.applySelectionRule(&action, target: newTarget, count: countRule)
                    if newTarget == .folders { extensionText = "" }
                }
            )) {
                Text("Files & Folders").tag(SelectionTargetRule.any)
                Text("Files").tag(SelectionTargetRule.files)
                Text("Folders").tag(SelectionTargetRule.folders)
            }

            Picker("Selection", selection: Binding(
                get: { countRule },
                set: { newCount in
                    ActionAuthoring.applySelectionRule(&action, target: targetRule, count: newCount)
                }
            )) {
                Text("Any").tag(SelectionCountRule.any)
                Text("Single Item").tag(SelectionCountRule.single)
                Text("Multiple Items").tag(SelectionCountRule.multiple)
            }

            if targetRule != .folders {
                TextField("Extensions", text: Binding(
                    get: { extensionText },
                    set: { value in
                        extensionText = value
                        var rules = action.extRules ?? ExtRules()
                        rules.pathExtensions = ActionAuthoring.normalizedExtensions(value)
                        action.extRules = (rules.pathExtensions.isEmpty && !rules.filesOnly && !rules.foldersOnly) ? nil : rules
                    }
                ), prompt: Text(verbatim: "png, jpg"))
            }
        }
    }

    private var executionSection: some View {
        Section("Action") {
            Picker("Type", selection: $action.type) {
                ForEach(selectableTypes, id: \.self) { Text($0.displayName).tag($0) }
            }

            switch action.type {
            case .shell:
                shellEditor
            case .application:
                applicationEditor
            case .terminal:
                LabeledContent("Terminal") {
                    HStack(spacing: 8) {
                        Text(state.openWithSettings.terminal.name)
                            .foregroundStyle(.secondary)
                        Button("Configure…") { state.navigate(to: .applications) }
                            .controlSize(.small)
                    }
                }
            case .appleScript:
                appleScriptEditor
            case .builtin:
                LabeledContent("Identifier", value: action.builtinId ?? "—")
            }
        }
    }

    @ViewBuilder
    private var shellEditor: some View {
        TextField("Shell", text: shellBinding(\.interpreter, default: "/bin/zsh"), prompt: Text(verbatim: "/bin/zsh"))
        scriptSourceControls(
            appleScript: false,
            filePath: action.shell?.scriptFile,
            inlineText: Binding(
                get: { action.shell?.scriptInline ?? "" },
                set: {
                    if action.shell == nil { action.shell = ShellConfig() }
                    action.shell?.scriptInline = $0
                }
            )
        )
    }

    @ViewBuilder
    private var appleScriptEditor: some View {
        scriptSourceControls(
            appleScript: true,
            filePath: action.appleScript?.scriptFile,
            inlineText: Binding(
                get: { action.appleScript?.scriptInline ?? "" },
                set: {
                    if action.appleScript == nil { action.appleScript = AppleScriptConfig() }
                    action.appleScript?.scriptInline = $0
                }
            )
        )
    }

    @ViewBuilder
    private func scriptSourceControls(
        appleScript: Bool,
        filePath: String?,
        inlineText: Binding<String>
    ) -> some View {
        let mode = ActionAuthoring.sourceMode(for: action)
        Picker("Source", selection: Binding(
            get: { mode },
            set: { newMode in
                switch newMode {
                case .inline:
                    ActionAuthoring.useInline(&action)
                case .file:
                    if (filePath ?? "").isEmpty {
                        chooseScript(appleScript: appleScript)
                    }
                }
            }
        )) {
            Text("Inline").tag(ScriptSourceMode.inline)
            Text("File").tag(ScriptSourceMode.file)
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier(SettingsAccessibilityID.inspectorSourceMode)

        if mode == .file, let file = filePath, !file.isEmpty {
            let resolved = state.store.resolveScriptPath(file)
            LabeledContent("Script") {
                HStack(spacing: 6) {
                    Text(resolved.lastPathComponent)
                        .font(.callout.monospaced())
                        .lineLimit(1)
                        .help(resolved.path)
                    Button("Choose…") { chooseScript(appleScript: appleScript) }
                        .controlSize(.small)
                    Button("Edit") { NSWorkspace.shared.open(resolved) }
                        .controlSize(.small)
                }
            }
        } else {
            ScriptEditor(text: inlineText)
        }
    }

    @ViewBuilder
    private var applicationEditor: some View {
        LabeledContent("Application") {
            Button("Choose…") { chooseApplication() }
        }
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
            "Path",
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

    private func chooseScript(appleScript: Bool) {
        let panel = NSOpenPanel()
        panel.directoryURL = state.store.actionsDirectoryURL
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
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
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url, let bundle = Bundle(url: url) else { return }
        action.application = ApplicationConfig(bundleId: bundle.bundleIdentifier ?? "", pathFallback: url.path)
    }

    private var symbolPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(34), spacing: 6), count: 4), spacing: 6) {
                ForEach(Self.commonSymbols, id: \.self) { symbol in
                    let isSelected = action.icon?.sfSymbol == symbol
                    Button {
                        symbolBinding.wrappedValue = symbol
                        showSymbolPicker = false
                    } label: {
                        Image(systemName: symbol)
                            .frame(width: 34, height: 34)
                            .background(
                                isSelected ? Color.accentColor.opacity(0.22) : Color.secondary.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(symbol)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }

            TextField("SF Symbol", text: symbolBinding, prompt: Text(verbatim: "doc.on.clipboard"))
                .textFieldStyle(.roundedBorder)
                .font(.caption.monospaced())
        }
        .padding(12)
        .frame(width: 184)
    }

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
}

private struct ScriptEditor: View {
    @Binding var text: String

    var body: some View {
        TextEditor(text: $text)
            .font(.callout.monospaced())
            .autocorrectionDisabled()
            .scrollContentBackground(.hidden)
            .padding(6)
            .frame(minHeight: 150)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
