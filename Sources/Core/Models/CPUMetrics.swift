import Foundation

public struct CPUMetrics: Codable, Sendable {
    public let timestamp: Date
    public let totalUsagePercent: Double
    public let systemUsagePercent: Double
    public let userUsagePercent: Double
    public let idlePercent: Double
    
    public init(
        timestamp: Date = Date(),
        totalUsagePercent: Double,
        systemUsagePercent: Double,
        userUsagePercent: Double,
        idlePercent: Double
    ) {
        self.timestamp = timestamp
        self.totalUsagePercent = totalUsagePercent
        self.systemUsagePercent = systemUsagePercent
        self.userUsagePercent = userUsagePercent
        self.idlePercent = idlePercent
    }
}
