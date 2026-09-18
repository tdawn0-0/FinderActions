import SwiftUI
import UniformTypeIdentifiers
import FinderActionsCore

// MARK: - Navigation Sections

enum SettingsSection: String, CaseIterable, Identifiable {
    case actions = "Actions"
    case applications = "Applications"
    case extensions = "Extensions & Permissions"
    case logs = "Activity Logs"
    case general = "General"
    case about = "About"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .actions: return "Actions"
        case .applications: return "Applications"
        case .extensions: return "Extensions & Permissions"
        case .logs: return "Activity Logs"
        case .general: return "General"
        case .about: return "About"
        }
    }

    var icon: String {
        switch self {
        case .actions: return "bolt.fill"
        case .applications: return "app.badge.fill"
        case .extensions: return "puzzlepiece.extension.fill"
        case .logs: return "list.bullet.rectangle.portrait.fill"
        case .general: return "gearshape.fill"
        case .about: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .actions: return .blue
        case .applications: return .purple
        case .extensions: return .orange
        case .logs: return .teal
        case .general: return .gray
        case .about: return .indigo
        }
    }
}

// MARK: - Root Settings View

/// Root view for the short-lived Settings helper process.
struct SettingsRootView: View {
    @Environment(AppState.self) private var state
    @State private var selectedSection: SettingsSection? = .actions

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    HStack(spacing: 8) {
                        Image(systemName: section.icon)
                            .foregroundStyle(section.color)
                            .frame(width: 18)
                        Text(LocalizedStringKey(section.title))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 225, max: 280)
        } detail: {
            Group {
                switch selectedSection ?? .actions {
                case .actions:
                    ActionsSettingsView()
                case .applications:
                    ApplicationsSettingsView()
                case .extensions:
                    ExtensionStatusView()
                case .logs:
                    LogsSettingsView()
                case .general:
                    GeneralSettingsView()
                case .about:
                    AboutView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 880, idealWidth: 960, minHeight: 560, idealHeight: 620)
        .environment(state)
    }
}

// MARK: - 1. Actions Management (Pure SwiftUI Flexible Layout)

struct ActionsSettingsView: View {
    @Environment(AppState.self) private var state
    @State private var selectedId: String?
    @State private var searchText: String = ""

