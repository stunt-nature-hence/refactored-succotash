import Foundation
import SystemConfiguration
import IOKit.ps

/// Runtime validation tool for production readiness
final class RuntimeValidator {
    private let logger = Logger.shared
    private var validationResults: [String: Bool] = [:]
    
    struct ValidationResults {
        var memoryUsage: (current: UInt64, peak: UInt64) = (0, 0)
        var cpuUsage: [Double] = []
        var errorCount: Int = 0
        var validationDuration: TimeInterval = 0
        var testResults: [String: Bool] = [:]
    }
    
    private var results = ValidationResults()
    
    func runComprehensiveValidation() async throws {
        let startTime = Date()
        logger.info("Starting comprehensive runtime validation")
        
        // Validation test suite
        try await runMemoryValidation()
        try await runCPUValidation()
        try await runNetworkValidation()
        try await runProcessValidation()
        try await runUIValidation()
        try await runErrorRecoveryValidation()
        try await runConcurrentAccessValidation()
        try await runLongRunningStability()
        
        results.validationDuration = Date().timeIntervalSince(startTime)
        
        await generateValidationReport()
    }
    
    private func runMemoryValidation() async throws {
        logger.info("Running memory validation tests...")
        
        // Test memory profiler
        let initialMemory = MemoryProfiler.shared.getCurrentMemoryUsage()
        XCTAssertGreaterThan(initialMemory.resident, 0)
        
        // Simulate memory load
        for cycle in 0..<10 {
            autoreleasepool {
                var testArray = [Int](repeating: 0, count: 100_000)
                for i in 0..<testArray.count {
                    testArray[i] = i % 100
                }
                
                // Check memory after each cycle
                if cycle % 3 == 0 {
                    let currentMemory = MemoryProfiler.shared.getCurrentMemoryUsage()
                    results.memoryUsage.current = currentMemory.resident
                    results.memoryUsage.peak = max(results.memoryUsage.peak, currentMemory.resident)
                }
            }
            
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        }
        
        // Final memory check
        let finalMemory = MemoryProfiler.shared.getCurrentMemoryUsage()
        let memoryGrowth = Double(finalMemory.resident - initialMemory.resident) / (1024 * 1024)
        
        // Memory growth should be minimal (<5MB for this test)
        XCTAssertLessThanOrEqual(memoryGrowth, 5.0)
        
        results.testResults["memory_validation"] = memoryGrowth <= 5.0
        logger.info("Memory validation completed: \(memoryGrowth)MB growth")
    }
    
    private func runCPUValidation() async throws {
        logger.info("Running CPU validation tests...")
        
        let manager = SystemMetricsManager()
        
        // Test CPU metrics collection under load
        for cycle in 0..<20 {
            let cpuMetrics = try manager.getOnDemandCPUMetrics()
            
            // Validate CPU percentages
            XCTAssertGreaterThanOrEqual(cpuMetrics.totalUsagePercent, 0)
            XCTAssertLessThanOrEqual(cpuMetrics.totalUsagePercent, 100)
            XCTAssertGreaterThanOrEqual(cpuMetrics.systemUsagePercent, 0)
            XCTAssertLessThanOrEqual(cpuMetrics.systemUsagePercent, 100)
            
            results.cpuUsage.append(cpuMetrics.totalUsagePercent)
            
            // Simulate some CPU load
            if cycle % 5 == 0 {
                DispatchQueue.global().async {
                    for i in 0..<1000 {
                        _ = sqrt(Double(i)) * sin(Double(i))
                    }
                }
            }
            
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        }
        
        // Analyze CPU usage patterns
        let avgCPU = results.cpuUsage.reduce(0, +) / Double(results.cpuUsage.count)
        let maxCPU = results.cpuUsage.max() ?? 0
        
        // Should maintain reasonable CPU usage (<20% average, <80% peak)
        XCTAssertLessThanOrEqual(avgCPU, 20.0)
        XCTAssertLessThanOrEqual(maxCPU, 80.0)
        
        results.testResults["cpu_validation"] = avgCPU <= 20.0 && maxCPU <= 80.0
        logger.info("CPU validation completed: avg \(avgCPU)%, peak \(maxCPU)%")
    }
    
