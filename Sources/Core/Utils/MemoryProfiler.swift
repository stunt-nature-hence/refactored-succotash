import Foundation
import Darwin

public final class MemoryProfiler: @unchecked Sendable {
    public static let shared = MemoryProfiler()
    
    private let logger = Logger.shared
    private var lastReportTime: TimeInterval = 0
    private let reportInterval: TimeInterval = 60.0
    
    private init() {}
    
    public func getCurrentMemoryUsage() -> (resident: UInt64, virtual: UInt64) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) { ptr in
            task_info(
                mach_task_self_,
                task_flavor_t(MACH_TASK_BASIC_INFO),
                UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: integer_t.self),
                &count
            )
        }
        
        guard result == KERN_SUCCESS else {
            return (0, 0)
        }
        
        return (info.resident_size, info.virtual_size)
    }
    
    public func logMemoryUsageIfNeeded() {
        let now = Date().timeIntervalSince1970
        guard now - lastReportTime > reportInterval else { return }
        
        let (resident, virtual) = getCurrentMemoryUsage()
        let residentMB = Double(resident) / (1024 * 1024)
        let virtualMB = Double(virtual) / (1024 * 1024)
        
        logger.info(String(format: "Memory Usage - Resident: %.2f MB, Virtual: %.2f MB", residentMB, virtualMB))
        
        if residentMB > 30 {
            logger.warning(String(format: "High memory usage detected: %.2f MB", residentMB))
        }
        
        lastReportTime = now
    }
    
    public func checkMemoryPressure() -> Bool {
        let (resident, _) = getCurrentMemoryUsage()
        let residentMB = Double(resident) / (1024 * 1024)
        return residentMB > 50
    }
}
