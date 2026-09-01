import Foundation
import Testing
@testable import FinderActionsCore

@Suite("Finder menu action tag registry")
struct MenuActionTagRegistryTests {
    @Test func assignsStableNonZeroTagAndResolvesRoute() {
        let registry = MenuActionTagRegistry()
        let route = MenuActionRoute(actionId: "copy-path", menuKind: .contextualMenuForItems)

        let first = registry.tag(for: route)
        let second = registry.tag(for: route)

        #expect(first > 0)
        #expect(second == first)
        #expect(registry.route(for: first) == route)
    }

    @Test func distinguishesActionAndMenuKind() {
        let registry = MenuActionTagRegistry()
        let itemRoute = MenuActionRoute(actionId: "copy-path", menuKind: .contextualMenuForItems)
        let containerRoute = MenuActionRoute(actionId: "copy-path", menuKind: .contextualMenuForContainer)
        let otherAction = MenuActionRoute(actionId: "copy-name", menuKind: .contextualMenuForItems)

        let itemTag = registry.tag(for: itemRoute)
        let containerTag = registry.tag(for: containerRoute)
        let otherTag = registry.tag(for: otherAction)

        #expect(itemTag != containerTag)
        #expect(itemTag != otherTag)
        #expect(containerTag != otherTag)
        #expect(registry.route(for: containerTag) == containerRoute)
        #expect(registry.route(for: otherTag) == otherAction)
    }

    @Test func rejectsUnknownAndDefaultTags() {
        let registry = MenuActionTagRegistry()

        #expect(registry.route(for: 0) == nil)
        #expect(registry.route(for: 999) == nil)
    }

    @Test func concurrentRegistrationKeepsOneStableRoute() {
        let registry = MenuActionTagRegistry()
        let route = MenuActionRoute(actionId: "copy-path", menuKind: .contextualMenuForItems)

        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            _ = registry.tag(for: route)
        }

        let tag = registry.tag(for: route)
        #expect(registry.route(for: tag) == route)
    }
}
