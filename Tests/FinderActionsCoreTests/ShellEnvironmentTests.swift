import Testing
import Foundation
@testable import FinderActionsCore

@Suite("Shell environment & argv")
struct ShellEnvironmentTests {
    @Test func envContainsAllFAKeys() {
        let paths = ["/tmp/a b.txt", "/tmp/中文.swift"]
        let env = ShellEnvironment.makeEnvironment(
            paths: paths,
            containerPath: "/tmp",
            actionId: "compress-images",
            base: [:]
        )
        #expect(env[ShellEnvironment.faCwd] == "/tmp")
        #expect(env[ShellEnvironment.faContainer] == "/tmp")
        #expect(env[ShellEnvironment.faActionId] == "compress-images")
        #expect(env[ShellEnvironment.faPathCount] == "2")
        #expect(env[ShellEnvironment.faPaths] == paths.joined(separator: "\n"))
    }

    @Test func argvForScriptFileKeepsPathsAsSeparateElements() {
        let weird = [
            "/Users/me/proj/a b.swift",
            "/Users/me/proj/中文文件.txt",
            "/Users/me/proj/it's_$weird.txt",
        ]
        let argv = ShellEnvironment.argvForScriptFile(
            interpreter: "/bin/zsh",
            scriptPath: "/tmp/copy-path.zsh",
            paths: weird
        )
        #expect(argv[0] == "/bin/zsh")
        #expect(argv[1] == "/tmp/copy-path.zsh")
        #expect(Array(argv.dropFirst(2)) == weird)
        #expect(!argv.contains { $0.contains("a b.swift") && $0.contains("中文") })
    }

    @Test func argvForInlineScriptUsesDashCAndDummyZero() {
        let paths = ["/tmp/foo bar", "/tmp/$x"]
        let argv = ShellEnvironment.argvForInlineScript(
            interpreter: "/bin/zsh",
            script: #"print -r -- "$@""#,
            paths: paths
        )
        #expect(argv[0] == "/bin/zsh")
        #expect(argv[1] == "-c")
        #expect(argv[2] == #"print -r -- "$@""#)
        #expect(argv[3] == "fa-action")
        #expect(Array(argv.dropFirst(4)) == paths)
    }

    @Test func singleQuoteEscapesEmbeddedQuotes() {
        #expect(ShellEnvironment.singleQuote("it's fine") == "'it'\"'\"'s fine'")
    }

    @Test func pathsWithSpacesChineseQuoteAndDollarSurviveEnvRoundTrip() {
        let paths = [
            "/tmp/space name/file.txt",
            "/tmp/中文/目录/文件.swift",
            "/tmp/quote'here",
            "/tmp/dol$lar",
        ]
        let env = ShellEnvironment.makeEnvironment(
            paths: paths,
            containerPath: "/tmp/space name",
            actionId: "test",
            base: [:]
        )
        let rebuilt = env[ShellEnvironment.faPaths]!
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        #expect(rebuilt == paths)
        #expect(env[ShellEnvironment.faPathCount] == "4")
        #expect(env[ShellEnvironment.faCwd] == "/tmp/space name")
    }

    @Test func terminalCDPathFolderVsFile() throws {
        let fm = FileManager.default
        let dir = fm.temporaryDirectory.appendingPathComponent("FA-CD-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("hello world.txt")
        try "x".write(to: file, atomically: true, encoding: .utf8)
        defer { try? fm.removeItem(at: dir) }

        #expect(ShellEnvironment.terminalCDPath(paths: [dir.path], containerPath: "/other") == dir.path)
        #expect(ShellEnvironment.terminalCDPath(paths: [file.path], containerPath: "/other") == dir.path)
        #expect(
            ShellEnvironment.terminalCDPath(paths: [file.path, dir.path], containerPath: "/container")
                == dir.path
        )
        #expect(
            ShellEnvironment.terminalCDPath(
                paths: [file.path],
                containerPath: "/container",
                preferContainer: true
            ) == "/container"
        )
    }

    @Test func resolvedWorkingDirectoryPrefersContainer() {
        #expect(
            ShellEnvironment.resolvedWorkingDirectory(paths: ["/a/b"], containerPath: "/container/path")
                == "/container/path"
        )
    }
}
