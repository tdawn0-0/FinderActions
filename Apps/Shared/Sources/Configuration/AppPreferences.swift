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
        CFPreferencesCopyAppValue(key as CFString, applicationID)
    }

    static func set(_ value: Any, forKey key: String) {
        CFPreferencesSetAppValue(key as CFString, value as CFPropertyList, applicationID)
        CFPreferencesAppSynchronize(applicationID)
    }
}
