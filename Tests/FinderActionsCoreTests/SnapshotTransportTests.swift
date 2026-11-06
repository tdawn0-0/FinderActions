import Foundation
import Testing
@testable import FinderActionsCore

@Suite("Snapshot transport")
struct SnapshotTransportTests {
    @Test func unicodeAndBoundaryRoundTrips() throws {
        for text in [String(repeating: "a", count: 39_999), String(repeating: "a", count: 40_000), String(repeating: "a", count: 40_001), String(repeating: "中文😀", count: 15_000), "a" + String(repeating: "\u{301}", count: 50_000)] {
            let parts = try #require(SnapshotTransport.chunks(text))
            #expect(parts.joined().utf8.elementsEqual(text.utf8))
            #expect(parts.allSatisfy { $0.utf8.count <= 40_000 })
            #expect(parts.allSatisfy { String(data: Data($0.utf8), encoding: .utf8) != nil })
        }
    }
    @Test func outOfOrderDuplicateAndConflictingParts() {
        var a = SnapshotAssembler()
        #expect(a.accept(body: "b", batchID: "x", index: 1, total: 2, now: 0) == nil)
        #expect(a.accept(body: "b", batchID: "x", index: 1, total: 2, now: 1) == nil)
        #expect(a.bufferedBytes == 1 && a.batchCount == 1)
        #expect(a.accept(body: "a", batchID: "x", index: 0, total: 2, now: 2) == "ab")
        #expect(a.bufferedBytes == 0 && a.batchCount == 0)
        _ = a.accept(body: "a", batchID: "x", index: 0, total: 2, now: 3)
        _ = a.accept(body: "different", batchID: "x", index: 0, total: 2, now: 4)
        #expect(a.batchCount == 0)
    }
    @Test func invalidEnvelopeDiscardsBatch() {
        for (index,total) in [(-1,2),(2,2),(0,129),(0,1),(0,3)] {
            var a = SnapshotAssembler()
            _ = a.accept(body: "a", batchID: "x", index: 0, total: 2, now: 0)
            _ = a.accept(body: "b", batchID: "x", index: index, total: total, now: 1)
            #expect(a.batchCount == 0)
        }
    }
    @Test func expiryAndBatchCountAreBounded() {
        var a = SnapshotAssembler()
        for n in 0..<20 {
            _ = a.accept(body: "a", batchID: "\(n)", index: 0, total: 2, now: Double(n))
            #expect(a.batchCount <= 4 && a.bufferedBytes <= 4)
        }
        #expect(a.nextExpiration == 46)
        a.expire(now: 50); #expect(a.batchCount == 0 && a.bufferedBytes == 0)
    }
    @Test func globalMemoryAndOversizeAreBounded() {
        var a = SnapshotAssembler()
        let part = String(repeating: "a", count: 40_000)
        for batch in 0..<4 {
            for index in 0..<100 {
                _ = a.accept(body: part, batchID: "\(batch)", index: index, total: 128, now: Double(batch))
                #expect(a.bufferedBytes <= SnapshotTransport.maxBufferedBytes)
            }
        }
        _ = a.accept(body: part + "b", batchID: "big", index: 0, total: 2, now: 5)
        #expect(a.batchCount <= 4)
        #expect(SnapshotTransport.chunks(String(repeating: "a", count: SnapshotTransport.maxMessageBytes + 1)) == nil)
    }
    @Test func multilingualSnapshotDecodesAfterAssembly() throws {
        var manifest = DefaultActions.manifest()
        manifest.actions[0].name = String(repeating: "中文😀", count: 10_000)
        let json = try JSONCoding.encodeToString(SnapshotBuilder.build(from: manifest))
        let parts = try #require(SnapshotTransport.chunks(json))
        #expect(parts.count > 1)
        var a = SnapshotAssembler(); var merged: String?
        for index in parts.indices.reversed() { merged = a.accept(body: parts[index], batchID: "x", index: index, total: parts.count, now: 0) ?? merged }
        let result = try #require(merged)
        let decoded = try JSONCoding.decode(MenuSnapshot.self, from: result)
        #expect(decoded.items.first?.title == manifest.actions[0].name)
    }
}
