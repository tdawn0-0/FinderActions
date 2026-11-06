import Foundation

public enum ActionTemplate: String, CaseIterable, Sendable {
    case perFile, currentDirectory, application, blank

    public func make(id: String, sortIndex: Int) -> ActionDefinition {
        let name: String
        let type: ActionType
        let source: String?
        switch self {
        case .perFile:
            name = "Process Selected Files"; type = .shell
            source = "#!/bin/zsh\nset -euo pipefail\nfor file in \"$@\"; do\n  print -r -- \"$file\"\n  # Add your command here, using \"$file\".\ndone\n"
        case .currentDirectory:
            name = "Run in Current Directory"; type = .shell
            source = "#!/bin/zsh\nset -euo pipefail\n# The working directory is FA_CWD.\npwd\n# Add your command here.\n"
        case .application: name = "Open with Application"; type = .application; source = nil
        case .blank: name = "New Action"; type = .shell; source = "#!/bin/zsh\n"
        }
        return ActionDefinition(id: id, name: name, type: type, enabled: false, sortIndex: sortIndex,
                                group: "Custom", icon: ActionIcon(sfSymbol: type == .shell ? "terminal" : "app"),
                                showWhen: self == .perFile ? .filesOnly : .always,
                                shell: source.map { ShellConfig(scriptInline: $0) })
    }
}

public enum ActionAuthoring {
    public static func normalizedExtensions(_ text: String) -> [String] {
        Array(Set(text.components(separatedBy: CharacterSet(charactersIn: ",; \n"))
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased() }
            .filter { !$0.isEmpty })).sorted()
    }

    /// Structural checks only; filesystem availability is checked again before execution.
    public static func validationError(_ action: ActionDefinition) -> String? {
        if action.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Enter an action name." }
        if let rules = action.extRules {
            if (rules.foldersOnly && action.showWhen == .filesOnly) || (rules.filesOnly && action.showWhen == .foldersOnly) {
                return "Show When and Input Kind must use compatible file or folder rules."
            }
            if rules.filesOnly && rules.foldersOnly { return "Choose either files or folders." }
            if rules.foldersOnly && !rules.pathExtensions.isEmpty { return "Extension filters apply to files; clear the folder-only rule." }
            if rules.pathExtensions.contains(where: { $0.contains("/") || $0.contains("\\") }) { return "Enter extensions without paths." }
        }
        switch action.type {
        case .shell:
            guard let shell = action.shell,
                  !(shell.scriptFile ?? "").isEmpty || !(shell.scriptInline ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "Choose a script file or enter an inline script." }
        case .appleScript:
            guard let script = action.appleScript,
                  !(script.scriptFile ?? "").isEmpty || !(script.scriptInline ?? "").isEmpty else { return "Choose a script file or enter an inline script." }
        case .application:
            guard let app = action.application, !app.bundleId.isEmpty || !(app.pathFallback ?? "").isEmpty else { return "Choose an application." }
        case .builtin: return "This built-in action is not supported."
        case .terminal: break
        }
        return nil
    }

    /// Switching to inline removes the file reference that otherwise takes priority.
    /// Switching to file preserves the inline draft until a file is chosen.
    public static func useInline(_ action: inout ActionDefinition) {
        if action.type == .shell { action.shell?.scriptFile = nil }
        if action.type == .appleScript { action.appleScript?.scriptFile = nil }
    }
}
