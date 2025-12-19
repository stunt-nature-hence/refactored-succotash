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
        )
    ]
)
