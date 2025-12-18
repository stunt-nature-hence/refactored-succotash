import XCTest
@testable import SystemMonitorCore
import Foundation

/// Integration testing for production readiness
final class IntegrationTesting: XCTestCase {
    
    func testEndToEndMetricsPipeline() async throws {
        let manager = SystemMetricsManager()
        
        // Start monitoring
        manager.startMonitoring()
        
        // Wait for initial collection
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Verify all metrics are being collected and cached
        let cpuMetrics = manager.getCPUMetrics()
        let ramMetrics = manager.getRAMMetrics()
        let networkMetrics = manager.getNetworkMetrics()
        
        XCTAssertNotNil(cpuMetrics, "CPU metrics should be collected")
        XCTAssertNotNil(ramMetrics, "RAM metrics should be collected")
        XCTAssertNotNil(networkMetrics, "Network metrics should be collected")
        
        // Verify metrics have reasonable values
        if let cpu = cpuMetrics {
            XCTAssertGreaterThanOrEqual(cpu.totalUsagePercent, 0)
            XCTAssertLessThanOrEqual(cpu.totalUsagePercent, 100)
        }
        
        if let ram = ramMetrics {
            XCTAssertGreaterThanOrEqual(ram.usagePercent, 0)
            XCTAssertLessThanOrEqual(ram.usagePercent, 100)
            XCTAssertGreaterThan(ram.totalBytes, 0)
        }
        
        if let network = networkMetrics {
            XCTAssertGreaterThan(network.interfaces.count, 0)
        }
        
        // Test process monitoring integration
        let topProcesses = manager.getTopProcesses(limit: 5, by: .cpuUsage)
        XCTAssertLessThanOrEqual(topProcesses.count, 5)
        
        if !topProcesses.isEmpty {
            // Verify process data integrity
            let validProcesses = topProcesses.allSatisfy { process in
                process.pid > 0 &&
                !process.name.isEmpty &&
                process.cpuPercent >= 0 &&
                process.memoryUsage >= 0
            }
            XCTAssertTrue(validProcesses, "All processes should have valid data")
        }
        
        manager.stopMonitoring()
    }
    
    func testMetricsManagerHealthMonitoring() async throws {
        let manager = SystemMetricsManager()
        
        // Initial health check
        let initialHealth = manager.getHealthStatus()
        XCTAssertTrue(initialHealth.isMonitoring, "Should be monitoring initially")
        XCTAssertEqual(initialHealth.errorCount, 0, "Should have no errors initially")
        XCTAssertTrue(initialHealth.isHealthy, "Should be healthy initially")
        
        // Start monitoring and let it run
        manager.startMonitoring()
        
        // Allow some cycles
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let healthAfterStart = manager.getHealthStatus()
        XCTAssertTrue(healthAfterStart.isMonitoring, "Should still be monitoring")
        
        // Test cache reset functionality
        manager.resetCaches()
        
        let healthAfterReset = manager.getHealthStatus()
        XCTAssertTrue(healthAfterReset.isMonitoring, "Should still be monitoring after cache reset")
        
        // Stop monitoring
        manager.stopMonitoring()
        
        let healthAfterStop = manager.getHealthStatus()
        XCTAssertFalse(healthAfterStop.isMonitoring, "Should not be monitoring after stop")
    }
    
    func testMemoryProfilerIntegration() async throws {
        let manager = SystemMetricsManager()
        
        // Test memory profiling
        let initialMemory = MemoryProfiler.shared.getCurrentMemoryUsage()
        XCTAssertGreaterThan(initialMemory.resident, 0, "Should have measurable memory usage")
        
        // Start monitoring to trigger memory profiler
        manager.startMonitoring()
        
        // Let memory profiler run and log
        try? await Task.sleep(nanoseconds: 65_000_000_000) // 65 seconds to trigger logging
        
        let currentMemory = MemoryProfiler.shared.getCurrentMemoryUsage()
        let memoryGrowth = Double(currentMemory.resident - initialMemory.resident) / (1024 * 1024)
        
        // Memory growth should be reasonable (<20MB for this test)
        XCTAssertLessThanOrEqual(memoryGrowth, 20.0, "Memory growth should be minimal")
        
        // Test memory pressure detection
        let hasPressure = MemoryProfiler.shared.checkMemoryPressure()
        XCTAssertFalse(hasPressure, "Should not detect memory pressure in normal operation")
        
        manager.stopMonitoring()
    }
    
