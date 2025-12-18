import Foundation

public struct ProcessMetrics: Identifiable, Sendable, Codable {
    public let id: Int32 // PID
    public let name: String
    public let cpuUsagePercent: Double
    public let memoryUsageBytes: UInt64
    public let networkBytesSent: UInt64
    public let networkBytesReceived: UInt64
    
    public init(id: Int32, name: String, cpuUsagePercent: Double, memoryUsageBytes: UInt64, networkBytesSent: UInt64, networkBytesReceived: UInt64) {
        self.id = id
        self.name = name
        self.cpuUsagePercent = cpuUsagePercent
        self.memoryUsageBytes = memoryUsageBytes
        self.networkBytesSent = networkBytesSent
        self.networkBytesReceived = networkBytesReceived
    }
}
