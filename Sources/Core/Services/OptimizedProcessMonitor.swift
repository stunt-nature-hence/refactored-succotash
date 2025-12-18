import Foundation
import Darwin

public class OptimizedProcessMonitor: @unchecked Sendable {
    private struct ProcessState {
        let totalUserTime: UInt64
        let totalSystemTime: UInt64
        let timestamp: TimeInterval
    }
    
    private struct CachedProcessName {
        let name: String
        let cachedAt: TimeInterval
    }
    
    private var previousProcessStates: [Int32: ProcessState] = [:]
    private var cachedProcessNames: [Int32: CachedProcessName] = [:]
    private var cachedProcesses: [ProcessMetrics] = []
    private var lastFullRefreshTime: TimeInterval = 0
    private var lastQuickRefreshTime: TimeInterval = 0
    
    private let fullRefreshInterval: TimeInterval = 10.0
    private let quickRefreshInterval: TimeInterval = 1.0
    private let namesCacheInterval: TimeInterval = 60.0
    private let maxCachedProcesses: Int = 100
    private let maxTrackedPIDs: Int = 200
    
    private let lock = NSLock()
    private let dataProvider: ProcessDataProvider
    private let logger = Logger.shared
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
        
        if now - lastFullRefreshTime > fullRefreshInterval {
            logger.debug("Performing full process refresh")
            performFullRefresh(now: now)
        } else if now - lastQuickRefreshTime > quickRefreshInterval {
            logger.debug("Performing quick process refresh")
            performQuickRefresh(now: now)
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
    
    private func performFullRefresh(now: TimeInterval) {
        let startTime = Date()
        
        let allPIDs = dataProvider.getAllPids()
        logger.debug("Found \(allPIDs.count) total processes")
        
        var relevantPIDs: [Int32] = []
        var pidMemoryMap: [(pid: Int32, memory: UInt64)] = []
        
        for pid in allPIDs {
            guard let taskInfo = dataProvider.getProcessTaskInfo(pid: pid) else {
                continue
            }
            let memoryBytes = taskInfo.pti_resident_size
            if memoryBytes > 0 {
                pidMemoryMap.append((pid, memoryBytes))
            }
        }
        
        pidMemoryMap.sort { $0.memory > $1.memory }
        relevantPIDs = pidMemoryMap.prefix(maxTrackedPIDs).map { $0.pid }
        
        logger.debug("Tracking top \(relevantPIDs.count) processes by memory")
        
        cleanupOldData(currentPIDs: Set(relevantPIDs), now: now)
        
        updateProcessMetrics(pids: relevantPIDs, now: now)
        
        lastFullRefreshTime = now
        lastQuickRefreshTime = now
        
        let elapsed = Date().timeIntervalSince(startTime)
        logger.debug("Full refresh completed in \(String(format: "%.3f", elapsed))s")
    }
    
    private func performQuickRefresh(now: TimeInterval) {
        let startTime = Date()
        
        let trackedPIDs = Array(previousProcessStates.keys)
        updateProcessMetrics(pids: trackedPIDs, now: now)
        
        lastQuickRefreshTime = now
        
        let elapsed = Date().timeIntervalSince(startTime)
        logger.debug("Quick refresh completed in \(String(format: "%.3f", elapsed))s, \(trackedPIDs.count) processes")
    }
    
    private func updateProcessMetrics(pids: [Int32], now: TimeInterval) {
        var newProcesses: [ProcessMetrics] = []
        newProcesses.reserveCapacity(min(pids.count, maxCachedProcesses))
        
        for pid in pids {
            guard let metrics = collectProcessMetrics(pid: pid, now: now) else {
                continue
            }
            newProcesses.append(metrics)
            
            if newProcesses.count >= maxCachedProcesses {
                break
            }
        }
        
        self.cachedProcesses = newProcesses
        logger.debug("Cached \(newProcesses.count) process metrics")
    }
    
    private func collectProcessMetrics(pid: Int32, now: TimeInterval) -> ProcessMetrics? {
        guard let taskInfo = dataProvider.getProcessTaskInfo(pid: pid) else {
            return nil
        }
        
        let name = getProcessName(pid: pid, now: now)
        
        let currentTotalUser = taskInfo.pti_total_user
        let currentTotalSystem = taskInfo.pti_total_system
        var cpuPercent: Double = 0.0
        
        if let prevState = previousProcessStates[pid] {
            let timeDiff = now - prevState.timestamp
            if timeDiff > 0 {
                let userDiff = Double(currentTotalUser) - Double(prevState.totalUserTime)
                let systemDiff = Double(currentTotalSystem) - Double(prevState.totalSystemTime)
                
                let totalDiffNs = userDiff + systemDiff
                let timeDiffNs = timeDiff * 1_000_000_000
                
                if timeDiffNs > 0 {
                    cpuPercent = (totalDiffNs / timeDiffNs) * 100.0
                    cpuPercent = min(cpuPercent, 800.0)
                }
            }
        }
        
        previousProcessStates[pid] = ProcessState(
            totalUserTime: currentTotalUser,
            totalSystemTime: currentTotalSystem,
            timestamp: now
        )
        
        let memoryBytes = taskInfo.pti_resident_size
        
        return ProcessMetrics(
            id: pid,
            name: name,
            cpuUsagePercent: cpuPercent,
            memoryUsageBytes: memoryBytes,
            networkBytesSent: 0,
            networkBytesReceived: 0
        )
    }
    
    private func getProcessName(pid: Int32, now: TimeInterval) -> String {
        if let cached = cachedProcessNames[pid],
           now - cached.cachedAt < namesCacheInterval {
            return cached.name
        }
        
        let name = dataProvider.getProcessName(pid: pid) ?? "Unknown"
        cachedProcessNames[pid] = CachedProcessName(name: name, cachedAt: now)
        return name
    }
    
    private func cleanupOldData(currentPIDs: Set<Int32>, now: TimeInterval) {
        let statesToRemove = previousProcessStates.keys.filter { !currentPIDs.contains($0) }
        for pid in statesToRemove {
            previousProcessStates.removeValue(forKey: pid)
        }
        
        let namesToRemove = cachedProcessNames.keys.filter { pid in
            guard currentPIDs.contains(pid) else { return true }
            guard let cached = cachedProcessNames[pid] else { return true }
            return now - cached.cachedAt > namesCacheInterval * 2
        }
        for pid in namesToRemove {
            cachedProcessNames.removeValue(forKey: pid)
        }
        
        logger.debug("Cleaned up \(statesToRemove.count) old process states, \(namesToRemove.count) old names")
    }
    
    public func resetCache() {
        lock.lock()
        defer { lock.unlock() }
        
        previousProcessStates.removeAll(keepingCapacity: true)
        cachedProcessNames.removeAll(keepingCapacity: true)
        cachedProcesses.removeAll(keepingCapacity: true)
        lastFullRefreshTime = 0
        lastQuickRefreshTime = 0
        
        logger.info("Process monitor cache reset")
    }
}
