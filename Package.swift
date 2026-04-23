// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "SSHTerminal",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "SSHTerminal",
            targets: ["SSHTerminal"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "SSHTerminal",
            dependencies: [],
            path: "SSHTerminal",
            sources: [
                "SSHTerminalApp.swift",
                "Models/Host.swift",
                "ViewModels/HostManager.swift",
                "ViewModels/ThemeManager.swift",
                "Views/ContentView.swift",
                "Views/HostListView.swift",
                "Views/HostEditView.swift",
                "Views/TerminalView.swift",
                "Services/SSHService.swift"
            ],
            resources: []
        )
    ]
)
