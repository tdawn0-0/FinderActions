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

public enum ExecutionSource: String, Codable, Sendable { case finder, test }

public struct ExecLogEntry: Codable, Identifiable, Sendable, Equatable {
    public var id: String
    public var timestamp: String
    public var actionId: String
    public var success: Bool
    public var summary: String
    public var paths: [String]
    public var stderrTail: String?
    public var actionName: String?
    public var durationSeconds: Double?
    public var source: ExecutionSource?

    public init(id: String = UUID().uuidString, timestamp: String = ISO8601DateFormatter().string(from: Date()), actionId: String, success: Bool, summary: String, paths: [String], stderrTail: String? = nil, actionName: String? = nil, durationSeconds: Double? = nil, source: ExecutionSource? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.actionId = actionId
        self.success = success
        self.summary = summary
        self.paths = paths
        self.stderrTail = stderrTail
        self.actionName = actionName
        self.durationSeconds = durationSeconds
        self.source = source
    }
}

/// Sole executor for all action types. The Host owns production execution;
/// Settings uses it only for explicit test runs.
public final class ActionExecutor: @unchecked Sendable {
    public let store: ManifestStore
    public let cutBuffer: CutBuffer
    private let writePasteboardURLs: @Sendable ([String]) -> Void

    public init(
        store: ManifestStore,
        cutBuffer: CutBuffer = CutBuffer(),
        writePasteboardURLs: @escaping @Sendable ([String]) -> Void = ActionExecutor.defaultWritePasteboardURLs
    ) {
        self.store = store
        self.cutBuffer = cutBuffer
        self.writePasteboardURLs = writePasteboardURLs
    }

    /// Mirrors the cut selection onto the system pasteboard so Finder's native
    /// Option-Command-V also works. Pasteboard access is serialized on the main thread.
    public static let defaultWritePasteboardURLs: @Sendable ([String]) -> Void = { paths in
        let write = {
            let urls = paths.map { URL(fileURLWithPath: $0) as NSURL }
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects(urls)
        }
        if Thread.isMainThread { write() } else { DispatchQueue.main.sync { write() } }
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
            return runBuiltin(action: action, rawPaths: paths, resolvedPaths: resolvedPaths)
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

    // MARK: - Built-in (Cut)

    private func runBuiltin(action: ActionDefinition, rawPaths: [String], resolvedPaths: [String]) -> ExecResult {
        guard let builtin = CutBuiltinID(rawValue: action.builtinId ?? "") else {
            return ExecResult(success: false, summary: "Unsupported built-in action '\(action.builtinId ?? "?")'", exitCode: 1)
        }
        switch builtin {
        case .cut:
            // Never fall back to the container: cutting needs an explicit selection.
            guard !rawPaths.isEmpty else {
                return ExecResult(success: false, summary: String(localized: "Select at least one item to cut"), exitCode: 1)
            }
            let stored = cutBuffer.set(rawPaths)
            writePasteboardURLs(stored)
            return ExecResult(success: true, summary: String.localizedStringWithFormat(
                NSLocalizedString("Cut %lld item(s)", comment: "Cut summary"), Int64(stored.count)))
        case .moveHere:
            let sources = cutBuffer.items
            guard !sources.isEmpty else {
                return ExecResult(success: false, summary: String(localized: "Cut queue is empty"), exitCode: 1)
            }
            var isDirectory: ObjCBool = false
            guard let destination = resolvedPaths.first,
                  FileManager.default.fileExists(atPath: destination, isDirectory: &isDirectory), isDirectory.boolValue else {
                return ExecResult(success: false, summary: String(localized: "Destination is not a folder"), exitCode: 1)
            }
            let result = CutFileMover.move(sources: sources, toDirectory: destination)
            cutBuffer.remove(result.completedPaths)
            return cutMoveExecResult(result)
        case .clear:
            let cleared = cutBuffer.clear()
            let summary = cleared == 0
                ? String(localized: "Cut queue is empty")
                : String.localizedStringWithFormat(NSLocalizedString("Cleared %lld cut item(s)", comment: "Clear cut summary"), Int64(cleared))
            return ExecResult(success: true, summary: summary)
        }
    }

    private func cutMoveExecResult(_ result: CutMoveResult) -> ExecResult {
        let moved = Int64(result.movedPaths.count)
        let conflicts = Int64(result.conflictPaths.count)
        let failures = Int64(result.failedItems.count + result.invalidDestinationPaths.count + result.missingPaths.count)
        let summary: String
        if failures > 0 {
            summary = moved > 0
                ? String.localizedStringWithFormat(NSLocalizedString("Moved %lld, %lld failed", comment: ""), moved, failures + conflicts)
                : String.localizedStringWithFormat(NSLocalizedString("Could not move %lld item(s)", comment: ""), failures + conflicts)
        } else if conflicts > 0 {
            summary = moved > 0
                ? String.localizedStringWithFormat(NSLocalizedString("Moved %lld, skipped %lld due to name conflict", comment: ""), moved, conflicts)
                : String.localizedStringWithFormat(NSLocalizedString("Skipped %lld item(s) due to name conflict", comment: ""), conflicts)
        } else if moved > 0 {
            summary = String.localizedStringWithFormat(NSLocalizedString("Moved %lld item(s)", comment: ""), moved)
        } else {
            summary = String(localized: "Already in destination")
        }

        func name(_ path: String) -> String { (path as NSString).lastPathComponent }
        var lines: [String] = []
        lines += result.conflictPaths.map { "Name conflict (not overwritten): \(name($0))" }
        lines += result.missingPaths.map { "Missing: \(name($0))" }
        lines += result.invalidDestinationPaths.map { "Cannot move into itself: \(name($0))" }
        lines += result.failedItems.map { "Failed: \(name($0.path)) — \($0.reason)" }
        return ExecResult(
            success: result.isSuccess,
            summary: summary,
            exitCode: result.isSuccess ? 0 : 1,
            stderr: lines.joined(separator: "\n")
        )
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
        return runProcess(argv: argv, env: ProcessInfo.processInfo.environment, cwd: FileManager.default.currentDirectoryPath, timeout: 120)
    }

    private func appleScriptString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    // MARK: - Process

    /// Shared Process runner — argv is already split (no shell string concat of paths).
    public func runProcess(
        argv: [String],
        env: [String: String],
        cwd: String,
        timeout: TimeInterval? = nil
    ) -> ExecResult {
        let output: ProcessOutput
        do {
            output = try ProcessRunner.run(argv: argv, environment: env, workingDirectory: cwd, timeout: timeout)
        } catch ProcessRunnerError.emptyArgv {
            return ExecResult(success: false, summary: "Empty argv", exitCode: 1)
        } catch {
            return ExecResult(success: false, summary: error.localizedDescription, exitCode: 1)
        }
        if output.timedOut {
            return ExecResult(
                success: false,
                summary: "Timed out after \(Int(timeout ?? 0))s",
                exitCode: output.exitCode,
                stdout: output.stdout,
                stderr: output.stderr
            )
        }
        let success = output.exitCode == 0
        let firstLine = output.stdout.split(separator: "\n", omittingEmptySubsequences: true).first.map(String.init)
        let summary = success
            ? (firstLine ?? "OK")
            : (output.stderr.split(separator: "\n").first.map(String.init) ?? "Exit \(output.exitCode)")
        return ExecResult(success: success, summary: summary, exitCode: output.exitCode, stdout: output.stdout, stderr: output.stderr)
    }
}
