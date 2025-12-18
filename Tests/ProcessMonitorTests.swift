import XCTest
@testable import Core

class MockProcessDataProvider: ProcessDataProvider {
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

final class ProcessMonitorTests: XCTestCase {
    
    func testTopProcessesSortingByMemory() {
        let provider = MockProcessDataProvider()
        provider.pids = [1, 2, 3]
        provider.names = [1: "Process1", 2: "Process2", 3: "Process3"]
        
        provider.taskInfos[1] = createInfo(resident: 100)
        provider.taskInfos[2] = createInfo(resident: 300)
        provider.taskInfos[3] = createInfo(resident: 200)
        
        let monitor = ProcessMonitor(dataProvider: provider)
        
        let top = monitor.topProcesses(limit: 3, by: .memory)
        
        XCTAssertEqual(top.count, 3)
        XCTAssertEqual(top[0].id, 2) // 300
        XCTAssertEqual(top[1].id, 3) // 200
        XCTAssertEqual(top[2].id, 1) // 100
    }
    
    func testCPUMetricsCalculation() {
        let provider = MockProcessDataProvider()
        provider.pids = [10]
        provider.names = [10: "CPUHog"]
        
        // Initial state
        provider.taskInfos[10] = createInfo(user: 1000, system: 500)
        
        let monitor = ProcessMonitor(dataProvider: provider)
        var currentTime = Date()
        monitor.dateProvider = { currentTime }
        
        // First call initializes state, returns 0% because no previous state
        let initial = monitor.topProcesses(limit: 1, by: .cpu)
        XCTAssertEqual(initial[0].cpuUsagePercent, 0.0)
        
        // Advance time by 1 second
        currentTime = currentTime.addingTimeInterval(2.0) // > 1.0 TTL
        
        // Update process CPU time
        // 1 second of user time = 1_000_000_000 ns
        // Let's say it used 0.5s user + 0.5s system in 2 seconds real time = 50% usage?
        // Wait, logic:
        // cpuPercent = (totalDiffNs / timeDiffNs) * 100.0
        
        let userDiff: UInt64 = 500_000_000 // 0.5s
        let systemDiff: UInt64 = 500_000_000 // 0.5s
        
        provider.taskInfos[10] = createInfo(
            user: 1000 + userDiff,
            system: 500 + systemDiff
        )
        
        let next = monitor.topProcesses(limit: 1, by: .cpu)
        
        // Total diff = 1s = 1e9 ns
        // Time diff = 2s = 2e9 ns
        // Usage = 1e9 / 2e9 * 100 = 50%
        
        XCTAssertEqual(next[0].cpuUsagePercent, 50.0, accuracy: 0.1)
    }
    
    func testProcessLifecycle() {
        let provider = MockProcessDataProvider()
        
        // Time 0: Process 1 exists
        provider.pids = [1]
        provider.names = [1: "Process1"]
        provider.taskInfos[1] = createInfo(resident: 100)
        
        let monitor = ProcessMonitor(dataProvider: provider)
        var currentTime = Date()
        monitor.dateProvider = { currentTime }
        
        let result1 = monitor.topProcesses(limit: 5, by: .memory)
        XCTAssertEqual(result1.count, 1)
        XCTAssertEqual(result1.first?.id, 1)
        
        // Time 1: Process 1 dies, Process 2 appears
        currentTime = currentTime.addingTimeInterval(2.0)
        provider.pids = [2]
        provider.names = [2: "Process2"]
        provider.taskInfos[2] = createInfo(resident: 200)
        // Clean up mock data for 1 to simulate gone
        provider.names[1] = nil
        provider.taskInfos[1] = nil
        
        let result2 = monitor.topProcesses(limit: 5, by: .memory)
        XCTAssertEqual(result2.count, 1)
        XCTAssertEqual(result2.first?.id, 2)
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
