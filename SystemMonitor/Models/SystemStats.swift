import Foundation

struct SystemStats {
    var cpuUsage: Double
    var memoryUsage: Double
    
    static var empty: SystemStats {
        SystemStats(cpuUsage: 0, memoryUsage: 0)
    }
}
