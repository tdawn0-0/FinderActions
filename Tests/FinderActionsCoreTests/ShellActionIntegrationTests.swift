import Testing
import Foundation
import Darwin
@testable import FinderActionsCore

@Suite("Shell action integration")
struct ShellActionIntegrationTests {
    @Test func scriptFileReceivesPathsAndEnvironmentIntact() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let paths = try makeSelectedFiles(in: directory)
        let script = directory.appendingPathComponent("echo-args.zsh")
        try #"""
        #!/bin/zsh
        for p in "$@"; do print -r -- "ARG:$p"; done
        print -r -- "COUNT:$FA_PATH_COUNT"
        print -r -- "ID:$FA_ACTION_ID"
        print -r -- "CWD:$PWD"
        print -r -- "ENV_CWD:$FA_CWD"
        print -r -- "CONTAINER:$FA_CONTAINER"
        print -r -- "PATHS:$FA_PATHS"
        """#.write(to: script, atomically: true, encoding: .utf8)
        let environment = ShellEnvironment.makeEnvironment(
            paths: paths, containerPath: directory.path, actionId: "it-test",
            base: ["PATH": "/usr/bin:/bin"]
        )
        let output = try ProcessRunner.run(
            argv: ShellEnvironment.argvForScriptFile(
                interpreter: "/bin/zsh", scriptPath: script.path, paths: paths
            ),
            environment: environment,
            workingDirectory: ShellEnvironment.resolvedWorkingDirectory(paths: paths, containerPath: directory.path),
            timeout: 5
        )
        #expect(output.exitCode == 0)
        #expect(!output.timedOut)
        #expect(output.stderr.isEmpty)
        let lines = output.stdout.split(separator: "\n").map(String.init)
        #expect(Array(lines.prefix(3)) == paths.map { "ARG:" + $0 })
        #expect(lines.contains("COUNT:3"))
        #expect(lines.contains("ID:it-test"))
        // Foundation normalizes /private/var back to /var on some macOS versions.
        let resolvedPath = try #require(directory.path.withCString { realpath($0, nil) })
        defer { free(resolvedPath) }
        let physicalPath = String(cString: resolvedPath)
        #expect(lines.contains("CWD:" + directory.path) || lines.contains("CWD:" + physicalPath))
        #expect(lines.contains("ENV_CWD:" + directory.path))
        #expect(lines.contains("CONTAINER:" + directory.path))
        #expect(output.stdout.contains("PATHS:" + paths.joined(separator: "\n") + "\n"))
    }

    @Test func inlineScriptReceivesPathsAsPositionalArgs() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let paths = try makeSelectedFiles(in: directory)
        let output = try ProcessRunner.run(
            argv: ShellEnvironment.argvForInlineScript(
                interpreter: "/bin/zsh",
                script: #"for p in "$@"; do print -r -- "ARG:$p"; done"#,
                paths: paths
            ),
            environment: ShellEnvironment.makeEnvironment(
                paths: paths, containerPath: directory.path, actionId: "it-test",
                base: ["PATH": "/usr/bin:/bin"]
            ),
            workingDirectory: ShellEnvironment.resolvedWorkingDirectory(paths: paths, containerPath: directory.path),
            timeout: 5
        )
        #expect(output.exitCode == 0)
        #expect(!output.timedOut)
        #expect(output.stderr.isEmpty)
        #expect(output.stdout.split(separator: "\n").map(String.init) == paths.map { "ARG:" + $0 })
    }

    private func makeSelectedFiles(in directory: URL) throws -> [String] {
        try ["a b.txt", "it's_$weird.txt", "中文.swift"].map { name in
            let file = directory.appendingPathComponent(name)
            try "selected file".write(to: file, atomically: true, encoding: .utf8)
            return file.path
        }
    }
}
