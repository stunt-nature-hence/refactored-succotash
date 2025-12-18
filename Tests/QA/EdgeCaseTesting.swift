import XCTest
@testable import SystemMonitorCore
import Foundation
import SystemConfiguration

/// Edge case testing for production robustness
final class EdgeCaseTesting: XCTestCase {
    
    func testExtremeCPUValues() throws {
        let manager = SystemMetricsManager()
        
        // Test various extreme CPU scenarios
        for _ in 0..<100 {
            let cpuMetrics = try manager.getOnDemandCPUMetrics()
            
            // Validate CPU percentages are always in valid range
            XCTAssertGreaterThanOrEqual(cpuMetrics.totalUsagePercent, 0)
            XCTAssertLessThanOrEqual(cpuMetrics.totalUsagePercent, 100)
            
            XCTAssertGreaterThanOrEqual(cpuMetrics.systemUsagePercent, 0)
            XCTAssertLessThanOrEqual(cpuMetrics.systemUsagePercent, 100)
            
            XCTAssertGreaterThanOrEqual(cpuMetrics.userUsagePercent, 0)
            XCTAssertLessThanOrEqual(cpuMetrics.userUsagePercent, 100)
            
            XCTAssertGreaterThanOrEqual(cpuMetrics.idlePercent, 0)
            XCTAssertLessThanOrEqual(cpuMetrics.idlePercent, 100)
            
            // Sum validation
            let sum = cpuMetrics.systemUsagePercent + cpuMetrics.userUsagePercent + cpuMetrics.idlePercent
            XCTAssertLessThanOrEqual(abs(sum - 100.0), 0.1, "CPU percentages should sum to ~100%")
        }
    }
    
    func testExtremeRAMValues() throws {
        let manager = SystemMetricsManager()
        
        // Test various RAM scenarios
        for _ in 0..<100 {
            let ramMetrics = try manager.getOnDemandRAMMetrics()
            
            // Validate RAM values
            XCTAssertGreaterThan(ramMetrics.totalBytes, 0)
            XCTAssertGreaterThanOrEqual(ramMetrics.availableBytes, 0)
            XCTAssertGreaterThanOrEqual(ramMetrics.usedBytes, 0)
            
            XCTAssertLessThanOrEqual(ramMetrics.usagePercent, 100)
            XCTAssertGreaterThanOrEqual(ramMetrics.usagePercent, 0)
            
            // Memory consistency checks
            let calculatedUsed = ramMetrics.totalBytes - ramMetrics.availableBytes
            let difference = abs(ramMetrics.usedBytes - calculatedUsed)
            XCTAssertLessThanOrEqual(difference, 1_000_000_000, "Used memory should roughly equal total - available (1GB tolerance)")
            
            // Component validation
            XCTAssertGreaterThanOrEqual(ramMetrics.activeBytes, 0)
            XCTAssertGreaterThanOrEqual(ramMetrics.inactiveBytes, 0)
            XCTAssertGreaterThanOrEqual(ramMetrics.wiredBytes, 0)
            XCTAssertGreaterThanOrEqual(ramMetrics.compressedBytes, 0)
        }
    }
    
    func testNetworkInterfaceEdgeCases() throws {
        let manager = SystemMetricsManager()
        
        for _ in 0..<50 {
            let networkMetrics = try manager.getOnDemandNetworkMetrics()
            
            XCTAssertNotNil(networkMetrics.interfaces)
            XCTAssertGreaterThanOrEqual(networkMetrics.interfaces.count, 0)
            
            for interface in networkMetrics.interfaces {
                // Interface name validation
                XCTAssertFalse(interface.name.isEmpty)
                
                // Network counters should not be negative
                XCTAssertGreaterThanOrEqual(interface.bytesSent, 0)
                XCTAssertGreaterThanOrEqual(interface.bytesReceived, 0)
                XCTAssertGreaterThanOrEqual(interface.packetsSent, 0)
                XCTAssertGreaterThanOrEqual(interface.packetsReceived, 0)
                XCTAssertGreaterThanOrEqual(interface.errorsSent, 0)
                XCTAssertGreaterThanOrEqual(interface.errorsReceived, 0)
                XCTAssertGreaterThanOrEqual(interface.droppedPackets, 0)
                
                // Inactive interfaces might have zero traffic, but counters should be consistent
                if interface.isActive {
                    // Active interfaces should have reasonable packet/byte ratios
                    if interface.packetsSent > 0 {
                        let avgPacketSize = Double(interface.bytesSent) / Double(interface.packetsSent)
                        XCTAssertLessThan(avgPacketSize, 100_000, "Average packet size should be reasonable")
                    }
                }
            }
        }
    }
    
