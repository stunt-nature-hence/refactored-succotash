import Darwin
import Foundation

class RAMMetricsCollector: @unchecked Sendable {
    private var lastSuccessfulMetrics: RAMMetrics? = nil
    private let logger = Logger.shared
    
    func collectMetrics() throws -> RAMMetrics {
        do {
            let stats = try getVMStatistics()
            let totalMemory = try getTotalSystemMemory()
            
            let pageSize = UInt64(vm_kernel_page_size)
            
            let activeBytes = UInt64(stats.active_count) * pageSize
            let inactiveBytes = UInt64(stats.inactive_count) * pageSize
            let wiredBytes = UInt64(stats.wire_count) * pageSize
            let availableBytes = UInt64(stats.free_count) * pageSize
            
            let usedBytes = totalMemory - availableBytes
            let usagePercent = Double(usedBytes) / Double(totalMemory) * 100
            
            let metrics = RAMMetrics(
                usedBytes: usedBytes,
                availableBytes: availableBytes,
                totalBytes: totalMemory,
                usagePercent: usagePercent,
                activeBytes: activeBytes,
                inactiveBytes: inactiveBytes,
                wiredBytes: wiredBytes
            )
            
            lastSuccessfulMetrics = metrics
            return metrics
        } catch {
            logger.error("Failed to collect RAM metrics: \(error)")
            
            if let fallback = lastSuccessfulMetrics {
                logger.warning("Returning cached RAM metrics due to error")
                return fallback
            }
            
            throw error
        }
    }
    
    private func getVMStatistics() throws -> vm_statistics64 {
        var count: mach_msg_type_number_t = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )
        var vmStats = vm_statistics64()
        
        let result = withUnsafeMutablePointer(to: &vmStats) { ptr in
            host_statistics64(
                mach_host_self(),
                HOST_VM_INFO64,
                UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: integer_t.self),
                &count
            )
        }
        
        guard result == KERN_SUCCESS else {
            throw SystemMetricsError.kernelAPIError("Failed to get VM statistics: kern_return_t = \(result)")
        }
        
        return vmStats
    }
    
    private func getTotalSystemMemory() throws -> UInt64 {
        var mib = [CTL_HW, HW_MEMSIZE]
        var size = MemoryLayout<UInt64>.size
        var memorySize: UInt64 = 0
        
        let result = sysctl(&mib, 2, &memorySize, &size, nil, 0)
        guard result == 0 else {
            throw SystemMetricsError.kernelAPIError("Failed to get total system memory: errno = \(errno)")
        }
        
        return memorySize
    }
}
