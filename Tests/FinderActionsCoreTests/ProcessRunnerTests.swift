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

    @Test func timeoutTerminatesProcess() throws {
        let start = Date()
        let output = try ProcessRunner.run(
            argv: ["/bin/sleep", "10"], environment: environment,
            workingDirectory: "/", timeout: 0.5
        )
        #expect(output.timedOut)
        #expect(Date().timeIntervalSince(start) < 5)
    }

    @Test func timeoutEscalatesWhenTerminationIsIgnored() throws {
        let start = Date()
        let output = try ProcessRunner.run(
            argv: ["/bin/sh", "-c", "trap '' TERM; echo ready; while :; do :; done"],
            environment: environment, workingDirectory: "/", timeout: 0.5
        )
        #expect(output.timedOut)
        #expect(output.stdout == "ready\n")
        #expect(output.exitCode != 0)
        #expect(Date().timeIntervalSince(start) < 5)
    }

    @Test func backgroundChildHoldingPipeDoesNotHang() throws {
        let start = Date()
        let output = try run("sleep 5 & echo started")
        #expect(Date().timeIntervalSince(start) < 4.5)
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
