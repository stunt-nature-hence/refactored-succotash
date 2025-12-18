import Foundation

public struct RAMMetrics: Codable, Sendable {
    public let timestamp: Date
    public let usedBytes: UInt64
    public let availableBytes: UInt64
    public let totalBytes: UInt64
    public let usagePercent: Double
    public let activeBytes: UInt64
    public let inactiveBytes: UInt64
    public let wiredBytes: UInt64
    
    public init(
        timestamp: Date = Date(),
        usedBytes: UInt64,
        availableBytes: UInt64,
        totalBytes: UInt64,
        usagePercent: Double,
        activeBytes: UInt64,
        inactiveBytes: UInt64,
        wiredBytes: UInt64
    ) {
        self.timestamp = timestamp
        self.usedBytes = usedBytes
        self.availableBytes = availableBytes
        self.totalBytes = totalBytes
        self.usagePercent = usagePercent
        self.activeBytes = activeBytes
        self.inactiveBytes = inactiveBytes
        self.wiredBytes = wiredBytes
    }
}