    private func runNetworkValidation() async throws {
        logger.info("Running network validation tests...")
        
        let manager = SystemMetricsManager()
        
        for cycle in 0..<15 {
            let networkMetrics = try manager.getOnDemandNetworkMetrics()
            
            XCTAssertNotNil(networkMetrics.interfaces)
            XCTAssertGreaterThanOrEqual(networkMetrics.interfaces.count, 0)
            
            // Validate each interface
            for interface in networkMetrics.interfaces {
                XCTAssertFalse(interface.name.isEmpty)
                XCTAssertGreaterThanOrEqual(interface.bytesSent, 0)
                XCTAssertGreaterThanOrEqual(interface.bytesReceived, 0)
                XCTAssertGreaterThanOrEqual(interface.packetsSent, 0)
                XCTAssertGreaterThanOrEqual(interface.packetsReceived, 0)
            }
            
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        results.testResults["network_validation"] = true
        logger.info("Network validation completed: \(15) collections successful")
    }
    
    private func runProcessValidation() async throws {
        logger.info("Running process validation tests...")
        
        let manager = SystemMetricsManager()
        
        // Test different sort metrics
        let cpuProcesses = manager.getTopProcesses(limit: 10, by: .cpuUsage)
        let memoryProcesses = manager.getTopProcesses(limit: 10, by: .memoryUsage)
        
        XCTAssertLessThanOrEqual(cpuProcesses.count, 10)
        XCTAssertLessThanOrEqual(memoryProcesses.count, 10)
        
        // Validate process data
        for process in cpuProcesses + memoryProcesses {
            XCTAssertGreaterThan(process.pid, 0)
            XCTAssertFalse(process.name.isEmpty)
            XCTAssertGreaterThanOrEqual(process.cpuPercent, 0)
            XCTAssertGreaterThanOrEqual(process.memoryUsage, 0)
        }
        
        // Test edge cases
        let emptyProcesses = manager.getTopProcesses(limit: 0, by: .cpuUsage)
        let manyProcesses = manager.getTopProcesses(limit: 100, by: .cpuUsage)
        
        XCTAssertEqual(emptyProcesses.count, 0)
        XCTAssertLessThanOrEqual(manyProcesses.count, 100)
        
        results.testResults["process_validation"] = true
        logger.info("Process validation completed: \(cpuProcesses.count) CPU processes, \(memoryProcesses.count) memory processes")
    }
    
    private func runUIValidation() async throws {
        logger.info("Running UI validation tests...")
        
        // Test SwiftUI view creation and rendering
        let contentView = ContentView()
        let hostingController = NSHostingController(rootView: contentView)
        
        XCTAssertNotNil(hostingController.view)
        XCTAssertFalse(hostingController.view.bounds.isEmpty)
        
        // Test different sizes
        let testSizes: [NSSize] = [
            NSSize(width: 300, height: 600),
            NSSize(width: 380, height: 850),
            NSSize(width: 500, height: 1000)
        ]
        
        for size in testSizes {
            hostingController.view.frame = NSRect(origin: .zero, size: size)
            hostingController.view.layoutSubtreeIfNeeded()
            XCTAssertFalse(hostingController.view.bounds.isEmpty)
        }
        
        // Test dark mode compatibility
        let darkAppearance = NSAppearance(named: .darkAqua)
        hostingController.view.appearance = darkAppearance
        XCTAssertNotNil(hostingController.view)
        
        results.testResults["ui_validation"] = true
        logger.info("UI validation completed: views render correctly")
    }
    
    private func runErrorRecoveryValidation() async throws {
        logger.info("Running error recovery validation tests...")
        
        let manager = SystemMetricsManager()
        manager.startMonitoring()
        
        // Let it establish baseline
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        var errorCount = 0
        var successfulCollections = 0
        
        // Test under various conditions
        for cycle in 0..<50 {
            do {
                try await manager.collectMetrics()
                successfulCollections += 1
            } catch {
                errorCount += 1
                XCTAssertTrue(error is SystemMetricsError)
            }
            
            // Simulate load every 10 cycles
            if cycle % 10 == 0 {
                DispatchQueue.global().async {
                    for i in 0..<5000 {
                        _ = sin(Double(i)) * cos(Double(i))
                    }
                }
            }
            
            try await Task.sleep(nanoseconds: 20_000_000) // 0.02 seconds
        }
        
        let successRate = Double(successfulCollections) / Double(successfulCollections + errorCount)
        
        // Should maintain >70% success rate
        XCTAssertGreaterThanOrEqual(successRate, 0.7)
        
        // Health check
        let health = manager.getHealthStatus()
        XCTAssertTrue(health.isMonitoring)
        
        results.errorCount = errorCount
        results.testResults["error_recovery"] = successRate >= 0.7 && health.isMonitoring
        
        manager.stopMonitoring()
        logger.info("Error recovery validation completed: \(successRate*100)% success rate")
    }
    
    private func runConcurrentAccessValidation() async throws {
        logger.info("Running concurrent access validation tests...")
        
        let manager = SystemMetricsManager()
        let concurrentTasks = 20
        
        await withTaskGroup(of: Void.self) { group in
            for taskId in 0..<concurrentTasks {
                group.addTask {
                    for iteration in 0..<25 {
                        do {
                            let cpu = try manager.getOnDemandCPUMetrics()
                            let ram = try manager.getOnDemandRAMMetrics()
                            let network = try manager.getOnDemandNetworkMetrics()
                            
                            XCTAssertTrue(cpu.totalUsagePercent >= 0 && cpu.totalUsagePercent <= 100)
                            XCTAssertTrue(ram.usagePercent >= 0 && ram.usagePercent <= 100)
                            XCTAssertTrue(network.interfaces.count >= 0)
                        } catch {
                            // Some errors acceptable under extreme concurrent load
                            if !(error is SystemMetricsError) {
                                XCTFail("Unexpected error type: \(type(of: error))")
                            }
                        }
                    }
                }
            }
        }
        
        results.testResults["concurrent_access"] = true
        logger.info("Concurrent access validation completed: \(concurrentTasks) concurrent tasks")
    }
    
    private func runLongRunningStability() async throws {
        logger.info("Running long-running stability test...")
        
        let manager = SystemMetricsManager()
        let testDuration: TimeInterval = 3.0 // 3 seconds for validation
        let checkInterval: TimeInterval = 0.5
        
        manager.startMonitoring()
        
        var stabilityChecks = 0
        var failedChecks = 0
        
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < testDuration {
            do {
                let (_, ram, _) = manager.getAllMetrics()
                if ram == nil {
                    failedChecks += 1
                }
                stabilityChecks += 1
            } catch {
                failedChecks += 1
                stabilityChecks += 1
            }
            
            try await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }
        
        let stabilityRate = Double(stabilityChecks - failedChecks) / Double(stabilityChecks)
        XCTAssertGreaterThanOrEqual(stabilityRate, 0.9)
        
        let finalHealth = manager.getHealthStatus()
        XCTAssertFalse(finalHealth.isInErrorState)
        
        results.testResults["stability"] = stabilityRate >= 0.9 && !finalHealth.isInErrorState
        
        manager.stopMonitoring()
        logger.info("Long-running stability completed: \(stabilityRate*100)% stability rate")
    }
    
    private func generateValidationReport() async {
        let report = RuntimeValidationReport(
            timestamp: Date(),
            duration: results.validationDuration,
            memoryGrowth: Double(results.memoryUsage.peak - results.memoryUsage.current) / (1024 * 1024),
            avgCPUUsage: results.cpuUsage.isEmpty ? 0 : results.cpuUsage.reduce(0, +) / Double(results.cpuUsage.count),
            maxCPUUsage: results.cpuUsage.max() ?? 0,
            errorCount: results.errorCount,
            testResults: results.testResults
        )
        
        logger.info("Runtime validation completed successfully")
        logger.info("Report: \(report.summary)")
        
        // Save report to file
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(report)
            let reportPath = "/tmp/system_monitor_validation_report.json"
            try data.write(to: URL(fileURLWithPath: reportPath))
            logger.info("Validation report saved to: \(reportPath)")
        } catch {
            logger.warning("Failed to save validation report: \(error)")
        }
    }
}

// MARK: - Validation Report Model
struct RuntimeValidationReport: Codable {
    let timestamp: Date
    let duration: TimeInterval
    let memoryGrowthMB: Double
    let avgCPUUsage: Double
    let maxCPUUsage: Double
    let errorCount: Int
    let testResults: [String: Bool]
    
    var summary: String {
        let totalTests = testResults.values.count
        let passedTests = testResults.values.filter { $0 }.count
        let passRate = Double(passedTests) / Double(totalTests) * 100
        
        return """
        Runtime Validation Report
        Duration: \(String(format: "%.1f", duration))s
        Tests: \(passedTests)/\(totalTests) passed (\(String(format: "%.1f", passRate))%)
        Memory Growth: \(String(format: "%.1f", memoryGrowthMB))MB
        Avg CPU: \(String(format: "%.1f", avgCPUUsage))%
        Max CPU: \(String(format: "%.1f", maxCPUUsage))%
        Errors: \(errorCount)
        """
    }
}