    private var filteredActions: [ActionDefinition] {
        let sorted = state.manifest.actions.sorted(by: { $0.sortIndex < $1.sortIndex })
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return sorted
        }
        return sorted.filter { action in
            action.name.localizedCaseInsensitiveContains(searchText)
                || (action.subtitle?.localizedCaseInsensitiveContains(searchText) ?? false)
                || (action.group?.localizedCaseInsensitiveContains(searchText) ?? false)
                || action.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left Action List (Fixed width, zero autolayout conflict)
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.secondary)
                    TextField("Search actions…", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(8)

                Divider()

                // Actions List
                List(selection: $selectedId) {
                    ForEach(filteredActions) { action in
                        ActionListRow(action: action) { enabled in
                            state.setEnabled(actionId: action.id, enabled: enabled)
                        }
                        .tag(action.id)
                    }
                    .onMove { src, dst in
                        state.moveAction(from: src, to: dst)
                    }
                }
                .listStyle(.plain)

                Divider()

                // List bottom action bar
                HStack(spacing: 6) {
                    Button {
                        let newAction = state.addNewAction()
                        selectedId = newAction.id
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("Add New Action")

                    Button {
                        if let id = selectedId {
                            state.deleteAction(id: id)
                            selectedId = filteredActions.first?.id
                        }
                    } label: {
                        Image(systemName: "minus")
                    }
                    .disabled(selectedId == nil)
                    .help("Delete Selected Action")

                    Button {
                        if let id = selectedId, let copy = state.duplicateAction(id: id) {
                            selectedId = copy.id
                        }
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .disabled(selectedId == nil)
                    .help("Duplicate Action")

                    Spacer()

                    Button {
                        state.openActionsDirectory()
                    } label: {
                        Image(systemName: "folder")
                    }
                    .help("Open Scripts Directory in Finder")
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.bar)
            }
            .frame(width: 240)

            Divider()

            // Right Detail Inspector (Flexible fill)
            if let id = selectedId,
               let idx = state.manifest.actions.firstIndex(where: { $0.id == id }) {
                ActionDetailInspectorView(
                    action: Binding(
                        get: { state.manifest.actions[idx] },
                        set: {
                            state.manifest.actions[idx] = $0
                            state.saveManifest()
                        }
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "No Action Selected",
                    systemImage: "bolt.badge.automatic",
                    description: Text("Select an action to inspect its settings, edit scripts, and test run.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if selectedId == nil {
                selectedId = state.manifest.actions.sorted(by: { $0.sortIndex < $1.sortIndex }).first?.id
            }
        }
    }
}

// MARK: - Action List Row

private struct ActionListRow: View {
    let action: ActionDefinition
    var onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(typeColor.opacity(0.15))
                Image(systemName: action.icon?.sfSymbol ?? "bolt")
                    .foregroundStyle(typeColor)
                    .font(.system(size: 11, weight: .semibold))
            }
            .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(action.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(action.enabled ? Color.primary : Color.secondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(action.type.rawValue.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(typeColor.opacity(0.12))
                        .foregroundStyle(typeColor)
                        .clipShape(RoundedRectangle(cornerRadius: 3))

                    if let sub = action.subtitle, !sub.isEmpty {
                        Text(sub)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 4)

            Toggle("", isOn: Binding(
                get: { action.enabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.mini)
        }
        .padding(.vertical, 3)
    }

    private var typeColor: Color {
        switch action.type {
        case .shell: return .blue
        case .terminal: return .purple
        case .application: return .green
        case .appleScript: return .orange
        case .builtin: return .pink
        }
    }
}

// MARK: - Action Detail Inspector

private struct ActionDetailInspectorView: View {
    @Environment(AppState.self) private var state
    @Binding var action: ActionDefinition
    @State private var isRunningTest = false
    @State private var testResult: ExecResult?
    @State private var showSymbolPicker = false

    private let commonSymbols = [
        "bolt", "bolt.fill", "terminal", "terminal.fill",
        "doc.on.doc", "doc.plaintext", "folder", "link",
        "gearshape", "hammer", "wrench.and.screwdriver", "play.fill",
        "scissors", "trash", "arrow.up.right.square", "shippingbox"
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                // Header Card
                HStack(spacing: 12) {
                    Button {
                        showSymbolPicker.toggle()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.accentColor.opacity(0.12))
                            Image(systemName: action.icon?.sfSymbol ?? "bolt")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.accentColor)
                        }
                        .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showSymbolPicker) {
                        symbolPickerPopover
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        TextField("Action Name", text: $action.name)
                            .font(.system(size: 15, weight: .bold))
                            .textFieldStyle(.plain)

                        TextField("Subtitle (Optional)", text: Binding(
                            get: { action.subtitle ?? "" },
                            set: { action.subtitle = $0.isEmpty ? nil : $0 }
                        ))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                        .textFieldStyle(.plain)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text(action.enabled ? LocalizedStringKey("Enabled") : LocalizedStringKey("Disabled"))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                        Toggle("", isOn: $action.enabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                }
                .padding(12)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Basic Properties
                GroupBox("Display & Matching") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Show When:")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.secondary)
                                .frame(width: 85, alignment: .leading)
                            Picker("", selection: $action.showWhen) {
                                Text("Always").tag(ShowWhen.always)
                                Text("Files Only").tag(ShowWhen.filesOnly)
                                Text("Folders Only").tag(ShowWhen.foldersOnly)
                                Text("Single Selection").tag(ShowWhen.single)
                                Text("Multiple Selection").tag(ShowWhen.multiple)
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            Spacer()
                        }

                        HStack {
                            Text("Menu Group:")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.secondary)
                                .frame(width: 85, alignment: .leading)
                            TextField("e.g. Develop, Quick Actions", text: Binding(
                                get: { action.group ?? "" },
                                set: { action.group = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }

                        HStack {
                            Text("SF Symbol:")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.secondary)
                                .frame(width: 85, alignment: .leading)
                            TextField("symbol name", text: Binding(
                                get: { action.icon?.sfSymbol ?? "" },
                                set: {
                                    if action.icon == nil { action.icon = ActionIcon() }
                                    action.icon?.sfSymbol = $0.isEmpty ? nil : $0
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(6)
                }

                // Execution Configuration
                GroupBox("Execution Logic") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Action Type:")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.secondary)
                                .frame(width: 85, alignment: .leading)
                            Picker("", selection: $action.type) {
                                Text("Shell Script").tag(ActionType.shell)
                                Text("Application").tag(ActionType.application)
                                Text("Terminal").tag(ActionType.terminal)
                                Text("AppleScript").tag(ActionType.appleScript)
                                Text("Built-in").tag(ActionType.builtin)
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            Spacer()
                        }

                        Divider()

                        switch action.type {
                        case .shell:
                            shellConfigEditor
                        case .application:
                            applicationConfigEditor
                        case .terminal:
                            terminalConfigEditor
                        case .appleScript:
                            appleScriptConfigEditor
                        case .builtin:
                            Text("Built-in Identifier: \(action.builtinId ?? "—")")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .padding(6)
                }

                // Live Test Runner Panel
                GroupBox("Live Test Console") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Button {
                                runLiveTest()
                            } label: {
                                Label(isRunningTest ? "Running…" : "Run Test", systemImage: "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(isRunningTest)

                            if let res = testResult {
                                HStack(spacing: 4) {
                                    Image(systemName: res.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(res.success ? Color.green : Color.red)
                                    Text(res.success ? "Success (0)" : "Failed (\(res.exitCode))")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(res.success ? Color.green : Color.red)
                                }
                            }

                            Spacer()
                        }

                        Text("Runs against user home directory.")
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)

                        if let res = testResult {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Summary: \(res.summary)")
                                    .font(.caption)
                                    .fontWeight(.medium)

                                if !res.stdout.isEmpty {
                                    Text("STDOUT:")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(Color.secondary)
                                    ScrollView(.horizontal, showsIndicators: true) {
                                        Text(res.stdout)
                                            .font(.system(size: 11, design: .monospaced))
                                            .padding(4)
                                            .textSelection(.enabled)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: 80, alignment: .leading)
                                    .background(Color.black.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                }

                                if !res.stderr.isEmpty {
                                    Text("STDERR:")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(Color.red)
                                    ScrollView(.horizontal, showsIndicators: true) {
                                        Text(res.stderr)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundStyle(Color.red)
                                            .padding(4)
                                            .textSelection(.enabled)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: 80, alignment: .leading)
                                    .background(Color.red.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            .padding(6)
                            .background(Color.secondary.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .padding(6)
                }
            }
            .padding(16)
        }
    }

    private var symbolPickerPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Choose Symbol")
                .font(.caption.bold())
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(32)), count: 4), spacing: 8) {
                ForEach(commonSymbols, id: \.self) { sym in
                    Button {
                        if action.icon == nil { action.icon = ActionIcon() }
                        action.icon?.sfSymbol = sym
                        showSymbolPicker = false
                    } label: {
                        Image(systemName: sym)
                            .font(.system(size: 14))
                            .frame(width: 32, height: 32)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
    }

    private var shellConfigEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Interpreter:")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 85, alignment: .leading)
                TextField("/bin/zsh", text: Binding(
                    get: { action.shell?.interpreter ?? "/bin/zsh" },
                    set: {
                        if action.shell == nil { action.shell = ShellConfig() }
                        action.shell?.interpreter = $0
                    }
                ))
                .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 8) {
                Text("Script File:")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 85, alignment: .leading)
                TextField("e.g. copy-path.zsh", text: Binding(
                    get: { action.shell?.scriptFile ?? "" },
                    set: {
                        if action.shell == nil { action.shell = ShellConfig() }
                        action.shell?.scriptFile = $0
                    }
                ))
                .textFieldStyle(.roundedBorder)

                Button {
                    state.openActionsDirectory()
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
                .help("Open Scripts Directory in Finder")
            }

            Text("Or Inline Script:")
                .font(.caption2)
                .foregroundStyle(Color.secondary)

            TextEditor(text: Binding(
                get: { action.shell?.scriptInline ?? "" },
                set: {
                    if action.shell == nil { action.shell = ShellConfig() }
                    action.shell?.scriptInline = $0.isEmpty ? nil : $0
                }
            ))
            .font(.system(size: 11, design: .monospaced))
            .frame(minHeight: 60, maxHeight: 110)
            .padding(4)
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private var applicationConfigEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bundle ID:")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 85, alignment: .leading)
                TextField("com.example.app", text: Binding(
                    get: { action.application?.bundleId ?? "" },
                    set: {
                        action.application = ApplicationConfig(
                            bundleId: $0,
                            pathFallback: action.application?.pathFallback
                        )
                    }
                ))
                .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("Fallback Path:")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 85, alignment: .leading)
                TextField("/Applications/App.app", text: Binding(
                    get: { action.application?.pathFallback ?? "" },
                    set: {
                        action.application = ApplicationConfig(
                            bundleId: action.application?.bundleId ?? "",
                            pathFallback: $0.isEmpty ? nil : $0
                        )
                    }
                ))
                .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var terminalConfigEditor: some View {
        Label("Configure default terminal in the Applications tab.", systemImage: "app.badge")
            .font(.caption)
            .foregroundStyle(Color.secondary)
    }

    private var appleScriptConfigEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Script File:")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 85, alignment: .leading)
                TextField("script.applescript", text: Binding(
                    get: { action.appleScript?.scriptFile ?? "" },
                    set: {
                        if action.appleScript == nil { action.appleScript = AppleScriptConfig() }
                        action.appleScript?.scriptFile = $0
                    }
                ))
                .textFieldStyle(.roundedBorder)
            }

            TextEditor(text: Binding(
                get: { action.appleScript?.scriptInline ?? "" },
                set: {
                    if action.appleScript == nil { action.appleScript = AppleScriptConfig() }
                    action.appleScript?.scriptInline = $0.isEmpty ? nil : $0
                }
            ))
            .font(.system(size: 11, design: .monospaced))
            .frame(minHeight: 60, maxHeight: 110)
            .padding(4)
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func runLiveTest() {
        isRunningTest = true
        let currentAction = action
        let executor = state.executor
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        Task {
            let res = await Task.detached {
                executor.execute(
                    action: currentAction,
                    paths: [homePath],
                    containerPath: homePath
                )
            }.value
            await MainActor.run {
                state.recordLog(ExecLogEntry(
                    actionId: currentAction.id,
                    success: res.success,
                    summary: "Test Run: \(res.summary)",
                    paths: [homePath]
                ))
                testResult = res
                isRunningTest = false
            }
        }
    }
}

// MARK: - 2. Applications Settings

struct ApplicationsSettingsView: View {
    @Environment(AppState.self) private var state

    private var terminalChoices: [ExternalApplication] {
        var choices = ExternalApplicationCatalog.terminals
        if !choices.contains(where: { $0.bundleId == state.openWithSettings.terminal.bundleId }) {
            choices.append(state.openWithSettings.terminal)
        }
        return choices
    }

    private var visibleEditors: [ExternalApplication] {
        ExternalApplicationCatalog.editors
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                // Section: Terminal
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Default Terminal", systemImage: "terminal.fill")
                                .font(.headline)
                            Spacer()
                            Button("Choose Other Terminal…") {
                                state.chooseApplications(kind: .terminal)
                            }
                            .controlSize(.small)
                        }

                        Text("Finder always renders one single “Open in Terminal” menu item. Selected terminal will launch with the working directory.")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 200))], spacing: 8) {
                            ForEach(terminalChoices) { terminal in
                                TerminalCard(
                                    application: terminal,
                                    isInstalled: state.isApplicationInstalled(terminal),
                                    isSelected: state.openWithSettings.terminal.bundleId == terminal.bundleId
                                ) {
                                    state.selectTerminal(terminal)
                                }
                            }
                        }
                    }
                    .padding(6)
                }

                // Section: Editors
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Code Editors & IDEs", systemImage: "chevron.left.forwardslash.chevron.right")
                                .font(.headline)
                            Spacer()
                            Button("Add Custom Editor…") {
                                state.chooseApplications(kind: .editor)
                            }
                            .controlSize(.small)
                        }

