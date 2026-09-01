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
        .executableTarget(
            name: "ShellExecHarness",
            dependencies: ["FinderActionsCore"],
            path: "Tools/ShellExecHarness"
        ),
    ]
)
