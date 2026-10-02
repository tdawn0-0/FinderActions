import Foundation
import Testing
@testable import FinderActionsCore

@Suite("Output tail")
struct OutputTailTests {
    @Test func emptyOutputIsAbsent() {
        #expect(OutputTail.tail("") == nil)
    }

    @Test func whitespaceOutputIsAbsent() {
        #expect(OutputTail.tail(" \t\n\r ") == nil)
    }

    @Test func shortOutputIsTrimmed() {
        #expect(OutputTail.tail(" \n one\ntwo \t") == "one\ntwo")
    }

    @Test func keepsTailWithTruncationMarker() {
        let text = String(repeating: "a", count: OutputTail.logLimit + 9) + "z"
        let tail = OutputTail.tail(text)
        #expect(tail?.count == OutputTail.logLimit + 1)
        #expect(tail?.hasPrefix("…") == true)
        #expect(tail?.hasSuffix("z") == true)
        #expect(tail == "…" + String(text.suffix(OutputTail.logLimit)))
    }

    @Test func truncatesByCharactersRatherThanBytes() {
        let text = String(repeating: "中", count: 10)
        #expect(OutputTail.tail(text, limit: 5) == "…中中中中中")
    }
}
