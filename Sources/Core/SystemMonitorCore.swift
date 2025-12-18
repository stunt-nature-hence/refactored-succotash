import Foundation

public typealias SystemMonitorManager = SystemMetricsManager

public extension SystemMetricsManager {
    @MainActor
    static let mainShared = SystemMetricsManager()
}

@_exported import struct Foundation.Date
@_exported import struct Foundation.TimeInterval
