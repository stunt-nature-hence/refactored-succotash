import XCTest
@testable import SystemMonitorCore

final class RAMMetricsCollectorTests: XCTestCase {
    
    func testRAMMetricsStructure() throws {
        let collector = RAMMetricsCollector()
        
        let metrics = try collector.collectMetrics()
        
        XCTAssertNotNil(metrics)
        XCTAssertGreater(metrics.totalBytes, 0)
        XCTAssertGreater(metrics.availableBytes, 0)
    }
    
    func testRAMMetricsRanges() throws {
        let collector = RAMMetricsCollector()
        
        let metrics = try collector.collectMetrics()
        
        XCTAssertGreaterThanOrEqual(metrics.usagePercent, 0)
        XCTAssertLessThanOrEqual(metrics.usagePercent, 100)
        
        XCTAssertGreater(metrics.totalBytes, metrics.availableBytes)
        XCTAssertGreater(metrics.usedBytes, 0)
    }
    
    func testRAMMemoryConsistency() throws {
        let collector = RAMMetricsCollector()
        
        let metrics = try collector.collectMetrics()
        
        let sumComponents = metrics.activeBytes + metrics.inactiveBytes + metrics.wiredBytes
        
        XCTAssertGreater(sumComponents, 0)
        XCTAssertLessThanOrEqual(sumComponents, metrics.totalBytes)
    }
    
    func testRAMMetricsPositive() throws {
        let collector = RAMMetricsCollector()
        
        let metrics = try collector.collectMetrics()
        
        XCTAssertGreaterThanOrEqual(metrics.activeBytes, 0)
        XCTAssertGreaterThanOrEqual(metrics.inactiveBytes, 0)
        XCTAssertGreaterThanOrEqual(metrics.wiredBytes, 0)
    }
    
    func testRAMUsagePercentCalculation() throws {
        let collector = RAMMetricsCollector()
        
        let metrics = try collector.collectMetrics()
        
        let expectedUsagePercent = Double(metrics.usedBytes) / Double(metrics.totalBytes) * 100
        
        XCTAssertAlmostEqual(metrics.usagePercent, expectedUsagePercent, accuracy: 1.0)
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
