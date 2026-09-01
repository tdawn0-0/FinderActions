import Foundation

// MARK: - Action types

public enum ActionType: String, Codable, Sendable, CaseIterable {
    case application
    case shell
    case terminal
    case appleScript
    case builtin
}

public enum ShowWhen: String, Codable, Sendable, CaseIterable {
    case always
    case filesOnly
    case foldersOnly
    case single
    case multiple
}

public struct ActionIcon: Codable, Sendable, Equatable {
    public var sfSymbol: String?
    public var appBundleId: String?

    public init(sfSymbol: String? = nil, appBundleId: String? = nil) {
        self.sfSymbol = sfSymbol
        self.appBundleId = appBundleId
    }
}

public struct ShellConfig: Codable, Sendable, Equatable {
    public var interpreter: String
    public var scriptFile: String?
    public var scriptInline: String?

    public init(interpreter: String = "/bin/zsh", scriptFile: String? = nil, scriptInline: String? = nil) {
        self.interpreter = interpreter
        self.scriptFile = scriptFile
        self.scriptInline = scriptInline
    }
}

public struct ApplicationConfig: Codable, Sendable, Equatable {
    public var bundleId: String
    public var pathFallback: String?

    public init(bundleId: String, pathFallback: String? = nil) {
        self.bundleId = bundleId
        self.pathFallback = pathFallback
    }
}

public enum TerminalLaunchMethod: String, Codable, Sendable, CaseIterable {
    case appleTerminal
    case iTerm
    case ghostty
    case applicationExecutable
    case openDirectory
}

public struct TerminalConfig: Codable, Sendable, Equatable {
    public var application: ApplicationConfig
    public var launchMethod: TerminalLaunchMethod
    /// Arguments passed directly to the application's executable. `{path}` is
    /// replaced with the Finder working directory without shell interpolation.
    public var arguments: [String]

    public init(
        application: ApplicationConfig,
        launchMethod: TerminalLaunchMethod,
        arguments: [String] = []
    ) {
        self.application = application
        self.launchMethod = launchMethod
        self.arguments = arguments
    }
}

public struct AppleScriptConfig: Codable, Sendable, Equatable {
    public var scriptFile: String?
    public var scriptInline: String?

    public init(scriptFile: String? = nil, scriptInline: String? = nil) {
        self.scriptFile = scriptFile
        self.scriptInline = scriptInline
    }
}

public struct ExtRules: Codable, Sendable, Equatable {
    public var pathExtensions: [String]
    public var foldersOnly: Bool
    public var filesOnly: Bool

    public init(pathExtensions: [String] = [], foldersOnly: Bool = false, filesOnly: Bool = false) {
        self.pathExtensions = pathExtensions
        self.foldersOnly = foldersOnly
        self.filesOnly = filesOnly
    }
}

/// A single user-defined or built-in action.
public struct ActionDefinition: Codable, Sendable, Identifiable, Equatable {
    public var id: String
    public var name: String
    public var subtitle: String?
    public var type: ActionType
    public var enabled: Bool
    public var sortIndex: Int
    public var group: String?
    public var icon: ActionIcon?
    public var showWhen: ShowWhen
    public var extRules: ExtRules?

    // Type-specific
    public var terminal: TerminalConfig?
    public var shell: ShellConfig?
    public var application: ApplicationConfig?
    public var appleScript: AppleScriptConfig?
    /// For `builtin` type: e.g. "cut-add", "cut-move-here", "cut-copy-here", "cut-clear"
    public var builtinId: String?

    public init(
        id: String,
        name: String,
        subtitle: String? = nil,
        type: ActionType,
        enabled: Bool = true,
        sortIndex: Int = 0,
        group: String? = nil,
        icon: ActionIcon? = nil,
        showWhen: ShowWhen = .always,
        extRules: ExtRules? = nil,
        terminal: TerminalConfig? = nil,
        shell: ShellConfig? = nil,
        application: ApplicationConfig? = nil,
        appleScript: AppleScriptConfig? = nil,
        builtinId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.type = type
        self.enabled = enabled
        self.sortIndex = sortIndex
        self.group = group
        self.icon = icon
        self.showWhen = showWhen
        self.extRules = extRules
        self.terminal = terminal
        self.shell = shell
        self.application = application
        self.appleScript = appleScript
        self.builtinId = builtinId
    }
}

// MARK: - Manifest

public struct ActionManifest: Codable, Sendable, Equatable {
    public var version: Int
    public var actions: [ActionDefinition]

    public init(version: Int = 2, actions: [ActionDefinition] = []) {
        self.version = version
        self.actions = actions
    }
}
