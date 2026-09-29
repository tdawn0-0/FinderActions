import Foundation

/// Factory default actions shipped with the app (seeded on first launch).
public enum DefaultActions {
    public static func manifest() -> ActionManifest {
        ActionManifest(version: 2, actions: actions())
    }

    public static func actions() -> [ActionDefinition] {
        [
            ActionDefinition(
                id: "copy-path",
                name: "Copy Path",
                subtitle: "Absolute path to clipboard",
                type: .shell,
                enabled: true,
                sortIndex: 20,
                group: nil,
                icon: ActionIcon(sfSymbol: "doc.on.clipboard"),
                showWhen: .always,
                shell: ShellConfig(interpreter: "/bin/zsh", scriptFile: "copy-path.zsh")
            ),
            ActionDefinition(
                id: "copy-name",
                name: "Copy Filename",
                subtitle: "Basename to clipboard",
                type: .shell,
                enabled: true,
                sortIndex: 21,
                group: nil,
                icon: ActionIcon(sfSymbol: "textformat"),
                showWhen: .always,
                shell: ShellConfig(interpreter: "/bin/zsh", scriptFile: "copy-name.zsh")
            ),
        ]
    }

    /// Bundled script contents keyed by filename.
    public static func bundledScripts() -> [String: String] {
        [
            "copy-path.zsh": """
            #!/bin/zsh
            set -euo pipefail
            # "$@" = selected paths; also available as FA_PATHS (newline-separated)
            printf '%s\\n' "$@" | /usr/bin/pbcopy
            print -r -- "Copied ${FA_PATH_COUNT:-$#} path(s)"
            """,
            "copy-name.zsh": """
            #!/bin/zsh
            set -euo pipefail
            names=()
            for p in "$@"; do
              names+=("${p:t}")
            done
            printf '%s\\n' "${names[@]}" | /usr/bin/pbcopy
            print -r -- "Copied ${#names} name(s)"
            """,
        ]
    }
}
