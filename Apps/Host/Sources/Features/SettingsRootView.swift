import SwiftUI
import AppKit
import UniformTypeIdentifiers
import FinderActionsCore

struct SettingsRootView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        TabView {
            Tab("Actions", systemImage: "bolt.fill") {
                ActionsSettingsView()
            }
            Tab("Extension", systemImage: "puzzlepiece.extension") {
                ExtensionStatusView()
            }
            Tab("Logs", systemImage: "list.bullet.rectangle") {
                LogsSettingsView()
            }
            Tab("Applications", systemImage: "app.badge") {
                ApplicationsSettingsView()
            }
            Tab("Settings", systemImage: "gearshape") {
                GeneralSettingsView()
            }
            Tab("About", systemImage: "info.circle") {
                AboutView()
            }
        }
        .frame(minWidth: 560, minHeight: 420)
        .environment(state)
    }
}

struct ActionsSettingsView: View {
    @Environment(AppState.self) private var state
    @State private var selectedId: String?

    var body: some View {
        @Bindable var state = state

        HSplitView {
            List(selection: $selectedId) {
                ForEach(state.manifest.actions.sorted(by: { $0.sortIndex < $1.sortIndex })) { action in
                    HStack {
                        Image(systemName: action.icon?.sfSymbol ?? "bolt")
                        Text(action.name)
                        Spacer()
                        if !action.enabled {
                            Text("Off")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(action.id)
                }
                .onMove { src, dst in
                    state.moveAction(from: src, to: dst)
                }
            }
            .frame(minWidth: 200)

            if let id = selectedId,
               let idx = state.manifest.actions.firstIndex(where: { $0.id == id }) {
                ActionEditorView(action: $state.manifest.actions[idx]) {
                    state.saveManifest()
                } onTest: {
                    testRun(action: state.manifest.actions[idx])
                }
            } else {
                ContentUnavailableView(
                    "Select an action",
                    systemImage: "bolt",
                    description: Text("Choose an action to edit its type, script, and visibility rules.")
                )
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Open Scripts Folder") {
                    state.openActionsDirectory()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Reset Defaults") {
                    state.seedDefaults()
                }
            }
        }
    }

    private func testRun(action: ActionDefinition) {
        let paths = [NSHomeDirectory()]
        let result = state.executor.execute(
            action: action,
            paths: paths,
            containerPath: paths.first
        )
        state.recordLog(ExecLogEntry(
            actionId: action.id,
            success: result.success,
            summary: "Test: \(result.summary)",
            paths: paths
        ))
    }
}

struct ActionEditorView: View {
    @Binding var action: ActionDefinition
    var onSave: () -> Void
    var onTest: () -> Void

