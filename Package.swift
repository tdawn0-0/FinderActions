// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FinderActions",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "FinderActionsCore", targets: ["FinderActionsCore"]),
        .executable(name: "ShellExecHarness", targets: ["ShellExecHarness"]),
    ],
    targets: [
        .target(
            name: "FinderActionsCore",
            path: "Packages/FinderActionsCore/Sources"
        ),
        .testTarget(
            name: "FinderActionsCoreTests",
            dependencies: ["FinderActionsCore"],
            path: "Tests/FinderActionsCoreTests"
        ),
        .testTarget(
            name: "FinderActionsAppTests",
            dependencies: ["FinderActionsCore"],
            path: ".",
            exclude: ["Apps/Host/Resources", "Apps/Settings/Resources", "Extensions", "web", "BundledActions", "build", "FinderActions.xcodeproj"],
            sources: [
                "Apps/Settings/Sources/App/AppState.swift",
                "Apps/Settings/Sources/Features/Actions/LiveTestSession.swift",
                "Apps/Shared/Sources/Configuration/WorkflowFeedback.swift",
                "Apps/Host/Sources/App/HostRuntimeState.swift",
                "Apps/Host/Sources/IPC/IPCServer.swift",
                "Apps/Shared/Sources/Configuration/SharedConfiguration.swift",
                "Apps/Shared/Sources/Configuration/AppPreferences.swift",
                "Apps/Shared/Sources/Execution/ActionExecutor.swift",
                "Apps/Shared/Sources/Execution/ExecLogStore.swift",
                "Tests/AppIntegrationTests/ConfigurationPersistenceTests.swift",
                "Tests/AppIntegrationTests/ExecutionFeedbackTests.swift",
                "Tests/AppIntegrationTests/LiveTestSessionTests.swift",
                "Tests/AppIntegrationTests/LogsRefreshTests.swift",
                "Tests/AppIntegrationTests/IPCResponsivenessTests.swift",
            ]
        ),
        .executableTarget(
            name: "ShellExecHarness",
            dependencies: ["FinderActionsCore"],
            path: "Tools/ShellExecHarness"
        ),
    ]
)
