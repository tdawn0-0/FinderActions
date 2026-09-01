import Foundation
import AppKit
import FinderActionsCore

private final class LockedErrorBox: @unchecked Sendable {
    private let lock = NSLock()
    private var storedError: Error?

    func store(_ error: Error?) {
        lock.lock()
        storedError = error
        lock.unlock()
    }

    func load() -> Error? {
        lock.lock()
        defer { lock.unlock() }
        return storedError
    }
}

public struct ExecResult: Sendable {
    public var success: Bool
    public var summary: String
    public var exitCode: Int32
    public var stdout: String
    public var stderr: String

    public init(success: Bool, summary: String, exitCode: Int32 = 0, stdout: String = "", stderr: String = "") {
        self.success = success
        self.summary = summary
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }
}

public struct ExecLogEntry: Codable, Identifiable, Sendable, Equatable {
    public var id: String
    public var timestamp: String
    public var actionId: String
    public var success: Bool
    public var summary: String
    public var paths: [String]

    public init(id: String = UUID().uuidString, timestamp: String = ISO8601DateFormatter().string(from: Date()), actionId: String, success: Bool, summary: String, paths: [String]) {
        self.id = id
        self.timestamp = timestamp
        self.actionId = actionId
        self.success = success
        self.summary = summary
        self.paths = paths
    }
}

/// Sole executor for all action types. The Host owns production execution;
/// Settings uses it only for explicit test runs.
public final class ActionExecutor: @unchecked Sendable {
    public let store: ManifestStore

    public init(store: ManifestStore) {
        self.store = store
    }

    public func execute(action: ActionDefinition, paths: [String], containerPath: String?) -> ExecResult {
        let resolvedPaths: [String]
        if paths.isEmpty, let containerPath, !containerPath.isEmpty {
            resolvedPaths = [containerPath]
        } else {
            resolvedPaths = paths
        }

        switch action.type {
        case .application:
            return runApplication(action: action, paths: resolvedPaths)
        case .shell:
            return runShell(action: action, paths: resolvedPaths, containerPath: containerPath)
        case .terminal:
            return runTerminal(action: action, paths: resolvedPaths, containerPath: containerPath)
        case .appleScript:
            return runAppleScript(action: action, paths: resolvedPaths, containerPath: containerPath)
        case .builtin:
            return ExecResult(
                success: false,
                summary: "Builtin action '\(action.builtinId ?? "?")' not implemented in P0",
                exitCode: 1
            )
        }
    }

    public func execute(request: ExecuteRequest, manifest: ActionManifest) -> ExecResult {
        guard let action = manifest.actions.first(where: { $0.id == request.actionId }) else {
            return ExecResult(success: false, summary: "Unknown action: \(request.actionId)", exitCode: 1)
        }
        guard action.enabled else {
            return ExecResult(success: false, summary: "Action disabled: \(request.actionId)", exitCode: 1)
        }
        return execute(action: action, paths: request.paths, containerPath: request.containerPath)
    }

    // MARK: - Application

    private func runApplication(action: ActionDefinition, paths: [String]) -> ExecResult {
        guard let config = action.application else {
            return ExecResult(success: false, summary: "Missing application config", exitCode: 1)
        }
        let appURL = applicationURL(for: config)
        guard let appURL else {
            return ExecResult(success: false, summary: "App not found: \(config.bundleId)", exitCode: 1)
        }
        let fileURLs = paths.map { URL(fileURLWithPath: $0) }
        let configOpen = NSWorkspace.OpenConfiguration()
        let sem = DispatchSemaphore(value: 0)
        let errorBox = LockedErrorBox()
        NSWorkspace.shared.open(fileURLs, withApplicationAt: appURL, configuration: configOpen) { _, error in
            errorBox.store(error)
            sem.signal()
        }
        guard sem.wait(timeout: .now() + 10) == .success else {
            return ExecResult(success: false, summary: "Timed out opening \(action.name)", exitCode: 1)
        }
        if let err = errorBox.load() {
            return ExecResult(success: false, summary: err.localizedDescription, exitCode: 1)
        }
        return ExecResult(success: true, summary: "Opened with \(action.name)")
    }