                        Text("Each enabled editor creates its own dedicated menu entry in Finder.")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170, maximum: 240))], spacing: 8) {
                            ForEach(visibleEditors) { editor in
                                EditorCard(
                                    application: editor,
                                    isInstalled: state.isApplicationInstalled(editor),
                                    isOn: editorBinding(for: editor)
                                )
                            }

                            ForEach(state.customEditors) { editor in
                                EditorCard(
                                    application: editor,
                                    isInstalled: state.isApplicationInstalled(editor),
                                    isOn: editorBinding(for: editor)
                                )
                            }
                        }
                    }
                    .padding(6)
                }
            }
            .padding(16)
        }
    }

    private func editorBinding(for application: ExternalApplication) -> Binding<Bool> {
        Binding(
            get: { state.isEditorEnabled(application) },
            set: { state.setEditor(application, enabled: $0) }
        )
    }
}

private struct TerminalCard: View {
    let application: ExternalApplication
    let isInstalled: Bool
    let isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: application.sfSymbol)
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 1) {
                    Text(application.name)
                        .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                        .lineLimit(1)
                    Text(isInstalled ? "Installed" : "Not Found")
                        .font(.system(size: 8))
                        .foregroundStyle(isInstalled ? Color.secondary : Color.orange)
                }

                Spacer(minLength: 2)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.system(size: 11))
                }
            }
            .padding(6)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

