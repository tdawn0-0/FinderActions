import Foundation

/// Output of a child process run to completion.
public struct ProcessOutput: Sendable, Equatable {
    public var exitCode: Int32
    public var stdout: String
    public var stderr: String
    /// True when the process was terminated because `timeout` elapsed.
    public var timedOut: Bool

    public init(exitCode: Int32, stdout: String, stderr: String, timedOut: Bool) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
        self.timedOut = timedOut
    }
}

public enum ProcessRunnerError: Error, Equatable {
    case emptyArgv
}

/// Runs a process from an already-split argv (paths are never joined into a
/// shell string). Drains stdout/stderr while the child runs so large output
/// cannot fill the pipe buffer and deadlock. Blocks the calling thread until
/// the process exits — never call it on the main thread.
public enum ProcessRunner {
    /// Bytes kept per stream. Output beyond this is still read (so the child
    /// never blocks). Stdout keeps its prefix for summaries; stderr keeps its
    /// suffix so final failure diagnostics remain available.
    public static let maxCapturedBytes = 256 * 1024
    /// How long to keep reading after exit; a background grandchild that
    /// inherited the pipe would otherwise hold it open indefinitely.
    static let postExitDrainSeconds: TimeInterval = 2

    public static func run(
        argv: [String],
        environment: [String: String],
        workingDirectory: String,
        timeout: TimeInterval? = nil
    ) throws -> ProcessOutput {
        guard let executable = argv.first else { throw ProcessRunnerError.emptyArgv }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = Array(argv.dropFirst())
        process.environment = environment
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()

        let stdout = StreamCapture(limit: maxCapturedBytes)
        let stderr = StreamCapture(limit: maxCapturedBytes, keepsSuffix: true)
        let drained = DispatchGroup()
        stdout.drain(outPipe.fileHandleForReading, group: drained)
        stderr.drain(errPipe.fileHandleForReading, group: drained)

        let timedOut = TimeoutFlag()
        var timer: DispatchWorkItem?
        if let timeout {
            let item = DispatchWorkItem { [process] in
                guard process.isRunning else { return }
                timedOut.set()
                process.terminate()
                // A script may ignore SIGTERM; bound the wait with escalation.
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1) {
                    guard process.isRunning else { return }
                    kill(process.processIdentifier, SIGKILL)
                }
            }
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout, execute: item)
            timer = item
        }

        process.waitUntilExit()
        timer?.cancel()

        if drained.wait(timeout: .now() + postExitDrainSeconds) == .timedOut {
            stdout.stop(outPipe.fileHandleForReading, group: drained)
            stderr.stop(errPipe.fileHandleForReading, group: drained)
        }

        return ProcessOutput(
            exitCode: process.terminationStatus,
            stdout: stdout.text,
            stderr: stderr.text,
            timedOut: timedOut.value
        )
    }
}

/// Accumulates one pipe's bytes up to `limit`; thread-safe because
/// `readabilityHandler` fires on a background queue.
private final class StreamCapture: @unchecked Sendable {
    private let lock = NSLock()
    private let limit: Int
    private let keepsSuffix: Bool
    private var data = Data()
    private var finished = false

    init(limit: Int, keepsSuffix: Bool = false) {
        self.limit = limit
        self.keepsSuffix = keepsSuffix
    }

    var text: String {
        lock.lock()
        defer { lock.unlock() }
        return String(decoding: data, as: UTF8.self)
    }

    func drain(_ handle: FileHandle, group: DispatchGroup) {
        group.enter()
        handle.readabilityHandler = { [self] handle in
            let chunk = handle.availableData
            if chunk.isEmpty {
                handle.readabilityHandler = nil
                if markFinished() { group.leave() }
            } else {
                append(chunk)
            }
        }
    }

    /// Stop collecting when a descendant keeps its inherited pipe open.
    func stop(_ handle: FileHandle, group: DispatchGroup) {
        handle.readabilityHandler = nil
        if markFinished() { group.leave() }
    }

    private func append(_ chunk: Data) {
        lock.lock()
        defer { lock.unlock() }
        guard !finished else { return }
        if keepsSuffix {
            if chunk.count >= limit {
                data = Data(chunk.suffix(limit))
            } else {
                let overflow = max(0, data.count + chunk.count - limit)
                if overflow > 0 { data.removeFirst(overflow) }
                data.append(chunk)
            }
        } else {
            let room = limit - data.count
            if room > 0 { data.append(chunk.prefix(room)) }
        }
    }

    /// Returns true only the first time, so the group is left exactly once.
    private func markFinished() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if finished { return false }
        finished = true
        return true
    }
}

private final class TimeoutFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var flag = false

    var value: Bool {
        lock.lock()
        defer { lock.unlock() }
        return flag
    }

    func set() {
        lock.lock()
        flag = true
        lock.unlock()
    }
}
