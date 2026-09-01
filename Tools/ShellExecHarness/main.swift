import Foundation
import FinderActionsCore

/// Headless harness: runs a real shell action against a path that contains a space,
/// proving ShellEnvironment + Process integration on the shipped Core APIs.
///
/// Usage:
///   ShellExecHarness [output-log-path]
/// Exit 0 only if the script sees the path intact via "$@".

func main() throws {
    let logPath = CommandLine.arguments.dropFirst().first
        ?? FileManager.default.temporaryDirectory.appendingPathComponent("shell-exec.log").path

    let fm = FileManager.default
    let work = fm.temporaryDirectory.appendingPathComponent("FA-Harness-\(UUID().uuidString)", isDirectory: true)
    try fm.createDirectory(at: work, withIntermediateDirectories: true)
    defer { try? fm.removeItem(at: work) }

    // Path with space + Chinese + special chars in filename components
    let spacedDir = work.appendingPathComponent("my project", isDirectory: true)
    try fm.createDirectory(at: spacedDir, withIntermediateDirectories: true)
    let targetFile = spacedDir.appendingPathComponent("hello 世界 $'test'.txt")
    try "payload".write(to: targetFile, atomically: true, encoding: .utf8)

    let scriptURL = work.appendingPathComponent("echo-paths.zsh")
    let script = """
    #!/bin/zsh
    set -euo pipefail
    # Prove "$@" preserves every path element intact
    print -r -- "COUNT=$#"
    print -r -- "ARG1=$1"
    print -r -- "FA_PATH_COUNT=$FA_PATH_COUNT"
    print -r -- "FA_PATHS=$FA_PATHS"
    print -r -- "FA_CWD=$FA_CWD"
    print -r -- "FA_ACTION_ID=$FA_ACTION_ID"
    # Fail if first arg does not match expected full path
    if [[ "$1" != "$EXPECTED_PATH" ]]; then
      print -u2 -- "PATH_MISMATCH expected=[$EXPECTED_PATH] got=[$1]"
      exit 2
    fi
    print -r -- "OK"
    """
    try script.write(to: scriptURL, atomically: true, encoding: .utf8)
    try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

    let paths = [targetFile.path]
    let container = spacedDir.path
    let actionId = "harness-echo"

    var env = ShellEnvironment.makeEnvironment(
        paths: paths,
        containerPath: container,
        actionId: actionId
    )
    env["EXPECTED_PATH"] = targetFile.path

    let argv = ShellEnvironment.argvForScriptFile(
        interpreter: "/bin/zsh",
        scriptPath: scriptURL.path,
        paths: paths
    )

    let process = Process()
    process.executableURL = URL(fileURLWithPath: argv[0])
    process.arguments = Array(argv.dropFirst())
    process.environment = env
    process.currentDirectoryURL = URL(fileURLWithPath: container)

    let outPipe = Pipe()
    let errPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errPipe

    try process.run()
    process.waitUntilExit()

    let outText = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let errText = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

    var log = """
    === ShellExecHarness ===
    target: \(targetFile.path)
    argv: \(argv)
    exit: \(process.terminationStatus)
    --- stdout ---
    \(outText)
    --- stderr ---
    \(errText)
    """

    let ok = process.terminationStatus == 0
        && outText.contains("OK")
        && outText.contains(targetFile.path)
        && outText.contains("COUNT=1")

    log += "\nRESULT: \(ok ? "PASS" : "FAIL")\n"
    try log.write(toFile: logPath, atomically: true, encoding: .utf8)
    print(log)
    if !ok {
        throw NSError(domain: "ShellExecHarness", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Harness failed — see \(logPath)"
        ])
    }
}

do {
    try main()
} catch {
    fputs("ERROR: \(error)\n", stderr)
    exit(1)
}
