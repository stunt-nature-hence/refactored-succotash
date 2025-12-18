import Foundation
import Darwin

// MARK: - Libproc Definitions

private let PROC_ALL_PIDS: UInt32 = 1
private let PROC_PIDTASKINFO: Int32 = 4
private let PROC_PIDT_SHORTBSDINFO: Int32 = 13

// Made internal for testing
struct proc_taskinfo {
    var pti_virtual_size: UInt64
    var pti_resident_size: UInt64
    var pti_total_user: UInt64
    var pti_total_system: UInt64
    var pti_threads_user: UInt64
    var pti_threads_system: UInt64
    var pti_policy: Int32
    var pti_faults: Int32
    var pti_pageins: Int32
    var pti_cow_faults: Int32
    var pti_messages_sent: Int32
    var pti_messages_received: Int32
    var pti_syscalls_mach: Int32
    var pti_syscalls_unix: Int32
    var pti_csw: Int32
    var pti_threadnum: Int32
    var pti_numrunning: Int32
    var pti_priority: Int32
}

private struct proc_bsdshortinfo {
    var pbsi_pid: UInt32
    var pbsi_ppid: UInt32
    var pbsi_pgid: UInt32
    var pbsi_status: UInt32
    var pbsi_comm: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8)
    var pbsi_flags: UInt32
    var pbsi_uid: uid_t
    var pbsi_gid: gid_t
    var pbsi_ruid: uid_t
    var pbsi_rgid: gid_t
    var pbsi_svuid: uid_t
    var pbsi_svgid: gid_t
    var pbsi_rfu: UInt32
}

@_silgen_name("proc_listpids")
private func proc_listpids(_ type: UInt32, _ typeinfo: UInt32, _ buffer: UnsafeMutableRawPointer?, _ buffersize: Int32) -> Int32

@_silgen_name("proc_pidinfo")
private func proc_pidinfo(_ pid: Int32, _ flavor: Int32, _ arg: UInt64, _ buffer: UnsafeMutableRawPointer?, _ buffersize: Int32) -> Int32

// MARK: - Data Provider Protocol

protocol ProcessDataProvider {
    func getAllPids() -> [Int32]
    func getProcessTaskInfo(pid: Int32) -> proc_taskinfo?
    func getProcessName(pid: Int32) -> String?
}

class RealProcessDataProvider: ProcessDataProvider {
    func getAllPids() -> [Int32] {
        // First call to get size
        let bufferSize = proc_listpids(PROC_ALL_PIDS, 0, nil, 0)
        guard bufferSize > 0 else { return [] }
        
        // Allocate buffer
        let count = Int(bufferSize) / MemoryLayout<Int32>.size
        var pids = [Int32](repeating: 0, count: count)
        
        let actualSize = proc_listpids(PROC_ALL_PIDS, 0, &pids, bufferSize)
        guard actualSize > 0 else { return [] }
        
        // Resize if we got fewer
        let actualCount = Int(actualSize) / MemoryLayout<Int32>.size
        if actualCount < count {
            pids = Array(pids.prefix(actualCount))
        }
        
        return pids
    }
    
    func getProcessTaskInfo(pid: Int32) -> proc_taskinfo? {
        var info = proc_taskinfo(
            pti_virtual_size: 0, pti_resident_size: 0, pti_total_user: 0, pti_total_system: 0,
            pti_threads_user: 0, pti_threads_system: 0, pti_policy: 0, pti_faults: 0,
            pti_pageins: 0, pti_cow_faults: 0, pti_messages_sent: 0, pti_messages_received: 0,
            pti_syscalls_mach: 0, pti_syscalls_unix: 0, pti_csw: 0, pti_threadnum: 0,
            pti_numrunning: 0, pti_priority: 0
        )
        let size = Int32(MemoryLayout<proc_taskinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, size)
        
        if result == size {
            return info
        }
        return nil
    }
    