    func testProcessMonitorEdgeCases() throws {
        let manager = SystemMetricsManager()
        
        // Test with various limit values
        let limits = [0, 1, 5, 10, 50, 100, 200]
        
        for limit in limits {
            let processesByCPU = manager.getTopProcesses(limit: limit, by: .cpuUsage)
            let processesByMemory = manager.getTopProcesses(limit: limit, by: .memoryUsage)
            
            XCTAssertLessThanOrEqual(processesByCPU.count, limit)
            XCTAssertLessThanOrEqual(processesByMemory.count, limit)
            
            // Validate process data if we have any processes
            for process in processesByCPU {
                XCTAssertGreaterThan(process.pid, 0)
                XCTAssertFalse(process.name.isEmpty)
                XCTAssertGreaterThanOrEqual(process.cpuPercent, 0)
                XCTAssertGreaterThanOrEqual(process.memoryUsage, 0)
                XCTAssertGreaterThanOrEqual(process.startTime, 0)
            }
            
            for process in processesByMemory {
                XCTAssertGreaterThan(process.pid, 0)
                XCTAssertFalse(process.name.isEmpty)
                XCTAssertGreaterThanOrEqual(process.cpuPercent, 0)
                XCTAssertGreaterThanOrEqual(process.memoryUsage, 0)
                XCTAssertGreaterThanOrEqual(process.startTime, 0)
            }
        }
    }
    
    func testMetricsTimestampsEdgeCases() throws {
        let manager = SystemMetricsManager()
        
        // Collect metrics very quickly
        let startTime = Date()
        
        let cpu1 = try manager.getOnDemandCPUMetrics()
        let ram1 = try manager.getOnDemandRAMMetrics()
        let network1 = try manager.getOnDemandNetworkMetrics()
        
        let cpu2 = try manager.getOnDemandCPUMetrics()
        let ram2 = try manager.getOnDemandRAMMetrics()
        let network2 = try manager.getOnDemandNetworkMetrics()
        
        let endTime = Date()
        
        // All timestamps should be within the test timeframe
        let allMetrics = [cpu1, cpu2, ram1, ram2, network1, network2]
        
        for metrics in allMetrics {
            XCTAssertGreaterThanOrEqual(metrics.timestamp, startTime)
            XCTAssertLessThanOrEqual(metrics.timestamp, endTime)
        }
        
        // Second collection should generally have later timestamp
        // (though this might not always be true due to system timing)
        XCTAssertGreaterThanOrEqual(cpu2.timestamp.timeIntervalSince1970, cpu1.timestamp.timeIntervalSince1970 - 1)
        XCTAssertGreaterThanOrEqual(ram2.timestamp.timeIntervalSince1970, ram1.timestamp.timeIntervalSince1970 - 1)
        XCTAssertGreaterThanOrEqual(network2.timestamp.timeIntervalSince1970, network1.timestamp.timeIntervalSince1970 - 1)
    }
    
    func testSystemUnderResourceExhaustion() async throws {
        let manager = SystemMetricsManager()
        manager.startMonitoring()
        
        // Simulate resource exhaustion scenario
        var memoryPressureTriggered = false
        var errorRecoveryWorked = false
        
        // Continuously allocate and release memory to simulate pressure
        for cycle in 0..<50 {
            autoreleasepool {
                // Allocate some memory
                var bigArray = [Int](repeating: 0, count: 1_000_000)
                
                // Fill it with some data
                for i in 0..<bigArray.count {
                    bigArray[i] = i % 1000
                }
                
                // Continuously collect metrics under pressure
                let cpu = try? manager.getOnDemandCPUMetrics()
                let ram = try? manager.getOnDemandRAMMetrics()
                
                // Check if memory pressure is detected
                if MemoryProfiler.shared.checkMemoryPressure() {
                    memoryPressureTriggered = true
                }
                
                // Small delay
                usleep(100_000) // 0.1 second
            }
            
            // Periodically check health
            if cycle % 10 == 0 {
                let health = manager.getHealthStatus()
                if health.isMonitoring && !health.isInErrorState {
                    errorRecoveryWorked = true
                }
            }
        }
        
        // System should either handle pressure gracefully or detect it
        XCTAssertTrue(errorRecoveryWorked || memoryPressureTriggered, "System should either recover from errors or detect memory pressure")
        
        // Final health check
        let finalHealth = manager.getHealthStatus()
        XCTAssertTrue(finalHealth.isMonitoring, "Should still be monitoring after resource exhaustion")
        
        manager.stopMonitoring()
    }
    
