import Foundation
import Testing
@testable import FinderActionsCore

@Suite("Execute delivery & menu availability")
struct ExecuteDeliveryTests {
    @Test func planOnceWhenHostRunning() {
        let plan = ExecuteDelivery.plan(hostRunning: true)
        #expect(plan == .once)
        #expect(ExecuteDelivery.postCount(for: plan) == 1)
    }

    @Test func planLaunchAndRetryWhenHostDown() {
        let plan = ExecuteDelivery.plan(hostRunning: false)
        #expect(plan == .launchAndRetry)
        #expect(ExecuteDelivery.postCount(for: plan) == 2)
    }

    @Test func menuShowsOnlyWhenHostProcessRunningWithItems() {
        let snap = MenuSnapshot(hostRunning: true, items: [
            MenuSnapshotItem(actionId: "a", title: "A")
        ])
        #expect(!MenuAvailability.shouldShowActionMenu(hostProcessRunning: false, snapshot: snap))
        #expect(MenuAvailability.shouldShowActionMenu(hostProcessRunning: true, snapshot: snap))
        #expect(!MenuAvailability.shouldShowActionMenu(
            hostProcessRunning: true,
            snapshot: MenuSnapshot(hostRunning: true, items: [])
        ))
        #expect(!MenuAvailability.shouldShowActionMenu(hostProcessRunning: true, snapshot: nil))

        let staleFalse = MenuSnapshot(hostRunning: false, items: [
            MenuSnapshotItem(actionId: "a", title: "A")
        ])
        #expect(MenuAvailability.shouldShowActionMenu(hostProcessRunning: true, snapshot: staleFalse))
    }

    @Test func requestIdDedupeRejectsDuplicateWithinWindow() {
        let dedupe = RequestIdDedupe(windowSeconds: 5)
        let t0 = Date(timeIntervalSince1970: 1_000)
        #expect(dedupe.accept("req-1", now: t0))
        #expect(!dedupe.accept("req-1", now: t0.addingTimeInterval(1)))
        #expect(dedupe.accept("req-2", now: t0.addingTimeInterval(1)))
        #expect(dedupe.accept("req-1", now: t0.addingTimeInterval(6)))
    }
}