private struct EditorCard: View {
    let application: ExternalApplication
    let isInstalled: Bool
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: application.sfSymbol)
                .font(.system(size: 14))
                .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(application.name)
                    .font(.system(size: 11, weight: isOn ? .semibold : .regular))
                    .lineLimit(1)
                Text(isInstalled ? application.bundleId : "Not Installed")
                    .font(.system(size: 8))
                    .foregroundStyle(isInstalled ? Color.secondary : Color.orange)
                    .lineLimit(1)
            }

            Spacer(minLength: 2)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
        }
        .padding(6)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - 3. Extensions & Permissions Dashboard

struct ExtensionStatusView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                // Extension Status Card
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "puzzlepiece.extension.fill")
                                .font(.title3)
                                .foregroundStyle(Color.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("FinderSync Extension")
                                    .font(.headline)
                                Text("Displays right-click action items in Finder.")
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                            }
                            Spacer()
                            Button("Refresh") {
                                state.refreshExtensionStatus()
                            }
                            .controlSize(.small)
                        }

                        HStack(spacing: 8) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            Text(state.extensionEnabledHint)
                                .font(.system(size: 12))
                                .textSelection(.enabled)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(statusColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                        HStack {
                            Button("Open System Settings → Extensions") {
                                state.openExtensionSettings()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)

                            Button("Restart Finder") {
                                state.restartFinder()
                            }
                            .controlSize(.small)
                        }
                    }
                    .padding(6)
                }

                // Full Disk Access Card
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .font(.title3)
                                .foregroundStyle(Color.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Full Disk Access (FDA)")
                                    .font(.headline)
                                Text("Grants permission for scripts to access protected folders without prompts.")
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                            }
                        }

                        FullDiskAccessGuideView()
                    }
                    .padding(6)
                }

                // Troubleshooting Box
                GroupBox("Troubleshooting Terminal Commands") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("If the menu does not show after enabling in System Settings:")
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)

                        Text("pluginkit -a \"/Applications/FinderActions.app/Contents/PlugIns/FAFinderSync.appex\"\npluginkit -e use -i com.finderactions.host.FinderSync\nkillall Finder")
                            .font(.system(size: 10, design: .monospaced))
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .textSelection(.enabled)
                    }
                    .padding(6)
                }
            }
            .padding(16)
        }
        .task {
            state.refreshExtensionStatus()
        }
    }

    private var statusColor: Color {
        if state.extensionEnabledHint.contains("Registered") && !state.extensionEnabledHint.contains("Not") {
            return .green
        }
        return .orange
    }
}

