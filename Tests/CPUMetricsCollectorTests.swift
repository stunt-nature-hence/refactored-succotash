import XCTest
@testable import SystemMonitorCore

final class CPUMetricsCollectorTests: XCTestCase {
    
    func testCPUMetricsStructure() throws {
        let collector = CPUMetricsCollector()
        
        let metrics = try collector.collectMetrics()
        
        XCTAssertNotNil(metrics)
        XCTAssertLessThanOrEqual(metrics.totalUsagePercent, 100)
        XCTAssertGreaterThanOrEqual(metrics.totalUsagePercent, 0)
    }
    
    func testConsecutiveCPUReadings() throws {
        let collector = CPUMetricsCollector()
        
        _ = try collector.collectMetrics()
        
        let metrics1 = try collector.collectMetrics()
        let metrics2 = try collector.collectMetrics()
        
        XCTAssertGreaterThanOrEqual(metrics1.totalUsagePercent, 0)
        XCTAssertGreaterThanOrEqual(metrics2.totalUsagePercent, 0)
        
        XCTAssertLessThanOrEqual(metrics1.totalUsagePercent, 100)
        XCTAssertLessThanOrEqual(metrics2.totalUsagePercent, 100)
    }
    
    func testCPUMetricsPercentages() throws {
        let collector = CPUMetricsCollector()
        
        _ = try collector.collectMetrics()
        let metrics = try collector.collectMetrics()
        
        let sum = metrics.systemUsagePercent + metrics.userUsagePercent + metrics.idlePercent
        
        XCTAssertAlmostEqual(sum, 100, accuracy: 0.1)
    }
    
    func testCPUMetricsComponentsValid() throws {
        let collector = CPUMetricsCollector()
        
        _ = try collector.collectMetrics()
        let metrics = try collector.collectMetrics()
        
        XCTAssertGreaterThanOrEqual(metrics.systemUsagePercent, 0)
        XCTAssertGreaterThanOrEqual(metrics.userUsagePercent, 0)
        XCTAssertGreaterThanOrEqual(metrics.idlePercent, 0)
        
        XCTAssertLessThanOrEqual(metrics.systemUsagePercent, 100)
        XCTAssertLessThanOrEqual(metrics.userUsagePercent, 100)
        XCTAssertLessThanOrEqual(metrics.idlePercent, 100)
    }
}

extension XCTestCase {
    func XCTAssertAlmostEqual(_ expression1: @autoclosure () throws -> Double, _ expression2: @autoclosure () throws -> Double, accuracy: Double, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
        do {
            let value1 = try expression1()
            let value2 = try expression2()
            XCTAssertLessThanOrEqual(abs(value1 - value2), accuracy, "Values are not almost equal: \(value1) vs \(value2). \(try message())", file: file, line: line)
        } catch {
            XCTFail("Error evaluating expressions: \(error)", file: file, line: line)
        }
    }
}
