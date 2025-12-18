import Darwin
import Foundation

class CPUMetricsCollector: Sendable {
    private let lock = NSLock()
    private var previousCPUTick: host_cpu_load_info? = nil
    
    func collectMetrics() throws -> CPUMetrics {
        var count: mach_msg_type_number_t = HOST_CPU_LOAD_INFO_COUNT
        var cpuLoad = host_cpu_load_info()
        
        let result = withUnsafeMutablePointer(to: &cpuLoad) { ptr in
            host_statistics(
                mach_host_self(),
                HOST_CPU_LOAD_INFO,
                UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: integer_t.self),
                &count
            )
        }
        
        guard result == KERN_SUCCESS else {
            throw SystemMetricsError.kernelAPIError("Failed to get CPU load info: kern_return_t = \(result)")
        }
        
        return calculateCPUUsage(with: cpuLoad)
    }
    
    private func calculateCPUUsage(with currentLoad: host_cpu_load_info) -> CPUMetrics {
        lock.lock()
        defer { lock.unlock() }
        
        let current = (
            user: UInt32(currentLoad.cpu_ticks.0),
            system: UInt32(currentLoad.cpu_ticks.1),
            idle: UInt32(currentLoad.cpu_ticks.2),
            nice: UInt32(currentLoad.cpu_ticks.3)
        )
        
        guard let previous = previousCPUTick else {
            previousCPUTick = currentLoad
            return CPUMetrics(
                totalUsagePercent: 0,
                systemUsagePercent: 0,
                userUsagePercent: 0,
                idlePercent: 0
            )
        }
        
        let prevUser = UInt32(previous.cpu_ticks.0)
        let prevSystem = UInt32(previous.cpu_ticks.1)
        let prevIdle = UInt32(previous.cpu_ticks.2)
        let prevNice = UInt32(previous.cpu_ticks.3)
        
        let userDiff = current.user &- prevUser
        let systemDiff = current.system &- prevSystem
        let idleDiff = current.idle &- prevIdle
        let niceDiff = current.nice &- prevNice
        
        let totalDiff = userDiff &+ systemDiff &+ idleDiff &+ niceDiff
        
        let userPercent = totalDiff > 0 ? Double(userDiff) / Double(totalDiff) * 100 : 0
        let systemPercent = totalDiff > 0 ? Double(systemDiff) / Double(totalDiff) * 100 : 0
        let idlePercent = totalDiff > 0 ? Double(idleDiff) / Double(totalDiff) * 100 : 0
        let totalUsagePercent = userPercent + systemPercent
        
        previousCPUTick = currentLoad
        
        return CPUMetrics(
            totalUsagePercent: totalUsagePercent,
            systemUsagePercent: systemPercent,
            userUsagePercent: userPercent,
            idlePercent: idlePercent
        )
    }
}
