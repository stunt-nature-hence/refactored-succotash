import XCTest
@testable import SystemMonitorCore

class MockProcessDataProviderForOptimized: ProcessDataProvider {
    var pids: [Int32] = []
    var taskInfos: [Int32: proc_taskinfo] = [:]
    var names: [Int32: String] = [:]
    
    func getAllPids() -> [Int32] {
        return pids
    }
    
    func getProcessTaskInfo(pid: Int32) -> proc_taskinfo? {
        return taskInfos[pid]
    }
    
    func getProcessName(pid: Int32) -> String? {
        return names[pid]
    }
}

final class OptimizedProcessMonitorTests: XCTestCase {
    
    func testTopProcessesSortingByMemory() {
        let provider = MockProcessDataProviderForOptimized()
        provider.pids = [1, 2, 3]
        provider.names = [1: "Process1", 2: "Process2", 3: "Process3"]
        
        provider.taskInfos[1] = createInfo(resident: 100 * 1024 * 1024)
        provider.taskInfos[2] = createInfo(resident: 300 * 1024 * 1024)
        provider.taskInfos[3] = createInfo(resident: 200 * 1024 * 1024)
        
        let monitor = OptimizedProcessMonitor(dataProvider: provider)
        
        let top = monitor.topProcesses(limit: 3, by: .memory)
        
        XCTAssertEqual(top.count, 3)
        XCTAssertEqual(top[0].id, 2) // 300MB
        XCTAssertEqual(top[1].id, 3) // 200MB
        XCTAssertEqual(top[2].id, 1) // 100MB
    }
    
    func testProcessNameCaching() {
        let provider = MockProcessDataProviderForOptimized()
        provider.pids = [1]
        provider.names = [1: "Process1"]
        provider.taskInfos[1] = createInfo(resident: 100 * 1024 * 1024)
        
        let monitor = OptimizedProcessMonitor(dataProvider: provider)
        var currentTime = Date()
        monitor.dateProvider = { currentTime }
        
        // First call should cache the name
        let result1 = monitor.topProcesses(limit: 1, by: .memory)
        XCTAssertEqual(result1[0].name, "Process1")
        
        // Change the name in provider (simulating process name change)
        provider.names[1] = "ChangedName"
        
        // Second call should still return cached name (within cache TTL)
        let result2 = monitor.topProcesses(limit: 1, by: .memory)
        XCTAssertEqual(result2[0].name, "Process1")
        
        // Advance time past name cache interval (60 seconds)
        currentTime = currentTime.addingTimeInterval(61.0)
        
        // Should now get new name
        let result3 = monitor.topProcesses(limit: 1, by: .memory)
        XCTAssertEqual(result3[0].name, "ChangedName")
    }
    
    func testLimitsProcessTracking() {
        let provider = MockProcessDataProviderForOptimized()
        
        // Create 300 processes (exceeds maxTrackedPIDs of 200)
        for i in 1...300 {
            provider.pids.append(Int32(i))
            provider.names[Int32(i)] = "Process\(i)"
            // Give varying memory amounts
            let memory = UInt64((301 - i) * 1024 * 1024) // Higher PIDs get less memory
            provider.taskInfos[Int32(i)] = createInfo(resident: memory)
        }
        
        let monitor = OptimizedProcessMonitor(dataProvider: provider)
        var currentTime = Date()
        monitor.dateProvider = { currentTime }
        
        // Force a full refresh
        let result = monitor.topProcesses(limit: 100, by: .memory)
        
        // Should not track all 300 processes, should limit to maxCachedProcesses (100)
        XCTAssertLessThanOrEqual(result.count, 100)
    }
    
    func testFullRefreshInterval() {
        let provider = MockProcessDataProviderForOptimized()
        provider.pids = [1]
        provider.names = [1: "Process1"]
        provider.taskInfos[1] = createInfo(resident: 100 * 1024 * 1024)
        
        let monitor = OptimizedProcessMonitor(dataProvider: provider)
        var currentTime = Date()
        monitor.dateProvider = { currentTime }
        
        // First call triggers full refresh
        _ = monitor.topProcesses(limit: 1, by: .memory)
        
        // Add a new process
        provider.pids = [1, 2]
        provider.names[2] = "Process2"
        provider.taskInfos[2] = createInfo(resident: 200 * 1024 * 1024)
        
        // Quick refresh (1 second) - should not pick up new process
        currentTime = currentTime.addingTimeInterval(1.0)
        let result1 = monitor.topProcesses(limit: 2, by: .memory)
        XCTAssertEqual(result1.count, 1) // Still only sees process 1
        
        // Full refresh (10+ seconds) - should pick up new process
        currentTime = currentTime.addingTimeInterval(10.0)
        let result2 = monitor.topProcesses(limit: 2, by: .memory)
        XCTAssertEqual(result2.count, 2) // Now sees both processes
    }
    
    func testCacheReset() {
        let provider = MockProcessDataProviderForOptimized()
        provider.pids = [1, 2]
        provider.names = [1: "Process1", 2: "Process2"]
        provider.taskInfos[1] = createInfo(resident: 100 * 1024 * 1024)
        provider.taskInfos[2] = createInfo(resident: 200 * 1024 * 1024)
        
        let monitor = OptimizedProcessMonitor(dataProvider: provider)
        
        // Populate cache
        let result1 = monitor.topProcesses(limit: 2, by: .memory)
        XCTAssertEqual(result1.count, 2)
        
        // Reset cache
        monitor.resetCache()
        
        // After reset, should still work
        let result2 = monitor.topProcesses(limit: 2, by: .memory)
        XCTAssertEqual(result2.count, 2)
    }
    
    private func createInfo(user: UInt64 = 0, system: UInt64 = 0, resident: UInt64 = 0) -> proc_taskinfo {
        return proc_taskinfo(
            pti_virtual_size: 0, pti_resident_size: resident, pti_total_user: user, pti_total_system: system,
            pti_threads_user: 0, pti_threads_system: 0, pti_policy: 0, pti_faults: 0,
            pti_pageins: 0, pti_cow_faults: 0, pti_messages_sent: 0, pti_messages_received: 0,
            pti_syscalls_mach: 0, pti_syscalls_unix: 0, pti_csw: 0, pti_threadnum: 0,
            pti_numrunning: 0, pti_priority: 0
        )
    }
}
