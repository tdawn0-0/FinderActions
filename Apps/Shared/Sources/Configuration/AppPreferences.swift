import Foundation
import FinderActionsCore

/// Reads and writes the Host's preferences domain explicitly so the nested
/// Settings app shares values without requiring an App Group or migration.
@MainActor
enum AppPreferences {
    private static let applicationID = IPCConstants.hostBundleId as CFString

    static func bool(forKey key: String) -> Bool {
        object(forKey: key) as? Bool ?? false
    }

    static func data(forKey key: String) -> Data? {
        object(forKey: key) as? Data
    }

    static func object(forKey key: String) -> Any? {
        // Host and Settings are separate processes; refresh this domain before reading
        // completion/navigation values written by the other process.
        CFPreferencesAppSynchronize(applicationID)
        return CFPreferencesCopyAppValue(key as CFString, applicationID)
    }

    static func set(_ value: Any, forKey key: String) {
        CFPreferencesSetAppValue(key as CFString, value as CFPropertyList, applicationID)
        CFPreferencesAppSynchronize(applicationID)
    }
}

/// Injectable domain adapter. Tests use memory() and never touch CFPreferences.
@MainActor
final class PreferencesStore {
    static let live = PreferencesStore()
    private var values: [String: Any]?
    var isInMemory: Bool { values != nil }
    private init(values: [String: Any]? = nil) { self.values = values }
    static func memory(_ values: [String: Any] = [:]) -> PreferencesStore { PreferencesStore(values: values) }
    func object(forKey key: String) -> Any? {
        if let values { return values[key] }
        return AppPreferences.object(forKey: key)
    }
    func bool(forKey key: String) -> Bool { object(forKey: key) as? Bool ?? false }
    func data(forKey key: String) -> Data? { object(forKey: key) as? Data }
    func set(_ value: Any, forKey key: String) {
        if values != nil { values?[key] = value } else { AppPreferences.set(value, forKey: key) }
    }
}
