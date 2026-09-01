import Testing
@testable import FinderActionsCore

@Suite("showWhen matching")
struct ShowWhenTests {
    @Test func alwaysMatchesAnySelection() {
        #expect(ShowWhenMatcher.matches(showWhen: .always, context: SelectionContext(paths: [])))
        #expect(ShowWhenMatcher.matches(showWhen: .always, context: SelectionContext(paths: ["/a"])))
        #expect(ShowWhenMatcher.matches(
            showWhen: .always,
            context: SelectionContext(paths: ["/a", "/b"], isDirectory: [false, true])
        ))
    }

    @Test func filesOnly() {
        let files = SelectionContext(paths: ["/a.txt", "/b.png"], isDirectory: [false, false])
        let folders = SelectionContext(paths: ["/dir"], isDirectory: [true])
        let mixed = SelectionContext(paths: ["/a.txt", "/dir"], isDirectory: [false, true])
        #expect(ShowWhenMatcher.matches(showWhen: .filesOnly, context: files))
        #expect(!ShowWhenMatcher.matches(showWhen: .filesOnly, context: folders))
        #expect(!ShowWhenMatcher.matches(showWhen: .filesOnly, context: mixed))
        #expect(!ShowWhenMatcher.matches(showWhen: .filesOnly, context: SelectionContext(paths: [])))
    }

    @Test func foldersOnly() {
        let folders = SelectionContext(paths: ["/dir", "/d2"], isDirectory: [true, true])
        let files = SelectionContext(paths: ["/a.txt"], isDirectory: [false])
        #expect(ShowWhenMatcher.matches(showWhen: .foldersOnly, context: folders))
        #expect(!ShowWhenMatcher.matches(showWhen: .foldersOnly, context: files))
        #expect(ShowWhenMatcher.matches(showWhen: .foldersOnly, context: SelectionContext(paths: [])))
    }

    @Test func singleAndMultiple() {
        #expect(ShowWhenMatcher.matches(showWhen: .single, context: SelectionContext(paths: ["/a"])))
        #expect(ShowWhenMatcher.matches(showWhen: .single, context: SelectionContext(paths: [])))
        #expect(!ShowWhenMatcher.matches(showWhen: .single, context: SelectionContext(paths: ["/a", "/b"])))
        #expect(!ShowWhenMatcher.matches(showWhen: .multiple, context: SelectionContext(paths: ["/a"])))
        #expect(ShowWhenMatcher.matches(showWhen: .multiple, context: SelectionContext(paths: ["/a", "/b"])))
    }

    @Test func extRulesPathExtensions() {
        let rules = ExtRules(pathExtensions: ["png", "jpg"])
        let images = SelectionContext(paths: ["/a.PNG", "/b.jpg"], isDirectory: [false, false])
        let code = SelectionContext(paths: ["/a.swift"], isDirectory: [false])
        #expect(ShowWhenMatcher.matchesExtRules(rules, context: images))
        #expect(!ShowWhenMatcher.matchesExtRules(rules, context: code))
        #expect(ShowWhenMatcher.matchesExtRules(nil, context: code))
    }

    @Test func extRulesFoldersOnly() {
        let rules = ExtRules(foldersOnly: true)
        #expect(ShowWhenMatcher.matchesExtRules(
            rules,
            context: SelectionContext(paths: ["/d"], isDirectory: [true])
        ))
        #expect(!ShowWhenMatcher.matchesExtRules(
            rules,
            context: SelectionContext(paths: ["/f.txt"], isDirectory: [false])
        ))
    }

    @Test func snapshotFilterAppliesShowWhen() {
        var manifest = ActionManifest(actions: [
            ActionDefinition(id: "a", name: "Always", type: .shell, sortIndex: 1, showWhen: .always),
            ActionDefinition(id: "b", name: "Multi", type: .shell, sortIndex: 2, showWhen: .multiple),
            ActionDefinition(id: "c", name: "Files", type: .shell, sortIndex: 3, showWhen: .filesOnly),
        ])
        for i in manifest.actions.indices { manifest.actions[i].enabled = true }

        let snap = SnapshotBuilder.build(from: manifest)
        let singleFile = SnapshotBuilder.filter(
            snap,
            context: SelectionContext(paths: ["/x.txt"], isDirectory: [false])
        )
        #expect(Set(singleFile.items.map(\.actionId)) == Set(["a", "c"]))

        let multi = SnapshotBuilder.filter(
            snap,
            context: SelectionContext(paths: ["/x.txt", "/y.txt"], isDirectory: [false, false])
        )
        #expect(Set(multi.items.map(\.actionId)) == Set(["a", "b", "c"]))
    }

    @Test func shouldShowCombinesRules() {
        let rules = ExtRules(pathExtensions: ["swift"])
        let ctx = SelectionContext(paths: ["/a.swift"], isDirectory: [false])
        #expect(ShowWhenMatcher.shouldShow(showWhen: .filesOnly, extRules: rules, context: ctx))
        #expect(!ShowWhenMatcher.shouldShow(
            showWhen: .filesOnly,
            extRules: rules,
            context: SelectionContext(paths: ["/a.png"], isDirectory: [false])
        ))
    }
}
