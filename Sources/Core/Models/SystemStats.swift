import Foundation

public struct SystemStats {
    public var cpuUsage: Double
    public var memoryUsage: Double
    
    public static var empty: SystemStats {
        SystemStats(cpuUsage: 0, memoryUsage: 0)
    }
    
    public init(cpuUsage: Double, memoryUsage: Double) {
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
    }
}
