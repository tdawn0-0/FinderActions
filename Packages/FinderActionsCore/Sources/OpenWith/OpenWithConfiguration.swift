import Foundation

public enum ExternalApplicationKind: String, Codable, Sendable {
    case terminal
    case editor
}

/// A launch target displayed in Settings. Catalog and user-selected apps share
/// the same value type, so the rest of the system never branches on provenance.
public struct ExternalApplication: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public var name: String
    public var bundleId: String
    public var pathFallback: String?
    public var sfSymbol: String
    public var kind: ExternalApplicationKind
    public var terminalLaunchMethod: TerminalLaunchMethod?
    public var terminalArguments: [String]

    public init(
        id: String,
        name: String,
        bundleId: String,
        pathFallback: String? = nil,
        sfSymbol: String,
        kind: ExternalApplicationKind,
        terminalLaunchMethod: TerminalLaunchMethod? = nil,
        terminalArguments: [String] = []
    ) {
        self.id = id
        self.name = name
        self.bundleId = bundleId
        self.pathFallback = pathFallback
        self.sfSymbol = sfSymbol
        self.kind = kind
        self.terminalLaunchMethod = terminalLaunchMethod
        self.terminalArguments = terminalArguments
    }

    public var applicationConfig: ApplicationConfig {
        ApplicationConfig(bundleId: bundleId, pathFallback: pathFallback)
    }
}

public struct OpenWithSettings: Codable, Sendable, Equatable {
    public var terminal: ExternalApplication
    public var editors: [ExternalApplication]

    public init(terminal: ExternalApplication, editors: [ExternalApplication]) {
        self.terminal = terminal
        self.editors = editors
    }

    public static var defaults: OpenWithSettings {
        OpenWithSettings(
            terminal: ExternalApplicationCatalog.terminals[0],
            editors: [ExternalApplicationCatalog.editors[0]]
        )
    }
}

/// Curated launch metadata for common macOS terminals and editors. Any .app can
/// also be selected in Settings, so catalog growth is an enhancement, not a gate.
public enum ExternalApplicationCatalog {
    public static let terminals: [ExternalApplication] = [
        terminal("apple-terminal", "Apple Terminal", "com.apple.Terminal", "/System/Applications/Utilities/Terminal.app", .appleTerminal),
        terminal("iterm2", "iTerm2", "com.googlecode.iterm2", "/Applications/iTerm.app", .iTerm),
        terminal("ghostty", "Ghostty", "com.mitchellh.ghostty", "/Applications/Ghostty.app", .ghostty),
        terminal("warp", "Warp", "dev.warp.Warp-Stable", "/Applications/Warp.app", .openDirectory),
        terminal("wezterm", "WezTerm", "com.github.wez.wezterm", "/Applications/WezTerm.app", .openDirectory),
        terminal("kitty", "kitty", "net.kovidgoyal.kitty", "/Applications/kitty.app", .applicationExecutable, ["--directory", "{path}"]),
        terminal("alacritty", "Alacritty", "org.alacritty", "/Applications/Alacritty.app", .applicationExecutable, ["--working-directory", "{path}"]),
        terminal("hyper", "Hyper", "co.zeit.hyper", "/Applications/Hyper.app", .openDirectory),
    ]

    public static let editors: [ExternalApplication] = [
        editor("vscode", "Visual Studio Code", "com.microsoft.VSCode", "/Applications/Visual Studio Code.app", "chevron.left.forwardslash.chevron.right"),
        editor("vscode-insiders", "Visual Studio Code Insiders", "com.microsoft.VSCodeInsiders", "/Applications/Visual Studio Code - Insiders.app", "chevron.left.forwardslash.chevron.right"),
        editor("cursor", "Cursor", "com.todesktop.230313mzl4w4u92", "/Applications/Cursor.app", "cursorarrow"),
        editor("windsurf", "Windsurf", "com.exafunction.windsurf", "/Applications/Windsurf.app", "wind"),
        editor("zed", "Zed", "dev.zed.Zed", "/Applications/Zed.app", "bolt.horizontal"),
        editor("sublime-text", "Sublime Text", "com.sublimetext.4", "/Applications/Sublime Text.app", "text.cursor"),
        editor("nova", "Nova", "com.panic.Nova", "/Applications/Nova.app", "sparkles"),
        editor("bbedit", "BBEdit", "com.barebones.bbedit", "/Applications/BBEdit.app", "doc.text"),
        editor("textmate", "TextMate", "com.macromates.TextMate", "/Applications/TextMate.app", "doc.plaintext"),
        editor("coteditor", "CotEditor", "com.coteditor.CotEditor", "/Applications/CotEditor.app", "text.alignleft"),
        editor("vscodium", "VSCodium", "com.vscodium", "/Applications/VSCodium.app", "chevron.left.forwardslash.chevron.right"),
        editor("xcode", "Xcode", "com.apple.dt.Xcode", "/Applications/Xcode.app", "hammer"),
        editor("android-studio", "Android Studio", "com.google.android.studio", "/Applications/Android Studio.app", "shippingbox"),
        editor("intellij", "IntelliJ IDEA", "com.jetbrains.intellij", "/Applications/IntelliJ IDEA.app", "square.stack.3d.up"),
        editor("webstorm", "WebStorm", "com.jetbrains.WebStorm", "/Applications/WebStorm.app", "globe"),
        editor("pycharm", "PyCharm", "com.jetbrains.pycharm", "/Applications/PyCharm.app", "chevron.left.forwardslash.chevron.right"),
        editor("goland", "GoLand", "com.jetbrains.goland", "/Applications/GoLand.app", "chevron.left.forwardslash.chevron.right"),
        editor("rider", "Rider", "com.jetbrains.rider", "/Applications/Rider.app", "chevron.left.forwardslash.chevron.right"),
        editor("rustrover", "RustRover", "com.jetbrains.rustrover", "/Applications/RustRover.app", "chevron.left.forwardslash.chevron.right"),
        editor("fleet", "Fleet", "com.jetbrains.fleet", "/Applications/Fleet.app", "square.grid.2x2"),
        editor("neovide", "Neovide", "com.neovide.neovide", "/Applications/Neovide.app", "terminal"),
        editor("macvim", "MacVim", "org.vim.MacVim", "/Applications/MacVim.app", "terminal"),
        editor("vimr", "VimR", "com.qvacua.VimR", "/Applications/VimR.app", "terminal"),
    ]