    func testOptimizedProcessMonitorIntegration() async throws {
        let manager = SystemMetricsManager()
        
        // Start monitoring
        manager.startMonitoring()
        
        // Wait for process monitoring to stabilize
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        // Test different sort metrics
        let cpuTopProcesses = manager.getTopProcesses(limit: 10, by: .cpuUsage)
        let memoryTopProcesses = manager.getTopProcesses(limit: 10, by: .memoryUsage)
        
        XCTAssertLessThanOrEqual(cpuTopProcesses.count, 10)
        XCTAssertLessThanOrEqual(memoryTopProcesses.count, 10)
        
        // If we have processes, verify they're sorted correctly
        if cpuTopProcesses.count > 1 {
            let sorted = cpuTopProcesses.dropFirst().enumerated().allSatisfy { index, process in
                process.cpuPercent <= cpuTopProcesses[index].cpuPercent
            }
            XCTAssertTrue(sorted, "CPU usage processes should be sorted in descending order")
        }
        
        if memoryTopProcesses.count > 1 {
            let sorted = memoryTopProcesses.dropFirst().enumerated().allSatisfy { index, process in
                process.memoryUsage <= memoryTopProcesses[index].memoryUsage
            }
            XCTAssertTrue(sorted, "Memory usage processes should be sorted in descending order")
        }
        
        // Test cache reset
        manager.resetCaches()
        
        // Verify process monitoring continues after cache reset
        let processesAfterReset = manager.getTopProcesses(limit: 5, by: .cpuUsage)
        XCTAssertLessThanOrEqual(processesAfterReset.count, 5)
        
        manager.stopMonitoring()
    }
    
    func testErrorRecoveryIntegration() async throws {
        let manager = SystemMetricsManager()
        
        // Start monitoring
        manager.startMonitoring()
        
        // Let it run normally first
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let healthyBefore = manager.getHealthStatus()
        XCTAssertTrue(healthyBefore.isHealthy, "Should be healthy initially")
        
        // Simulate some error conditions by rapid-fire requests
        var errorCount = 0
        for i in 0..<20 {
            do {
                if i % 5 == 0 {
                    // Force some on-demand collection
                    _ = try manager.getOnDemandCPUMetrics()
                } else {
                    // Regular access
                    _ = manager.getCPUMetrics()
                }
            } catch {
                errorCount += 1
                XCTAssertTrue(error is SystemMetricsError, "Should be SystemMetricsError")
            }
        }
        
        // Give time for error recovery
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let healthyAfter = manager.getHealthStatus()
        XCTAssertTrue(healthyAfter.isMonitoring, "Should continue monitoring after errors")
        
        // System should recover from transient errors
        XCTAssertLessThanOrEqual(healthyAfter.errorCount, 10, "Error count should be reasonable")
        
        manager.stopMonitoring()
    }
    
    func testConcurrentIntegration() async throws {
        let manager = SystemMetricsManager()
        
        // Start monitoring
        manager.startMonitoring()
        
        // Multiple concurrent operations
        await withTaskGroup(of: Void.self) { group in
            // Concurrent metrics access
            for i in 0..<10 {
                group.addTask {
                    for j in 0..<20 {
                        let cpu = manager.getCPUMetrics()
                        let ram = manager.getRAMMetrics()
                        let network = manager.getNetworkMetrics()
                        
                        XCTAssertTrue(cpu == nil || (cpu!.totalUsagePercent >= 0 && cpu!.totalUsagePercent <= 100))
                        XCTAssertTrue(ram == nil || (ram!.usagePercent >= 0 && ram!.usagePercent <= 100))
                        XCTAssertTrue(network == nil || network!.interfaces.count >= 0)
                    }
                }
            }
            
            // Concurrent process monitoring
            for i in 0..<5 {
                group.addTask {
                    for j in 0..<10 {
                        let processes = manager.getTopProcesses(limit: 10, by: .cpuUsage)
                        XCTAssertLessThanOrEqual(processes.count, 10)
                    }
                }
            }
            
            // Concurrent on-demand metrics
            for i in 0..<5 {
                group.addTask {
                    for j in 0..<5 {
                        do {
                            let cpu = try manager.getOnDemandCPUMetrics()
                            let ram = try manager.getOnDemandRAMMetrics()
                            let network = try manager.getOnDemandNetworkMetrics()
                            
                            XCTAssertTrue(cpu.totalUsagePercent >= 0 && cpu.totalUsagePercent <= 100)
                            XCTAssertTrue(ram.usagePercent >= 0 && ram.usagePercent <= 100)
                            XCTAssertTrue(network.interfaces.count >= 0)
                        } catch {
                            XCTFail("On-demand metrics should not fail in normal operation: \(error)")
                        }
                    }
                }
            }
        }
        
        // Final health check
        let finalHealth = manager.getHealthStatus()
        XCTAssertTrue(finalHealth.isMonitoring, "Should still be monitoring after concurrent operations")
        XCTAssertFalse(finalHealth.isInErrorState, "Should not be in error state")
        
        manager.stopMonitoring()
    }
    
    func testSystemMetricsManagerLifecycle() async throws {
        let manager = SystemMetricsManager()
        
        // Test multiple start/stop cycles
        for cycle in 0..<3 {
            manager.startMonitoring()
            
            // Let it run
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            let health = manager.getHealthStatus()
            XCTAssertTrue(health.isMonitoring, "Cycle \(cycle): Should be monitoring")
            
            manager.stopMonitoring()
            
            let stoppedHealth = manager.getHealthStatus()
            XCTAssertFalse(stoppedHealth.isMonitoring, "Cycle \(cycle): Should not be monitoring after stop")
            
            // Small delay between cycles
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        
        // Test sampling interval changes
        manager.setSamplingInterval(0.1)
        XCTAssertNoThrow(manager.startMonitoring())
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        manager.stopMonitoring()
        
        // Reset to default
        manager.setSamplingInterval(1.0)
    }
}