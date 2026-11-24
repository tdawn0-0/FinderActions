import Foundation
import FinderActionsCore

/// Configuration persistence shared by the Host and the Settings helper, so both
/// processes seed, migrate and read the same files identically.
@MainActor
enum SharedConfiguration {
    static let openWithDefaultsKey = "openWithSettings.v2"
    static let cutEnabledDefaultsKey = "cutActionsEnabled.v1"

    /// Cut is on unless the user turned it off.
    static func loadCutEnabled(preferences: PreferencesStore = .live) -> Bool {
        preferences.object(forKey: cutEnabledDefaultsKey) as? Bool ?? true
    }

    static func saveCutEnabled(_ enabled: Bool, preferences: PreferencesStore = .live) {
        preferences.set(enabled, forKey: cutEnabledDefaultsKey)
    }

    static func localizedCutLabels(count: Int) -> CutMenuLabels {
        CutMenuLabels(
            cutTitle: NSLocalizedString("Cut", comment: "Finder menu: cut selection"),
            moveHereTitle: count > 0
                ? String.localizedStringWithFormat(NSLocalizedString("Move Here (%lld)", comment: "Finder menu: move cut items here"), Int64(count))
                : NSLocalizedString("Move Here", comment: "Finder menu: move cut items here"),
            clearTitle: NSLocalizedString("Clear Cut", comment: "Finder menu: clear cut queue")
        )
    }

    /// Seeds defaults on first launch; otherwise migrates the stored manifest to
    /// its base form (Open With actions are generated, never stored). Always
    /// restores missing bundled scripts.
    static func bootstrap(store: ManifestStore, preferences: PreferencesStore = .live, migrationSave: ((ActionManifest) throws -> Void)? = nil) throws -> (manifest: ActionManifest, openWith: OpenWithSettings) {
        try store.ensureDirectories()
        let result: (manifest: ActionManifest, openWith: OpenWithSettings)
        if FileManager.default.fileExists(atPath: store.fileURL.path) {
            let stored = try store.load()
            let base = OpenWithActions.baseManifest(from: stored)
            if base != stored {
                try (migrationSave ?? store.save)(base)
            }
            result = (base, loadOpenWithSettings(preferences: preferences))
        } else {
            result = try resetToDefaults(store: store, preferences: preferences)
        }
        seedMissingScripts(store: store)
        return result
    }

    /// Writes factory defaults for both the manifest and Open With settings.
    @discardableResult
    static func resetToDefaults(store: ManifestStore, preferences: PreferencesStore = .live) throws -> (manifest: ActionManifest, openWith: OpenWithSettings) {
        let manifest = DefaultActions.manifest()
        try store.save(manifest)
        saveOpenWithSettings(.defaults, preferences: preferences)
        saveCutEnabled(true, preferences: preferences)
        return (manifest, .defaults)
    }

    static func loadOpenWithSettings(preferences: PreferencesStore = .live) -> OpenWithSettings {
        guard let data = preferences.data(forKey: openWithDefaultsKey),
              let settings = try? JSONDecoder().decode(OpenWithSettings.self, from: data) else {
            return .defaults
        }
        return settings
    }

    static func saveOpenWithSettings(_ settings: OpenWithSettings, preferences: PreferencesStore = .live) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        preferences.set(data, forKey: openWithDefaultsKey)
    }

    static func seedMissingScripts(store: ManifestStore) {
        try? store.ensureDirectories()
        for (name, body) in DefaultActions.bundledScripts() {
            let destination = store.actionsDirectoryURL.appendingPathComponent(name)
            guard !FileManager.default.fileExists(atPath: destination.path) else { continue }
            try? body.write(to: destination, atomically: true, encoding: .utf8)
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destination.path)
        }

        guard let resourceURL = Bundle.main.resourceURL?.appendingPathComponent("BundledActions"),
              let files = try? FileManager.default.contentsOfDirectory(atPath: resourceURL.path) else {
            return
        }
        for file in files where file.hasSuffix(".zsh") {
            let destination = store.actionsDirectoryURL.appendingPathComponent(file)
            guard !FileManager.default.fileExists(atPath: destination.path) else { continue }
            try? FileManager.default.copyItem(at: resourceURL.appendingPathComponent(file), to: destination)
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destination.path)
        }
    }
}