// MARK: - 4. Logs Settings View

struct LogsSettingsView: View {
    @Environment(AppState.self) private var state
    @State private var filterStatus: Int = 0 // 0: all, 1: success, 2: failure
    @State private var searchText = ""

    private var filteredLogs: [ExecLogEntry] {
        state.logs.filter { log in
            if filterStatus == 1 && !log.success { return false }
            if filterStatus == 2 && log.success { return false }
            if !searchText.isEmpty {
                return log.actionId.localizedCaseInsensitiveContains(searchText)
                    || log.summary.localizedCaseInsensitiveContains(searchText)
                    || log.paths.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
            return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter Toolbar
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.secondary)
                    TextField("Search logs…", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(5)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Picker("", selection: $filterStatus) {
                    Text("All").tag(0)
                    Text("Success").tag(1)
                    Text("Failed").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)

                Spacer(minLength: 4)

                Button("Clear", role: .destructive) {
                    state.clearLogs()
                }
                .controlSize(.small)
                .disabled(state.logs.isEmpty)
            }
            .padding(10)

            Divider()

            if filteredLogs.isEmpty {
                ContentUnavailableView(
                    "No Logs Found",
                    systemImage: "tray",
                    description: Text("Execution history stays strictly on this Mac.")
                )
            } else {
                List(filteredLogs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: log.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(log.success ? Color.green : Color.red)
                            Text(log.actionId)
                                .font(.system(size: 12, weight: .semibold))
                            Spacer()
                            Text(log.timestamp)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.secondary)
                        }

                        Text(log.summary)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.primary)

                        if !log.paths.isEmpty {
                            Text(log.paths.joined(separator: "\n"))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Color.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 3)
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - 5. General Settings

struct GeneralSettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.openURL) private var openURL
    @State private var showResetConfirm = false

