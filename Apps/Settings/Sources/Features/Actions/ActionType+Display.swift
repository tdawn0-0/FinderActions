import SwiftUI
import FinderActionsCore

extension ActionType {
    var displayName: LocalizedStringResource {
        switch self {
        case .shell: "Shell Script"
        case .application: "Application"
        case .appleScript: "AppleScript"
        case .builtin: "Built-in"
        case .terminal: "Terminal"
        }
    }
}

extension ShowWhen {
    var displayName: LocalizedStringResource {
        switch self {
        case .always: "Always"
        case .filesOnly: "Files Only"
        case .foldersOnly: "Folders Only"
        case .single: "Single Selection"
        case .multiple: "Multiple Selection"
        }
    }
}
