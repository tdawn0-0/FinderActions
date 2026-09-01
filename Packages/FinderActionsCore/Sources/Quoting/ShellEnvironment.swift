import Foundation

/// Builds safe shell execution context: env vars + argv for Process.
/// Never concatenates unquoted paths into a single shell string.
public enum ShellEnvironment {
    public static let faCwd = "FA_CWD"
    public static let faPaths = "FA_PATHS"
    public static let faPathCount = "FA_PATH_COUNT"
    public static let faContainer = "FA_CONTAINER"
    public static let faActionId = "FA_ACTION_ID"

    /// Environment variables injected for every shell action.
    public static func makeEnvironment(
        paths: [String],
        containerPath: String?,
        actionId: String,
        base: [String: String] = ProcessInfo.processInfo.environment
    ) -> [String: String] {
        var env = base
        let cwd = resolvedWorkingDirectory(paths: paths, containerPath: containerPath)
        env[faCwd] = cwd
        env[faContainer] = containerPath ?? cwd
        // Newline-separated paths (paths themselves may contain spaces; newlines are invalid in macOS paths)
        env[faPaths] = paths.joined(separator: "\n")
        env[faPathCount] = String(paths.count)
        env[faActionId] = actionId
        return env
    }

    /// Working directory: prefer container; else first folder path; else parent of first file.
    public static func resolvedWorkingDirectory(paths: [String], containerPath: String?) -> String {
        if let containerPath, !containerPath.isEmpty {
            return containerPath
        }
        guard let first = paths.first else {
            return FileManager.default.currentDirectoryPath
        }
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: first, isDirectory: &isDir), isDir.boolValue {
            return first
        }
        return (first as NSString).deletingLastPathComponent
    }

    /// Resolve terminal `cd` target from selection rules (F-04).
    public static func terminalCDPath(paths: [String], containerPath: String?, preferContainer: Bool = false) -> String {
        if preferContainer, let containerPath, !containerPath.isEmpty {
            return containerPath
        }
        guard let first = paths.first else {
            return containerPath ?? FileManager.default.currentDirectoryPath
        }
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: first, isDirectory: &isDir), isDir.boolValue {
            return first
        }
        return (first as NSString).deletingLastPathComponent
    }

    /// Argv for running a script file: `[interpreter, scriptPath] + paths as separate args`.
    /// The script receives paths as `"$@"` — never unquoted-joined.
    public static func argvForScriptFile(
        interpreter: String,
        scriptPath: String,
        paths: [String]
    ) -> [String] {
        [interpreter, scriptPath] + paths
    }

    /// Argv for inline script via `interpreter -c <script>` with paths as trailing args.
    /// For zsh/bash, positional params after `-c` need a dummy `$0`:
    /// `zsh -c 'script' -- path1 path2`
    public static func argvForInlineScript(
        interpreter: String,
        script: String,
        paths: [String]
    ) -> [String] {
        // `$0` placeholder then paths become $1..$n; scripts should use "$@" which works after shifting,
        // or use FA_PATHS. We set -- as $0 so "$@" in zsh -c still sees paths when script uses:
        //   for f; do ...; done  OR  use FA_PATHS
        // Standard portable approach: pass paths only via env for inline, but PRD wants "$@".
        // zsh: zsh -c 'script' zsh path1 path2  → $0=zsh, $1=path1
        // In zsh/bash, "$@" is $1..$n, so:
        [interpreter, "-c", script, "fa-action"] + paths
    }

    /// Single-quote a string for embedding in a shell command (AppleScript terminal cd helpers).
    public static func singleQuote(_ value: String) -> String {
        // 'foo'bar' → 'foo'"'"'bar'
        "'" + value.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
    }
}
