import XCTest
@testable import SystemMonitorCore
import Foundation
import Dispatch

/// Comprehensive stress testing for production readiness
final class StressTesting: XCTestCase {
    
    func testHighFrequencyMetricsCollection() async throws {
        let manager = SystemMetricsManager()
        let iterations = 100
        var successCount = 0
        var errorCount = 0
        
        // Test high-frequency collection
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    do {
                        let cpu = try manager.getOnDemandCPUMetrics()
                        XCTAssertGreaterThanOrEqual(cpu.totalUsagePercent, 0)
                        XCTAssertLessThanOrEqual(cpu.totalUsagePercent, 100)
                        successCount += 1
                    } catch {
                        errorCount += 1
                    }
                }
            }
        }
        
        let successRate = Double(successCount) / Double(iterations)
        XCTAssertGreaterThanOrEqual(successRate, 0.95, "Success rate should be >= 95%, got \(successRate)")
        print("High-frequency test: \(successCount)/\(iterations) successful (\(successRate*100)%)")
    }
    
    func testConcurrentMetricsAccess() async throws {
        let manager = SystemMetricsManager()
        let concurrentTasks = 20
        var results = Array(repeating: false, count: concurrentTasks)
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<concurrentTasks {
                group.addTask {
                    do {
                        // Test concurrent access to different metrics
                        let cpu = try manager.getOnDemandCPUMetrics()
                        let ram = try manager.getOnDemandRAMMetrics()
                        let network = try manager.getOnDemandNetworkMetrics()
                        
                        XCTAssertNotNil(cpu)
                        XCTAssertNotNil(ram)
                        XCTAssertNotNil(network)
                        
                        results[i] = true
                    } catch {
                        XCTFail("Concurrent access failed: \(error)")
                    }
                }
            }
        }
        
        let successCount = results.filter { $0 }.count
        XCTAssertEqual(successCount, concurrentTasks, "All concurrent tasks should succeed")
    }
    
    func testProcessMonitorHighLoad() async throws {
        let manager = SystemMetricsManager()
        let startTime = Date()
        var processResults: [Bool] = []
        
        // Simulate high system load and test process monitoring
        for i in 0..<50 {
            autoreleasepool {
                let processes = manager.getTopProcesses(limit: 10, by: .memoryUsage)
                
                if !processes.isEmpty {
                    // Validate process data
                    let validProcess = processes.allSatisfy { process in
                        process.memoryUsage >= 0 &&
                        process.cpuPercent >= 0 &&
                        !process.name.isEmpty
                    }
                    processResults.append(validProcess)
                } else {
                    processResults.append(true) // Empty list is valid if no processes
                }
                
                // Simulate some load every 10 iterations
                if i % 10 == 0 {
                    DispatchQueue.global().async {
                        for _ in 0..<1000 {
                            _ = sqrt(Double(i))
                        }
                    }
                }
            }
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        let successRate = Double(processResults.filter { $0 }.count) / Double(processResults.count)
        
        XCTAssertGreaterThanOrEqual(successRate, 0.9, "Process monitoring should maintain >90% success rate under load")
        XCTAssertLessThanOrEqual(elapsedTime, 30.0, "High-load testing should complete within 30 seconds")
        
        print("Process monitoring high-load test: \(successRate*100)% success in \(elapsedTime)s")
    }
    
    func testMemoryPressureUnderLoad() async throws {
        let manager = SystemMetricsManager()
        var memorySnapshots: [(Date, UInt64)] = []
        
        // Simulate sustained load for 5 seconds
        for _ in 0..<100 {
            autoreleasepool {
                let cpu = try? manager.getOnDemandCPUMetrics()
                let ram = try? manager.getOnDemandRAMMetrics()
                let processes = manager.getTopProcesses(limit: 20, by: .cpuUsage)
                
                // Record memory usage
                let memoryUsage = MemoryProfiler.shared.getCurrentMemoryUsage()
                memorySnapshots.append((Date(), memoryUsage.resident))
                
                // Small delay to simulate real usage
                usleep(100000) // 0.1 second
            }
        }
        
        // Analyze memory usage pattern
        let firstMemory = memorySnapshots.first?.1 ?? 0
        let lastMemory = memorySnapshots.last?.1 ?? 0
        let memoryGrowth = Double(lastMemory - firstMemory) / (1024 * 1024) // MB
        
        // Memory growth should be minimal (<5MB for this test)
        XCTAssertLessThanOrEqual(memoryGrowth, 5.0, "Memory growth should be minimal under load, got \(memoryGrowth)MB")
        
        print("Memory usage under load: growth = \(memoryGrowth)MB")
    }
    
    func testErrorRecoveryUnderLoad() async throws {
        let manager = SystemMetricsManager()
        var successfulCollections = 0
        var totalCollections = 0
        
        // Start monitoring to establish baseline
        manager.startMonitoring()
        
        // Simulate load and mixed success/error scenarios
        for iteration in 0..<100 {
            do {
                try await manager.collectMetrics()
                successfulCollections += 1
            } catch {
                // Some failures are expected under extreme load
                XCTAssertTrue(error is SystemMetricsError, "Expected SystemMetricsError, got \(type(of: error))")
            }
            totalCollections += 1
            
            // Simulate some CPU-intensive operations
            if iteration % 10 == 0 {
                DispatchQueue.global().async {
                    for i in 0..<10000 {
                        _ = sin(Double(i)) * cos(Double(i))
                    }
                }
            }
            
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 second
        }
        
        let successRate = Double(successfulCollections) / Double(totalCollections)
        XCTAssertGreaterThanOrEqual(successRate, 0.7, "Should maintain >70% success rate under error conditions")
        
        // Check health status
        let health = manager.getHealthStatus()
        XCTAssertTrue(health.isMonitoring, "Should remain monitoring after errors")
        
        manager.stopMonitoring()
        
        print("Error recovery test: \(successRate*100)% success rate")
    }
    
    func testLongRunningStability() async throws {
        let manager = SystemMetricsManager()
        let duration: TimeInterval = 5.0 // 5 seconds for test
        let checkInterval: TimeInterval = 0.5
        let startTime = Date()
        
        manager.startMonitoring()
        
        var collections = 0
        var successfulCollections = 0
        
        // Run stability test
        while Date().timeIntervalSince(startTime) < duration {
            do {
                let (_, ram, _) = manager.getAllMetrics()
                if ram != nil {
                    successfulCollections += 1
                }
                collections += 1
            } catch {
                XCTFail("Unexpected error during stability test: \(error)")
            }
            
            try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }
        
        let successRate = Double(successfulCollections) / Double(collections)
        XCTAssertGreaterThanOrEqual(successRate, 0.95, "Long-running stability should maintain >95% success rate")
        
        let finalHealth = manager.getHealthStatus()
        XCTAssertFalse(finalHealth.isInErrorState, "Should not be in error state after stability test")
        
        manager.stopMonitoring()
        
        let testDuration = Date().timeIntervalSince(startTime)
        print("Stability test: \(successRate*100)% success over \(testDuration)s")
    }
}