    // MARK: - Shell

    private func runShell(action: ActionDefinition, paths: [String], containerPath: String?) -> ExecResult {
        guard let shell = action.shell else {
            return ExecResult(success: false, summary: "Missing shell config", exitCode: 1)
        }
        let interpreter = shell.interpreter.isEmpty ? "/bin/zsh" : shell.interpreter
        let env = ShellEnvironment.makeEnvironment(
            paths: paths,
            containerPath: containerPath,
            actionId: action.id
        )
        let cwd = ShellEnvironment.resolvedWorkingDirectory(paths: paths, containerPath: containerPath)

        let argv: [String]
        if let file = shell.scriptFile, !file.isEmpty {
            let scriptPath = store.resolveScriptPath(file).path
            guard FileManager.default.fileExists(atPath: scriptPath) else {
                return ExecResult(success: false, summary: "Script not found: \(scriptPath)", exitCode: 1)
            }
            argv = ShellEnvironment.argvForScriptFile(interpreter: interpreter, scriptPath: scriptPath, paths: paths)
        } else if let inline = shell.scriptInline, !inline.isEmpty {
            argv = ShellEnvironment.argvForInlineScript(interpreter: interpreter, script: inline, paths: paths)
        } else {
            return ExecResult(success: false, summary: "Shell action has no script", exitCode: 1)
        }

        return runProcess(argv: argv, env: env, cwd: cwd)
    }

    // MARK: - Terminal

    private func runTerminal(action: ActionDefinition, paths: [String], containerPath: String?) -> ExecResult {
        guard let terminal = action.terminal else {
            return ExecResult(success: false, summary: "Missing terminal config", exitCode: 1)
        }
        guard let appURL = applicationURL(for: terminal.application) else {
            return ExecResult(
                success: false,
                summary: "Terminal not found: \(terminal.application.bundleId)",
                exitCode: 1
            )
        }
        let cdPath = ShellEnvironment.terminalCDPath(paths: paths, containerPath: containerPath)
        let cdQuoted = ShellEnvironment.singleQuote(cdPath)
        let shellCommand = "cd \(cdQuoted)"

        switch terminal.launchMethod {
        case .appleTerminal:
            return runTerminalApp(command: shellCommand)
        case .iTerm:
            return runITerm(command: shellCommand)
        case .ghostty:
            return runGhostty(path: cdPath)
        case .applicationExecutable:
            let arguments = terminal.arguments.map { $0.replacingOccurrences(of: "{path}", with: cdPath) }
            return launchApplicationExecutable(appURL, arguments: arguments, cwd: cdPath)
        case .openDirectory:
            return openDirectory(cdPath, with: appURL, appName: action.subtitle ?? action.name)
        }
    }

    private func runTerminalApp(command: String) -> ExecResult {
        let script = """
        tell application "Terminal"
          activate
          do script \(appleScriptString(command))
        end tell
        """
        return runOsascript(script)
    }

    private func runITerm(command: String) -> ExecResult {
        let script = """
        tell application "iTerm"
          activate
          try
            set newWindow to (create window with default profile)
            tell current session of newWindow
              write text \(appleScriptString(command))
            end tell
          on error
            tell current session of current window
              write text \(appleScriptString(command))
            end tell
          end try
        end tell
        """
        return runOsascript(script)
    }

    private func runGhostty(path: String) -> ExecResult {
        let script = """
        tell application "Ghostty"
          activate
          set cfg to new surface configuration
          set initial working directory of cfg to \(appleScriptString(path))
          new window with configuration cfg
        end tell
        """
        return runOsascript(script)
    }

