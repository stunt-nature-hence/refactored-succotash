import Foundation

public struct NetworkMetrics: Codable, Sendable {
    public let timestamp: Date
    public let interfaces: [NetworkInterfaceMetrics]
    
    public init(
        timestamp: Date = Date(),
        interfaces: [NetworkInterfaceMetrics]
    ) {
        self.timestamp = timestamp
        self.interfaces = interfaces
    }
}

public struct NetworkInterfaceMetrics: Codable, Sendable {
    public let name: String
    public let isUp: Bool
    public let bytesSent: UInt64
    public let bytesReceived: UInt64
    public let packetsSent: UInt64
    public let packetsReceived: UInt64
    public let errorsSent: UInt64
    public let errorsReceived: UInt64
    public let droppedPackets: UInt64
    
    public init(
        name: String,
        isUp: Bool,
        bytesSent: UInt64,
        bytesReceived: UInt64,
        packetsSent: UInt64,
        packetsReceived: UInt64,
        errorsSent: UInt64,
        errorsReceived: UInt64,
        droppedPackets: UInt64
    ) {
        self.name = name
        self.isUp = isUp
        self.bytesSent = bytesSent
        self.bytesReceived = bytesReceived
        self.packetsSent = packetsSent
        self.packetsReceived = packetsReceived
        self.errorsSent = errorsSent
        self.errorsReceived = errorsReceived
        self.droppedPackets = droppedPackets
    }
}
