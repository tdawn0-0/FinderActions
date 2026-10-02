import Foundation
import FinderActionsCore

/// Configuration persistence shared by the Host and the Settings helper, so both
/// processes seed, migrate and read the same files identically.
@MainActor
enum SharedConfiguration {
    static let openWithDefaultsKey = "openWithSettings.v2"

    /// Seeds defaults on first launch; otherwise migrates the stored manifest to
    /// its base form (Open With actions are generated, never stored). Always
    /// restores missing bundled scripts.
    static func bootstrap(store: ManifestStore) -> (manifest: ActionManifest, openWith: OpenWithSettings) {
        try? store.ensureDirectories()
        let result: (manifest: ActionManifest, openWith: OpenWithSettings)
        if FileManager.default.fileExists(atPath: store.fileURL.path) {
            let stored = store.loadOrEmpty()
            let base = OpenWithActions.baseManifest(from: stored)
            if base != stored {
                try? store.save(base)
            }
            result = (base, loadOpenWithSettings())
        } else {
            result = resetToDefaults(store: store)
        }
        seedMissingScripts(store: store)
        return result
    }

    /// Writes factory defaults for both the manifest and Open With settings.
    @discardableResult
    static func resetToDefaults(store: ManifestStore) -> (manifest: ActionManifest, openWith: OpenWithSettings) {
        let manifest = DefaultActions.manifest()
        try? store.save(manifest)
        saveOpenWithSettings(.defaults)
        return (manifest, .defaults)
    }

    static func loadOpenWithSettings() -> OpenWithSettings {
        guard let data = AppPreferences.data(forKey: openWithDefaultsKey),
              let settings = try? JSONDecoder().decode(OpenWithSettings.self, from: data) else {
            return .defaults
        }
        return settings
    }

    static func saveOpenWithSettings(_ settings: OpenWithSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        AppPreferences.set(data, forKey: openWithDefaultsKey)
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