    var body: some View {
        @Bindable var state = state

        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Preferences") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Show system notifications upon execution completion", isOn: $state.notificationsEnabled)
                    }
                    .padding(6)
                }

                GroupBox("Storage & Configurations") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Manifest Config")
                                    .font(.subheadline.bold())
                                Text(state.store.fileURL.path)
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                                    .textSelection(.enabled)
                            }
                            Spacer()
                            Button("Reveal in Finder") {
                                openURL(state.store.fileURL.deletingLastPathComponent())
                            }
                            .controlSize(.small)
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Scripts Folder")
                                    .font(.subheadline.bold())
                                Text(state.store.actionsDirectoryURL.path)
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                                    .textSelection(.enabled)
                            }
                            Spacer()
                            Button("Open Folder") {
                                openURL(state.store.actionsDirectoryURL)
                            }
                            .controlSize(.small)
                        }
                    }
                    .padding(6)
                }

                GroupBox("Factory Reset") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reset actions and application configurations back to the initial defaults.")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)

                        Button("Reset to Defaults", role: .destructive) {
                            showResetConfirm = true
                        }
                        .controlSize(.small)
                        .alert("Reset all actions to default?", isPresented: $showResetConfirm) {
                            Button("Reset", role: .destructive) {
                                state.seedDefaults()
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This will restore the default manifest and bundled scripts.")
                        }
                    }
                    .padding(6)
                }

                GroupBox("Privacy & Offline") {
                    HStack(spacing: 10) {
                        Image(systemName: "hand.raised.shield.fill")
                            .font(.title3)
                            .foregroundStyle(Color.green)
                        Text("FinderActions is completely offline. No telemetry, no accounts, and no data leaves your device.")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(6)
                }
            }
            .padding(16)
        }
        .onChange(of: state.notificationsEnabled) { _, _ in state.persistSettings() }
    }
}

// MARK: - 6. About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 72, height: 72)
                Image(systemName: "hammer.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.white)
            }

            VStack(spacing: 4) {
                Text("FinderActions")
                    .font(.title2.bold())
                Text("Version 1.0.0 (Native)")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }

            Text("Fast, non-sandboxed Host + lightweight FinderSync extension for custom context menu actions.")
                .font(.body)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            HStack(spacing: 12) {
                Link("GitHub Repository", destination: URL(string: "https://github.com/finderactions/FinderActions")!)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                Text("MIT License")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
}

// MARK: - Full Disk Access Helper

struct FullDiskAccessGuideView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                VStack(alignment: .leading, spacing: 1) {
                    Text(FullDiskAccessSettings.isInstalledInApplications
                         ? "FinderActions is installed in /Applications"
                         : "Recommended: Move FinderActions to /Applications")
                        .fontWeight(.medium)
                    Text(FullDiskAccessSettings.isInstalledInApplications
                         ? "Ready to grant permissions stably."
                         : "Running from Downloads or build folders can invalidate permissions on update.")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
            } icon: {
                Image(systemName: FullDiskAccessSettings.isInstalledInApplications ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(FullDiskAccessSettings.isInstalledInApplications ? Color.green : Color.orange)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("1. Open Full Disk Access in macOS System Settings.")
                Text("2. Click + and select FinderActions.app, or drag the app into the list.")
                Text("3. Turn FinderActions on.")
            }
            .font(.caption)
            .foregroundStyle(Color.secondary)

            HStack {
                Button("Show in Finder") {
                    FullDiskAccessSettings.revealApplication()
                }
                .controlSize(.small)

                Button("Open Full Disk Access") {
                    FullDiskAccessSettings.openSystemSettings()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Environment(AppState.self) private var state
    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set up FinderActions")
                            .font(.title2.bold())
                        Text("Two quick system settings make Finder actions available across protected folders.")
                            .foregroundStyle(Color.secondary)
                    }

                    GroupBox("1. Allow access to protected folders") {
                        FullDiskAccessGuideView()
                            .padding(.top, 2)
                    }

                    GroupBox("2. Enable the Finder extension") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Open Extensions, enable FinderActions under Added Extensions, then return here.")
                                .font(.caption)
                            Button("Open Extension Settings") {
                                state.openExtensionSettings()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                    }
                }
                .padding(20)
            }

            Divider()
            HStack {
                Button("Skip for Now") {
                    finish()
                }
                Spacer()
                Button("Finish Setup") {
                    finish()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 540, height: 500)
    }

    private func finish() {
        state.completeOnboarding()
        onDismiss()
    }
}
