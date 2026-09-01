import SwiftUI
import AppKit
import FinderActionsCore

struct MenuBarPopoverView: View {
    @Environment(AppState.self) private var state
    @Environment(\.openWindow) private var openWindow
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var hoveredActionId: String?
    @State private var testingActionId: String?

    private var activeActionsCount: Int {
        state.manifest.actions.filter(\.enabled).count
    }

    private var filteredActions: [ActionDefinition] {
        let sorted = state.manifest.actions.sorted(by: { $0.sortIndex < $1.sortIndex })
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return sorted
        }
        return sorted.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.subtitle?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.group?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var isExtensionReady: Bool {
        state.extensionEnabledHint.contains("Registered") && !state.extensionEnabledHint.contains("Not")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerView

            Divider()
                .opacity(0.6)

            // Segment Tabs & Search
            tabAndSearchSection

            Divider()
                .opacity(0.4)

            // Main Content Area
            Group {
                if selectedTab == 0 {
                    actionsContentView
                } else {
                    logsContentView
                }
            }
            .frame(maxHeight: .infinity)

            Divider()
                .opacity(0.6)

            // Footer Section
            footerView
        }
        .frame(width: 340, height: 460)
        .background(.ultraThinMaterial)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 10) {
            // App Icon Badge
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color.blue, Color.purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 28, height: 28)
                    .shadow(color: Color.blue.opacity(0.3), radius: 3, y: 1)

                Image(systemName: "hammer.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text("FinderActions")
                        .font(.system(size: 13, weight: .semibold))

                    Circle()
                        .fill(isExtensionReady ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                }

                Text(isExtensionReady ? "\(activeActionsCount) actions ready in Finder" : "Extension setup required")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            // Header Action Buttons
            HStack(spacing: 4) {
                Button {
                    state.openActionsDirectory()
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 12))
                        .padding(5)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Open Scripts Folder")

                Button {
                    openWindow(id: "settings")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12))
                        .padding(5)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Open Settings")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
    }

    // MARK: - Tab & Search Section

    private var tabAndSearchSection: some View {
        VStack(spacing: 8) {
            Picker("", selection: $selectedTab) {
                Text("Actions (\(state.manifest.actions.count))").tag(0)
                Text("Recent Logs (\(state.logs.count))").tag(1)
            }
            .pickerStyle(.segmented)
            .controlSize(.small)

            if selectedTab == 0 {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)

                    TextField("Filter actions…", text: $searchText)
                        .font(.system(size: 11))
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Actions Content View

    private var actionsContentView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            if filteredActions.isEmpty {
                VStack(spacing: 8) {
                    Spacer(minLength: 40)
                    Image(systemName: "bolt.slash")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.secondary)
                    Text("No actions found")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 3) {
                    ForEach(filteredActions) { action in
                        modernActionRow(action: action)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
    }

    private func modernActionRow(action: ActionDefinition) -> some View {
        let isHovered = hoveredActionId == action.id
        let isTesting = testingActionId == action.id

        return HStack(spacing: 8) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(typeColor(for: action.type).opacity(action.enabled ? 0.15 : 0.08))
                Image(systemName: action.icon?.sfSymbol ?? "bolt")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(action.enabled ? typeColor(for: action.type) : Color.secondary)
            }
            .frame(width: 24, height: 24)

            // Details
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(action.name)
                        .font(.system(size: 12, weight: action.enabled ? .medium : .regular))
                        .foregroundStyle(action.enabled ? Color.primary : Color.secondary)
                        .lineLimit(1)

                    if let group = action.group, !group.isEmpty {
                        Text(group)
                            .font(.system(size: 9))
                            .padding(.horizontal, 3)
                            .padding(.vertical, 0.5)
                            .background(Color.secondary.opacity(0.1))
                            .foregroundStyle(Color.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }

                if let sub = action.subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            // Hover quick run test button
            if isHovered && action.enabled {
                Button {
                    quickTest(action: action)
                } label: {
                    Image(systemName: isTesting ? "hourglass" : "play.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.blue)
                        .padding(4)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isTesting)
                .help("Test run with Home folder")
                .transition(.opacity.combined(with: .scale))
            }

            // Enable switch
            Toggle("", isOn: Binding(
                get: { action.enabled },
                set: { state.setEnabled(actionId: action.id, enabled: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.mini)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            hoveredActionId = hovering ? action.id : nil
        }
    }

    // MARK: - Logs Content View

    private var logsContentView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            if state.logs.isEmpty {
                VStack(spacing: 8) {
                    Spacer(minLength: 40)
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.secondary)
                    Text("No execution logs yet")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                    Text("Actions run from Finder will be recorded here.")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondary.opacity(0.8))
                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(state.logs.prefix(20)) { log in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: log.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(log.success ? Color.green : Color.red)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 1) {
                                HStack {
                                    Text(log.actionId)
                                        .font(.system(size: 11, weight: .semibold))
                                    Spacer()
                                    Text(log.timestamp)
                                        .font(.system(size: 9))
                                        .foregroundStyle(Color.secondary)
                                }

                                Text(log.summary)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.primary.opacity(0.85))

                                if let firstPath = log.paths.first {
                                    Text((firstPath as NSString).lastPathComponent)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        }
                        .padding(6)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Button {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                    Text("Manage Actions…")
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))

            Spacer()

            Button {
                state.restartFinder()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .help("Restart Finder")

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(Color.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))
    }

    // MARK: - Helpers

    private func typeColor(for type: ActionType) -> Color {
        switch type {
        case .shell: return .blue
        case .terminal: return .purple
        case .application: return .green
        case .appleScript: return .orange
        case .builtin: return .pink
        }
    }

    private func quickTest(action: ActionDefinition) {
        testingActionId = action.id
        let executor = state.executor
        Task {
            let res = await Task.detached {
                executor.execute(
                    action: action,
                    paths: [NSHomeDirectory()],
                    containerPath: NSHomeDirectory()
                )
            }.value
            await MainActor.run {
                state.recordLog(ExecLogEntry(
                    actionId: action.id,
                    success: res.success,
                    summary: "Quick Test: \(res.summary)",
                    paths: [NSHomeDirectory()]
                ))
                testingActionId = nil
            }
        }
    }
}
