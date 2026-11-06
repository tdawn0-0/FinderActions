import Foundation
import Testing
@testable import FinderActionsCore

@Suite("Process runner")
struct ProcessRunnerTests {
    private let environment = ["PATH": "/usr/bin:/bin"]

    @Test func capturesStdoutStderrAndExitCode() throws {
        let output = try run("echo out; echo err >&2; exit 3")
        #expect(output.exitCode == 3)
        #expect(output.stdout == "out\n")
        #expect(output.stderr == "err\n")
        #expect(!output.timedOut)
    }

    @Test func largeOutputDoesNotDeadlock() throws {
        let output = try run(#"head -c 1000000 /dev/zero | tr '\0' a; head -c 1000000 /dev/zero | tr '\0' b >&2"#)
        #expect(output.stdout.utf8.count == ProcessRunner.maxCapturedBytes)
        #expect(output.stderr.utf8.count == ProcessRunner.maxCapturedBytes)
        #expect(output.exitCode == 0)
    }

    @Test func passesEnvironmentAndWorkingDirectory() throws {
        let output = try ProcessRunner.run(
            argv: ["/bin/sh", "-c", #"printf '%s|' "$FA_TEST"; /bin/pwd -P"#],
            environment: ["FA_TEST": "a b"], workingDirectory: "/usr/bin"
        )
        #expect(output.stdout == "a b|/usr/bin\n")
    }

    @Test(.timeLimit(.minutes(1))) func timeoutTerminatesProcess() throws {
        let output = try ProcessRunner.run(
            argv: ["/bin/sleep", "10"], environment: environment,
            workingDirectory: "/", timeout: 0.5
        )
        #expect(output.timedOut)
        #expect(output.exitCode != 0)
    }

    @Test(.timeLimit(.minutes(1))) func timeoutEscalatesWhenTerminationIsIgnored() throws {
        let output = try ProcessRunner.run(
            argv: ["/bin/sh", "-c", #"trap '' TERM; echo ready; i=0; while [ "$i" -lt 30 ]; do sleep 1; i=$((i + 1)); done"#],
            environment: environment, workingDirectory: "/", timeout: 0.5
        )
        #expect(output.timedOut)
        #expect(output.stdout == "ready\n")
        #expect(output.exitCode != 0)
        #expect(output.exitCode == SIGKILL)
    }

    @Test(.timeLimit(.minutes(1))) func backgroundChildHoldingPipeDoesNotHang() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let pidFile = root.appendingPathComponent("child.pid")
        // The parent exits immediately. Its child keeps both output pipes open.
        // The PID fixture also lets failure cleanup run if output capture regresses.
        defer {
            if let text = try? String(contentsOf: pidFile, encoding: .utf8),
               let pid = Int32(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                kill(pid, SIGKILL)
            }
        }
        let output = try ProcessRunner.run(
            argv: ["/bin/sh", "-c", "sleep 30 & echo $! > \"$1\"; echo started", "fixture", pidFile.path],
            environment: environment, workingDirectory: root.path
        )
        let text = try String(contentsOf: pidFile, encoding: .utf8)
        let pid = try #require(Int32(text.trimmingCharacters(in: .whitespacesAndNewlines)))
        // Returning while the pipe-owning child is alive proves post-exit draining
        // is bounded without comparing CI scheduling latency to a tight clock limit.
        #expect(kill(pid, 0) == 0)
        #expect(output.stdout.hasPrefix("started"))
    }

    @Test func keepsFinalStderrDiagnosticsAfterCaptureLimit() throws {
        let output = try run(#"head -c 1000000 /dev/zero | tr '\0' x >&2; echo final-diagnostic >&2"#)
        #expect(output.stderr.utf8.count == ProcessRunner.maxCapturedBytes)
        #expect(output.stderr.hasSuffix("final-diagnostic\n"))
    }

    @Test func emptyArgvThrows() {
        #expect(throws: ProcessRunnerError.emptyArgv) {
            try ProcessRunner.run(argv: [], environment: [:], workingDirectory: "/")
        }
    }

    @Test func missingExecutableThrows() {
        #expect(throws: (any Error).self) {
            try ProcessRunner.run(argv: ["/nonexistent/fa-missing"], environment: [:], workingDirectory: "/")
        }
    }

    private func run(_ script: String) throws -> ProcessOutput {
        try ProcessRunner.run(argv: ["/bin/sh", "-c", script], environment: environment, workingDirectory: "/")
    }
}