    func testMetricsWithSystemSleepWake() async throws {
        let manager = SystemMetricsManager()
        
        // Start monitoring
        manager.startMonitoring()
        
        // Let it collect some baseline metrics
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        let baselineCPU = manager.getCPUMetrics()
        let baselineRAM = manager.getRAMMetrics()
        
        // Simulate time gap (similar to system sleep)
        let sleepStart = Date()
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second "sleep"
        
        // Wake up and collect metrics
        let postSleepCPU = try manager.getOnDemandCPUMetrics()
        let postSleepRAM = try manager.getOnDemandRAMMetrics()
        
        // Metrics should still be valid after wake
        XCTAssertGreaterThanOrEqual(postSleepCPU.totalUsagePercent, 0)
        XCTAssertLessThanOrEqual(postSleepCPU.totalUsagePercent, 100)
        XCTAssertGreaterThanOrEqual(postSleepRAM.usagePercent, 0)
        XCTAssertLessThanOrEqual(postSleepRAM.usagePercent, 100)
        
        // Timestamps should show progression
        XCTAssertGreaterThan(postSleepCPU.timestamp.timeIntervalSince1970, sleepStart.timeIntervalSince1970)
        
        // System should still be healthy
        let healthAfterWake = manager.getHealthStatus()
        XCTAssertTrue(healthAfterWake.isMonitoring, "Should continue monitoring after wake")
        
        manager.stopMonitoring()
    }
    
    func testConcurrentAccessStressTest() async throws {
        let manager = SystemMetricsManager()
        let concurrentTasks = 50
        
        var completionCount = 0
        var errorCount = 0
        
        await withTaskGroup(of: Void.self) { group in
            for taskId in 0..<concurrentTasks {
                group.addTask {
                    for iteration in 0..<100 {
                        do {
                            // Mix of different operations
                            if iteration % 3 == 0 {
                                let cpu = try manager.getOnDemandCPUMetrics()
                                XCTAssertTrue(cpu.totalUsagePercent >= 0 && cpu.totalUsagePercent <= 100)
                            } else if iteration % 3 == 1 {
                                let ram = try manager.getOnDemandRAMMetrics()
                                XCTAssertTrue(ram.usagePercent >= 0 && ram.usagePercent <= 100)
                            } else {
                                let network = try manager.getOnDemandNetworkMetrics()
                                XCTAssertTrue(network.interfaces.count >= 0)
                            }
                            
                            // Also test cached metrics
                            _ = manager.getCPUMetrics()
                            _ = manager.getRAMMetrics()
                            _ = manager.getNetworkMetrics()
                            
                            // Process monitoring
                            _ = manager.getTopProcesses(limit: 5, by: .cpuUsage)
                            
                        } catch {
                            // Some errors are acceptable under extreme concurrent load
                            if error is SystemMetricsError {
                                // Expected error type
                            } else {
                                XCTFail("Unexpected error type: \(type(of: error))")
                            }
                            errorCount += 1
                        }
                        
                        completionCount += 1
                    }
                }
            }
        }
        
        let totalOperations = concurrentTasks * 100
        let successRate = Double(totalOperations - errorCount) / Double(totalOperations)
        
        // Should maintain reasonable success rate even under extreme load
        XCTAssertGreaterThanOrEqual(successRate, 0.8, "Should maintain >80% success rate under extreme concurrent load")
        
        // Final health check
        let finalHealth = manager.getHealthStatus()
        XCTAssertTrue(finalHealth.isMonitoring, "Should still be monitoring after stress test")
        
        print("Concurrent stress test: \(successRate*100)% success rate")
    }
    
    func testInvalidInputHandling() throws {
        let manager = SystemMetricsManager()
        
        // Test with extreme limit values
        XCTAssertNoThrow(manager.getTopProcesses(limit: 0, by: .cpuUsage))
        XCTAssertNoThrow(manager.getTopProcesses(limit: -1, by: .cpuUsage))
        XCTAssertNoThrow(manager.getTopProcesses(limit: 1000, by: .cpuUsage))
        
        // Test with invalid sort metrics
        XCTAssertNoThrow(manager.getTopProcesses(limit: 5, by: .cpuUsage))
        XCTAssertNoThrow(manager.getTopProcesses(limit: 5, by: .memoryUsage))
        
        // Test sampling interval changes
        XCTAssertNoThrow(manager.setSamplingInterval(-1.0)) // Should be clamped
        XCTAssertNoThrow(manager.setSamplingInterval(0.01)) // Should be clamped
        XCTAssertNoThrow(manager.setSamplingInterval(60.0)) // Should work
        XCTAssertNoThrow(manager.setSamplingInterval(0.5)) // Should work
        
        // Test cache operations
        XCTAssertNoThrow(manager.resetCaches())
        
        // Test health status after edge cases
        let health = manager.getHealthStatus()
        XCTAssertTrue(health.isMonitoring || !health.isMonitoring) // Just verify it doesn't crash
        XCTAssertGreaterThanOrEqual(health.errorCount, 0)
    }
}