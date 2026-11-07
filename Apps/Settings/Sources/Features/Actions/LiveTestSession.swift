import Foundation
import Observation
import FinderActionsCore

struct LiveTestPreview: Sendable {
    var action: ActionDefinition
    var inputPaths: [String]
    var paths: [String]
    var container: String?
    var workingDirectory: String
    var description: String
    var visibilityReason: String
    var visible: Bool
}

@Observable @MainActor
final class LiveTestSession {
    var paths: [String] = [FileManager.default.homeDirectoryForCurrentUser.path]
    var container: String?
    var preview: LiveTestPreview?
    var validationError: String?
    var result: ExecResult?
    var resultActionId: String?
    var isValidating = false
    var isRunning = false
    private var generation = 0

    func invalidate() {
        generation += 1
        preview = nil; validationError = nil; result = nil; resultActionId = nil
    }

    func validate(action: ActionDefinition, store: ManifestStore) async {
        guard !isRunning else { return }
        invalidate(); isValidating = true
        let token = generation
        let inputs = paths; let directory = container
        let checked = await Task.detached { () -> Result<LiveTestPreview, Error> in
            Result { try Self.buildPreview(action: action, paths: inputs, container: directory, store: store) }
        }.value
        guard token == generation else { return }
        isValidating = false
        switch checked {
        case .success(let value): preview = value
        case .failure(let error): validationError = error.localizedDescription
        }
    }

    nonisolated static func buildPreview(action: ActionDefinition, paths: [String], container: String?, store: ManifestStore) throws -> LiveTestPreview {
        func fail(_ text: String) -> NSError { NSError(domain: "LiveTest", code: 1, userInfo: [NSLocalizedDescriptionKey: text]) }
        if let error = ActionAuthoring.validationError(action) { throw fail(String(localized: String.LocalizationValue(error))) }
        let fm = FileManager.default
        if let container {
            var directory: ObjCBool = false
            guard fm.fileExists(atPath: container, isDirectory: &directory), directory.boolValue else { throw fail(String(localized: "Choose an existing working directory.")) }
        }
        guard !paths.isEmpty || container != nil else { throw fail(String(localized: "Choose files, folders, or a working directory.")) }
        let resolved = paths.isEmpty ? [container!] : paths
        var folders: [Bool] = []
        for path in resolved {
            var directory: ObjCBool = false
            guard fm.fileExists(atPath: path, isDirectory: &directory), fm.isReadableFile(atPath: path) else { throw fail(String(localized: "Input is missing or unreadable: \(path)")) }
            folders.append(directory.boolValue)
        }
        let cwd = ShellEnvironment.resolvedWorkingDirectory(paths: resolved, containerPath: container)
        var description = ""
        if action.type == .shell, let shell = action.shell {
            let interpreter = shell.interpreter.isEmpty ? "/bin/zsh" : shell.interpreter
            guard fm.isExecutableFile(atPath: interpreter) else { throw fail(String(localized: "Interpreter is missing or not executable: \(interpreter)")) }
            let argv: [String]
            if let file = shell.scriptFile, !file.isEmpty {
                let script = store.resolveScriptPath(file).path
                guard fm.isReadableFile(atPath: script) else { throw fail(String(localized: "Script not found or unreadable: \(script)")) }
                argv = ShellEnvironment.argvForScriptFile(interpreter: interpreter, scriptPath: script, paths: resolved)
            } else {
                argv = ShellEnvironment.argvForInlineScript(interpreter: interpreter, script: shell.scriptInline ?? "", paths: resolved)
            }
            let env = ShellEnvironment.makeEnvironment(paths: resolved, containerPath: container, actionId: action.id, base: [:])
            description = "argv (JSON):\n" + String(data: try JSONEncoder().encode(argv), encoding: .utf8)!
                + "\n\n" + env.keys.filter { $0.hasPrefix("FA_") }.sorted().map { "\($0)=\(env[$0]!)" }.joined(separator: "\n")
        } else if action.type == .appleScript {
            if let file = action.appleScript?.scriptFile, !file.isEmpty, !fm.isReadableFile(atPath: store.resolveScriptPath(file).path) { throw fail(String(localized: "Script not found or unreadable: \(file)")) }
            description = "/usr/bin/osascript — faPaths, faContainer, faActionId are supplied."
        } else if action.type == .application {
            description = "Launch application: \(action.application?.bundleId ?? action.application?.pathFallback ?? "")"
        } else { description = "Launch terminal at \(cwd)" }
        let context = SelectionContext(paths: paths, isDirectory: paths.isEmpty ? [] : folders)
        let reason: String
        if !action.enabled { reason = "Disabled" }
        else if !ShowWhenMatcher.matches(showWhen: action.showWhen, context: context) { reason = "Selection rule mismatch" }
        else if !ShowWhenMatcher.matchesExtRules(action.extRules, context: context) { reason = "File extension mismatch" }
        else { reason = "Shown in Finder" }
        return LiveTestPreview(action: action, inputPaths: paths, paths: resolved, container: container, workingDirectory: cwd, description: description, visibilityReason: reason,
            visible: action.enabled && ShowWhenMatcher.shouldShow(showWhen: action.showWhen, extRules: action.extRules,
                context: SelectionContext(paths: paths, isDirectory: paths.isEmpty ? [] : folders)))
    }

    func run(action: ActionDefinition, executor: ActionExecutor, record: (ExecLogEntry) -> Void) async {
        guard !isRunning, let captured = preview, captured.action == action, captured.inputPaths == paths, captured.container == container else { return }
        isRunning = true; result = nil; resultActionId = action.id
        defer { isRunning = false }
        let startedAt = Date()
        let output = await Task.detached {
            executor.execute(action: action, paths: captured.paths, containerPath: captured.container)
        }.value
        result = output
        record(ExecLogEntry(actionId: action.id, success: output.success, summary: "Test Run: \(output.summary)", paths: captured.paths, stderrTail: OutputTail.tail(output.stderr), actionName: action.name, durationSeconds: Date().timeIntervalSince(startedAt), source: .test))
    }
}