    var body: some View {
        Form {
            Section("Identity") {
                TextField("Name", text: $action.name)
                TextField("Subtitle", text: Binding(
                    get: { action.subtitle ?? "" },
                    set: { action.subtitle = $0.isEmpty ? nil : $0 }
                ))
                Toggle("Enabled", isOn: $action.enabled)
                Picker("Show when", selection: $action.showWhen) {
                    ForEach(ShowWhen.allCases, id: \.self) { w in
                        Text(w.rawValue).tag(w)
                    }
                }
                TextField("Group", text: Binding(
                    get: { action.group ?? "" },
                    set: { action.group = $0.isEmpty ? nil : $0 }
                ))
                TextField("SF Symbol", text: Binding(
                    get: { action.icon?.sfSymbol ?? "" },
                    set: {
                        if action.icon == nil { action.icon = ActionIcon() }
                        action.icon?.sfSymbol = $0.isEmpty ? nil : $0
                    }
                ))
            }

            Section("Type") {
                switch action.type {
                case .terminal:
                    Label("Configure the terminal in Applications settings.", systemImage: "app.badge")
                        .foregroundStyle(.secondary)
                case .shell:
                    TextField("Interpreter", text: Binding(
                        get: { action.shell?.interpreter ?? "/bin/zsh" },
                        set: {
                            if action.shell == nil { action.shell = ShellConfig() }
                            action.shell?.interpreter = $0
                        }
                    ))
                    TextField("Script file", text: Binding(
                        get: { action.shell?.scriptFile ?? "" },
                        set: {
                            if action.shell == nil { action.shell = ShellConfig() }
                            action.shell?.scriptFile = $0
                        }
                    ))
                case .application:
                    TextField("Bundle ID", text: Binding(
                        get: { action.application?.bundleId ?? "" },
                        set: {
                            action.application = ApplicationConfig(
                                bundleId: $0,
                                pathFallback: action.application?.pathFallback
                            )
                        }
                    ))
                    TextField("Path fallback", text: Binding(
                        get: { action.application?.pathFallback ?? "" },
                        set: {
                            action.application = ApplicationConfig(
                                bundleId: action.application?.bundleId ?? "",
                                pathFallback: $0.isEmpty ? nil : $0
                            )
                        }
                    ))
                case .appleScript:
                    TextField("Script file", text: Binding(
                        get: { action.appleScript?.scriptFile ?? "" },
                        set: {
                            if action.appleScript == nil { action.appleScript = AppleScriptConfig() }
                            action.appleScript?.scriptFile = $0
                        }
                    ))
                case .builtin:
                    Text("Builtin: \(action.builtinId ?? "—")")
                }
            }

            Section {
                HStack {
                    Button("Save") { onSave() }
                        .keyboardShortcut(.defaultAction)
                    Button("Test Run") { onTest() }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ExtensionStatusView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Form {
            Section("FinderSync") {
                LabeledContent("Status") {
                    Text(state.extensionEnabledHint)
                        .textSelection(.enabled)
                        .font(.caption)
                }
                Button("Refresh Status") { state.refreshExtensionStatus() }
                Button("Open System Settings → Extensions") { state.openExtensionSettings() }
                Button("Restart Finder") { state.restartFinder() }
            }
            Section("Troubleshooting") {
                Text("""
                1. Build & run Host so the extension is embedded.
                2. System Settings → Privacy & Security → Extensions → Added Extensions → enable FinderActions.
                3. If the toggle is missing:
                   pluginkit -a "/path/to/FinderActions.app/Contents/PlugIns/FAFinderSync.appex"
                   pluginkit -e use -i \(IPCConstants.extensionBundleId)
                4. Restart Finder, then right-click a file.
                """)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            }
        }
        .formStyle(.grouped)
        .padding()
        .task { state.refreshExtensionStatus() }
    }
}

struct LogsSettingsView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Recent executions")
                    .font(.headline)
                Spacer()
                Button("Clear", role: .destructive) { state.clearLogs() }
            }
            if state.logs.isEmpty {
                ContentUnavailableView(
                    "No logs",
                    systemImage: "tray",
                    description: Text("Execution history stays on this Mac only.")
                )
            } else {
                List(state.logs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: log.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(log.success ? .green : .red)
                            Text(log.actionId).bold()
                            Spacer()
                            Text(log.timestamp).font(.caption).foregroundStyle(.secondary)
                        }
                        Text(log.summary).font(.caption)
                        if !log.paths.isEmpty {
                            Text(log.paths.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct GeneralSettingsView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state

        Form {
            Section("Preferences") {
                Toggle("Show notifications", isOn: $state.notificationsEnabled)
            }
            Section {
                FullDiskAccessGuideView()
            } header: {
                Text("Full Disk Access")
            } footer: {
                Text("macOS requires you to grant this permission yourself. FinderActions never changes system privacy settings, and Automation may still ask once before controlling a terminal app.")
            }
            Section("Data") {
                LabeledContent("Config") {
                    Text(state.store.fileURL.path)
                        .font(.caption)
                        .textSelection(.enabled)
                }
                Button("Open Application Support") {
                    NSWorkspace.shared.open(state.store.fileURL.deletingLastPathComponent())
                }
                Button("Open Scripts Folder") {
                    state.openActionsDirectory()
                }
            }
            Section("Privacy") {
                Text("No telemetry. No network client. Logs stay on this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: state.notificationsEnabled) { _, _ in state.persistSettings() }
    }
}

struct ApplicationsSettingsView: View {
    @Environment(AppState.self) private var state

    private var terminalChoices: [ExternalApplication] {
        var choices = ExternalApplicationCatalog.terminals.filter(state.isApplicationInstalled)
        if !choices.contains(where: { $0.bundleId == state.openWithSettings.terminal.bundleId }) {
            choices.append(state.openWithSettings.terminal)
        }
        return choices
    }

    private var visibleEditors: [ExternalApplication] {
        ExternalApplicationCatalog.editors.filter {
            state.isApplicationInstalled($0) || state.isEditorEnabled($0)
        }
    }

    var body: some View {
        Form {
            Section {
                Picker("Default terminal", selection: terminalSelection) {
                    ForEach(terminalChoices) { application in
                        Label(application.name, systemImage: application.sfSymbol)
                            .tag(application.id)
                    }
                }
                .pickerStyle(.menu)

                Button("Choose Terminal Application…") {
                    chooseApplications(kind: .terminal)
                }
            } header: {
                Text("Terminal")
            } footer: {
                Text("Finder always shows one “Open in Terminal” command. The selected application is shown as its subtitle.")
            }

            Section {
                if visibleEditors.isEmpty && state.customEditors.isEmpty {
                    ContentUnavailableView(
                        "No editors found",
                        systemImage: "chevron.left.forwardslash.chevron.right",
                        description: Text("Choose any application to add it as a Finder editor action.")
                    )
                } else {
                    ForEach(visibleEditors) { application in
                        ApplicationToggleRow(
                            application: application,
                            isInstalled: state.isApplicationInstalled(application),
                            isOn: editorBinding(for: application)
                        )
                    }

                    ForEach(state.customEditors) { application in
                        ApplicationToggleRow(
                            application: application,
                            isInstalled: state.isApplicationInstalled(application),
                            isOn: editorBinding(for: application)
                        )
                    }
                }

                Button("Add Editor Application…") {
                    chooseApplications(kind: .editor)
                }
            } header: {
                Text("Editors")
            } footer: {
                Text("Each selected editor gets its own Finder command. You can enable one or several.")
            }

            Section("Supported Applications") {
                LabeledContent("Terminals") {
                    Text("Terminal, iTerm2, Ghostty, Warp, WezTerm, kitty, Alacritty, Hyper")
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Editors") {
                    Text("VS Code, Cursor, Windsurf, Zed, Sublime Text, Nova, BBEdit, TextMate, CotEditor, VSCodium, Xcode, Android Studio, JetBrains IDEs, Neovide, MacVim, VimR")
                        .multilineTextAlignment(.trailing)
                }
                Text("The application picker supports any additional macOS .app, even when it is not in the built-in catalog.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var terminalSelection: Binding<String> {
        Binding(
            get: { state.openWithSettings.terminal.id },
            set: { id in
                guard let application = terminalChoices.first(where: { $0.id == id }) else { return }
                state.selectTerminal(application)
            }
        )
    }

    private func editorBinding(for application: ExternalApplication) -> Binding<Bool> {
        Binding(
            get: { state.isEditorEnabled(application) },
            set: { state.setEditor(application, enabled: $0) }
        )
    }

    private func chooseApplications(kind: ExternalApplicationKind) {
        let panel = NSOpenPanel()
        panel.title = kind == .terminal ? "Choose a Terminal" : "Choose Editor Applications"
        panel.prompt = "Choose"
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = kind == .editor

        guard panel.runModal() == .OK else { return }
        let applications = panel.urls.compactMap { externalApplication(at: $0, kind: kind) }
        if kind == .terminal, let application = applications.first {
            state.selectTerminal(application)
        } else {
            for application in applications {
                state.setEditor(application, enabled: true)
            }
        }
    }

    private func externalApplication(
        at url: URL,
        kind: ExternalApplicationKind
    ) -> ExternalApplication? {
        guard let bundle = Bundle(url: url), let bundleId = bundle.bundleIdentifier else { return nil }
        if let known = ExternalApplicationCatalog.knownApplication(bundleId: bundleId, kind: kind) {
            return known
        }
        let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? url.deletingPathExtension().lastPathComponent
        return ExternalApplication(
            id: "custom.\(bundleId)",
            name: name,
            bundleId: bundleId,
            pathFallback: url.path,
            sfSymbol: kind == .terminal ? "terminal" : "app",
            kind: kind,
            terminalLaunchMethod: kind == .terminal ? .openDirectory : nil
        )
    }
}

private struct ApplicationToggleRow: View {
    let application: ExternalApplication
    let isInstalled: Bool
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 10) {
                Image(systemName: application.sfSymbol)
                    .frame(width: 20)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(application.name)
                        if !isInstalled {
                            Text("Not installed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(application.bundleId)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        ContentUnavailableView {
            Label("FinderActions", systemImage: "hammer.fill")
        } description: {
            Text("Open-source Finder right-click actions\nNon-sandbox Host + thin FinderSync")
        } actions: {
            Link("GitHub", destination: URL(string: "https://github.com/finderactions/FinderActions")!)
            Text("MIT License")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct OnboardingView: View {
    @Environment(AppState.self) private var state
    private let onDismiss: (() -> Void)?

    init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Set up FinderActions")
                            .font(.title2.bold())
                        Text("Two quick system settings make Finder actions available across protected folders. You stay in control of both.")
                            .foregroundStyle(.secondary)
                    }

                    GroupBox("Allow access to protected folders") {
                        FullDiskAccessGuideView()
                            .padding(.top, 4)
                    }

                    GroupBox("Enable the Finder extension") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Open Extensions, enable FinderActions under Added Extensions, then return here.")
                            Button("Open Extension Settings") {
                                state.openExtensionSettings()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    }

                    Label(
                        "Then right-click a file and try Copy Path or Open in Terminal.",
                        systemImage: "cursorarrow.click.2"
                    )
                    .foregroundStyle(.secondary)
                }
                .padding(24)
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
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 560, height: 570)
    }

    private func finish() {
        state.completeOnboarding()
        onDismiss?()
    }
}

private struct FullDiskAccessGuideView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                VStack(alignment: .leading, spacing: 3) {
                    Text(FullDiskAccessSettings.isInstalledInApplications
                         ? "FinderActions is ready to add"
                         : "Move FinderActions to Applications first")
                        .fontWeight(.medium)
                    Text(installationMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: FullDiskAccessSettings.isInstalledInApplications
                      ? "checkmark.circle.fill"
                      : "exclamationmark.triangle.fill")
                    .foregroundStyle(FullDiskAccessSettings.isInstalledInApplications ? .green : .orange)
            }

            Text("Full Disk Access lets actions work with protected locations without asking you to choose the same folders repeatedly.")

            LabeledContent("Current app") {
                Text(FullDiskAccessSettings.applicationURL.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("1. Open Full Disk Access.")
                Text("2. Click + and select FinderActions.app, or drag the revealed app into the list.")
                Text("3. Turn FinderActions on. If macOS asks to quit and reopen it, allow that.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                Button("Show FinderActions in Finder") {
                    FullDiskAccessSettings.revealApplication()
                }
                Button("Open Full Disk Access") {
                    FullDiskAccessSettings.openSystemSettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var installationMessage: String {
        if FullDiskAccessSettings.isInstalledInApplications {
            return "Grant access to this stable copy once."
        }
        return "A build or Downloads copy can move after an update, causing macOS to treat it as a different app."
    }
}
