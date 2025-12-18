import Foundation

public typealias SystemMonitorManager = SystemMetricsManager

public extension SystemMetricsManager {
    @MainActor
    static let mainShared = SystemMetricsManager()
}