    public static func knownApplication(bundleId: String, kind: ExternalApplicationKind) -> ExternalApplication? {
        let source = kind == .terminal ? terminals : editors
        return source.first { $0.bundleId == bundleId }
    }

    private static func terminal(
        _ id: String,
        _ name: String,
        _ bundleId: String,
        _ path: String,
        _ method: TerminalLaunchMethod,
        _ arguments: [String] = []
    ) -> ExternalApplication {
        ExternalApplication(
            id: id,
            name: name,
            bundleId: bundleId,
            pathFallback: path,
            sfSymbol: "terminal",
            kind: .terminal,
            terminalLaunchMethod: method,
            terminalArguments: arguments
        )
    }

    private static func editor(
        _ id: String,
        _ name: String,
        _ bundleId: String,
        _ path: String,
        _ symbol: String
    ) -> ExternalApplication {
        ExternalApplication(
            id: id,
            name: name,
            bundleId: bundleId,
            pathFallback: path,
            sfSymbol: symbol,
            kind: .editor
        )
    }
}

/// Deep module for the Finder-facing "Open With" behavior. Callers provide
/// settings and a base manifest; this module owns all generated IDs, ordering,
/// labels, and the invariant that exactly one terminal action exists.
public enum OpenWithActions {
    public static let terminalActionId = "open-with.terminal"
    public static let editorActionPrefix = "open-with.editor."

    private static let obsoleteBuiltInIds: Set<String> = [
        "open-terminal", "open-iterm", "open-ghostty", "open-vscode", "open-cursor",
    ]

    public static func baseManifest(from manifest: ActionManifest) -> ActionManifest {
        var result = manifest
        result.version = 2
        result.actions.removeAll { action in
            action.type == .terminal
                || obsoleteBuiltInIds.contains(action.id)
                || action.id.hasPrefix("open-with.")
        }
        return result
    }

    public static func compose(
        baseManifest: ActionManifest,
        settings: OpenWithSettings
    ) -> ActionManifest {
        var result = OpenWithActions.baseManifest(from: baseManifest)
        var generated = [terminalAction(settings.terminal)]
        generated.append(contentsOf: settings.editors.enumerated().map(editorAction))
        result.actions.append(contentsOf: generated)
        return result
    }

    private static func terminalAction(_ app: ExternalApplication) -> ActionDefinition {
        ActionDefinition(
            id: terminalActionId,
            name: "Open in Terminal",
            subtitle: app.name,
            type: .terminal,
            enabled: true,
            sortIndex: 10,
            group: "Develop",
            icon: ActionIcon(sfSymbol: app.sfSymbol, appBundleId: app.bundleId),
            showWhen: .always,
            terminal: TerminalConfig(
                application: app.applicationConfig,
                launchMethod: app.terminalLaunchMethod ?? .openDirectory,
                arguments: app.terminalArguments
            )
        )
    }

    private static func editorAction(index: Int, app: ExternalApplication) -> ActionDefinition {
        ActionDefinition(
            id: editorActionPrefix + app.id,
            name: "Open in \(app.name)",
            type: .application,
            enabled: true,
            sortIndex: 11 + index,
            group: "Develop",
            icon: ActionIcon(sfSymbol: app.sfSymbol, appBundleId: app.bundleId),
            showWhen: .always,
            application: app.applicationConfig
        )
    }
}