    func getProcessName(pid: Int32) -> String? {
        var info = proc_bsdshortinfo(
            pbsi_pid: 0, pbsi_ppid: 0, pbsi_pgid: 0, pbsi_status: 0,
            pbsi_comm: (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
            pbsi_flags: 0, pbsi_uid: 0, pbsi_gid: 0, pbsi_ruid: 0,
            pbsi_rgid: 0, pbsi_svuid: 0, pbsi_svgid: 0, pbsi_rfu: 0
        )
        let size = Int32(MemoryLayout<proc_bsdshortinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDT_SHORTBSDINFO, 0, &info, size)
        
        if result == size {
            // Convert tuple to string
            return withUnsafePointer(to: &info.pbsi_comm) { ptr in
                return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
            }
        }
        return nil
    }
}

// MARK: - ProcessMonitor

public enum ProcessSortMetric {
    case cpu
    case memory
    case network
}

public class ProcessMonitor: @unchecked Sendable {
    private struct ProcessState {
        let totalUserTime: UInt64
        let totalSystemTime: UInt64
        let timestamp: TimeInterval
    }
    
    private var previousProcessStates: [Int32: ProcessState] = [:]
    private var cachedProcesses: [ProcessMetrics] = []
    private var lastUpdateTime: TimeInterval = 0
    private let cacheTTL: TimeInterval = 1.0 // 1 second cache
    
    private let lock = NSLock()
    private let dataProvider: ProcessDataProvider
    internal var dateProvider: () -> Date = { Date() }
    
    init(dataProvider: ProcessDataProvider) {
        self.dataProvider = dataProvider
    }
    
    public convenience init() {
        self.init(dataProvider: RealProcessDataProvider())
    }
    
    public func topProcesses(limit: Int = 5, by metric: ProcessSortMetric) -> [ProcessMetrics] {
        lock.lock()
        defer { lock.unlock() }
        
        let now = dateProvider().timeIntervalSince1970
        if now - lastUpdateTime > cacheTTL {
            refreshProcesses(now: now)
        }
        
        let sorted = cachedProcesses.sorted {
            switch metric {
            case .cpu:
                return $0.cpuUsagePercent > $1.cpuUsagePercent
            case .memory:
                return $0.memoryUsageBytes > $1.memoryUsageBytes
            case .network:
                return ($0.networkBytesSent + $0.networkBytesReceived) > ($1.networkBytesSent + $1.networkBytesReceived)
            }
        }
        
        return Array(sorted.prefix(limit))
    }
    
    private func refreshProcesses(now: TimeInterval) {
        let pids = dataProvider.getAllPids()
        var newProcesses: [ProcessMetrics] = []
        var newStates: [Int32: ProcessState] = [:]
        
        for pid in pids {
            guard let taskInfo = dataProvider.getProcessTaskInfo(pid: pid),
                  let name = dataProvider.getProcessName(pid: pid) else {
                continue
            }
            
            // Calculate CPU
            let currentTotalUser = taskInfo.pti_total_user
            let currentTotalSystem = taskInfo.pti_total_system
            var cpuPercent: Double = 0.0
            
            if let prevState = previousProcessStates[pid] {
                let timeDiff = now - prevState.timestamp
                if timeDiff > 0 {
                    let userDiff = Double(currentTotalUser) - Double(prevState.totalUserTime)
                    let systemDiff = Double(currentTotalSystem) - Double(prevState.totalSystemTime)
                    
                    // Usage = (delta_usage_ns / delta_time_ns) * 100
                    // timeDiff is in seconds.
                    
                    let totalDiffNs = userDiff + systemDiff
                    let timeDiffNs = timeDiff * 1_000_000_000
                    
                    if timeDiffNs > 0 {
                        cpuPercent = (totalDiffNs / timeDiffNs) * 100.0
                    }
                }
            }
            
            // Store state
            newStates[pid] = ProcessState(
                totalUserTime: currentTotalUser,
                totalSystemTime: currentTotalSystem,
                timestamp: now
            )
            
            // RAM
            let memoryBytes = taskInfo.pti_resident_size
            
            // Network (Placeholder)
            let netSent: UInt64 = 0
            let netRecv: UInt64 = 0
            
            newProcesses.append(ProcessMetrics(
                id: pid,
                name: name,
                cpuUsagePercent: cpuPercent,
                memoryUsageBytes: memoryBytes,
                networkBytesSent: netSent,
                networkBytesReceived: netRecv
            ))
        }
        
        self.cachedProcesses = newProcesses
        self.previousProcessStates = newStates
        self.lastUpdateTime = now
    }
}