    private func launchApplicationExecutable(
        _ appURL: URL,
        arguments: [String],
        cwd: String
    ) -> ExecResult {
        guard let executableURL = Bundle(url: appURL)?.executableURL else {
            return ExecResult(success: false, summary: "Application executable not found", exitCode: 1)
        }
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        process.environment = ProcessInfo.processInfo.environment
        process.currentDirectoryURL = URL(fileURLWithPath: cwd)
        do {
            try process.run()
            return ExecResult(success: true, summary: "Opened \(appURL.deletingPathExtension().lastPathComponent) at \(cwd)")
        } catch {
            return ExecResult(success: false, summary: error.localizedDescription, exitCode: 1)
        }
    }

    private func openDirectory(_ path: String, with appURL: URL, appName: String) -> ExecResult {
        let conf = NSWorkspace.OpenConfiguration()
        let sem = DispatchSemaphore(value: 0)
        let errorBox = LockedErrorBox()
        NSWorkspace.shared.open(
            [URL(fileURLWithPath: path)],
            withApplicationAt: appURL,
            configuration: conf
        ) { _, error in
            errorBox.store(error)
            sem.signal()
        }
        guard sem.wait(timeout: .now() + 10) == .success else {
            return ExecResult(success: false, summary: "Timed out opening \(appName)", exitCode: 1)
        }
        if let launchError = errorBox.load() {
            return ExecResult(success: false, summary: launchError.localizedDescription, exitCode: 1)
        }
        return ExecResult(success: true, summary: "Opened \(appName) at \(path)")
    }

    private func applicationURL(for config: ApplicationConfig) -> URL? {
        if let registered = NSWorkspace.shared.urlForApplication(withBundleIdentifier: config.bundleId) {
            return registered
        }
        guard let fallback = config.pathFallback else { return nil }
        let url = URL(fileURLWithPath: fallback)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - AppleScript

    private func runAppleScript(action: ActionDefinition, paths: [String], containerPath: String?) -> ExecResult {
        guard let cfg = action.appleScript else {
            return ExecResult(success: false, summary: "Missing appleScript config", exitCode: 1)
        }
        let source: String
        if let file = cfg.scriptFile, !file.isEmpty {
            let path = store.resolveScriptPath(file).path
            guard let body = try? String(contentsOfFile: path, encoding: .utf8) else {
                return ExecResult(success: false, summary: "AppleScript file not found: \(path)", exitCode: 1)
            }
            source = body
        } else if let inline = cfg.scriptInline, !inline.isEmpty {
            source = inline
        } else {
            return ExecResult(success: false, summary: "AppleScript action has no script", exitCode: 1)
        }

        // Inject paths as AppleScript list via environment for simple scripts;
        // also write a temp wrapper that sets path variables.
        let pathList = paths.map(appleScriptString).joined(separator: ", ")
        let wrapper = """
        set faPaths to {\(pathList)}
        set faContainer to \(appleScriptString(containerPath ?? ""))
        set faActionId to \(appleScriptString(action.id))
        \(source)
        """
        return runOsascript(wrapper)
    }

    private func runOsascript(_ source: String) -> ExecResult {
        let argv = ["/usr/bin/osascript", "-e", source]
        return runProcess(argv: argv, env: ProcessInfo.processInfo.environment, cwd: FileManager.default.currentDirectoryPath)
    }

    private func appleScriptString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    // MARK: - Process

    /// Shared Process runner — argv is already split (no shell string concat of paths).
    public func runProcess(argv: [String], env: [String: String], cwd: String) -> ExecResult {
        guard let exe = argv.first else {
            return ExecResult(success: false, summary: "Empty argv", exitCode: 1)
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: exe)
        process.arguments = Array(argv.dropFirst())
        process.environment = env
        process.currentDirectoryURL = URL(fileURLWithPath: cwd)

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ExecResult(success: false, summary: error.localizedDescription, exitCode: 1)
        }

        let stdout = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let code = process.terminationStatus
        let success = code == 0
        let firstLine = stdout.split(separator: "\n", omittingEmptySubsequences: true).first.map(String.init)
        let summary = success
            ? (firstLine ?? "OK")
            : (stderr.split(separator: "\n").first.map(String.init) ?? "Exit \(code)")
        return ExecResult(success: success, summary: summary, exitCode: code, stdout: stdout, stderr: stderr)
    }
}
