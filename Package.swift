// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SystemMonitor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SystemMonitor", targets: ["SystemMonitor"]),
        .library(name: "SystemMonitorCore", targets: ["SystemMonitorCore"])
    ],
    targets: [
        .target(
            name: "SystemMonitorCore",
            path: "Sources/Core"
        ),
        .executableTarget(
            name: "SystemMonitor",
            dependencies: ["SystemMonitorCore"],
            path: "Sources/App"
        ),
        .testTarget(
            name: "SystemMonitorTests",
            dependencies: ["SystemMonitorCore"],
            path: "Tests"
        ),
        // QA Test Targets
        .testTarget(
            name: "QAStressTesting",
            dependencies: ["SystemMonitorCore"],
            path: "Tests/QA",
            exclude: [
                "UITesting.swift",
                "IntegrationTesting.swift", 
                "EdgeCaseTesting.swift"
            ]
        ),
        .testTarget(
            name: "QAUITesting",
            dependencies: ["SystemMonitor", "SystemMonitorCore"],
            path: "Tests/QA",
            exclude: [
                "StressTesting.swift",
                "IntegrationTesting.swift",
                "EdgeCaseTesting.swift"
            ]
        ),
        .testTarget(
            name: "QAIntegrationTesting",
            dependencies: ["SystemMonitorCore"],
            path: "Tests/QA",
            exclude: [
                "StressTesting.swift",
                "UITesting.swift",
                "EdgeCaseTesting.swift"
            ]
        ),
        .testTarget(
            name: "QAEdgeCaseTesting",
            dependencies: ["SystemMonitorCore"],
            path: "Tests/QA",
            exclude: [
                "StressTesting.swift",
                "UITesting.swift",
                "IntegrationTesting.swift"
            ]
        )
    ]
)