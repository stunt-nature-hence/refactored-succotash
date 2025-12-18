import XCTest
@testable import SystemMonitorCore

final class SystemMetricsManagerTests: XCTestCase {
    
    func testCPUMetricsCollection() throws {
        let manager = SystemMetricsManager()
        
        let cpuMetrics = try manager.getOnDemandCPUMetrics()
        
        XCTAssertGreaterThanOrEqual(cpuMetrics.totalUsagePercent, 0)
        XCTAssertLessThanOrEqual(cpuMetrics.totalUsagePercent, 100)
        
        XCTAssertGreaterThanOrEqual(cpuMetrics.systemUsagePercent, 0)
        XCTAssertLessThanOrEqual(cpuMetrics.systemUsagePercent, 100)
        
        XCTAssertGreaterThanOrEqual(cpuMetrics.userUsagePercent, 0)
        XCTAssertLessThanOrEqual(cpuMetrics.userUsagePercent, 100)
        
        XCTAssertGreaterThanOrEqual(cpuMetrics.idlePercent, 0)
        XCTAssertLessThanOrEqual(cpuMetrics.idlePercent, 100)
        
        let sum = cpuMetrics.systemUsagePercent + cpuMetrics.userUsagePercent + cpuMetrics.idlePercent
        XCTAssertAlmostEqual(sum, 100, accuracy: 0.1)
    }
    
    func testRAMMetricsCollection() throws {
        let manager = SystemMetricsManager()
        
        let ramMetrics = try manager.getOnDemandRAMMetrics()
        
        XCTAssertGreater(ramMetrics.totalBytes, 0)
        XCTAssertGreater(ramMetrics.availableBytes, 0)
        XCTAssertGreater(ramMetrics.usedBytes, 0)
        
        XCTAssertLessThanOrEqual(ramMetrics.usedBytes + ramMetrics.availableBytes, ramMetrics.totalBytes + 1_000_000_000)
        
        XCTAssertGreaterThanOrEqual(ramMetrics.usagePercent, 0)
        XCTAssertLessThanOrEqual(ramMetrics.usagePercent, 100)
        
        XCTAssertGreaterThanOrEqual(ramMetrics.activeBytes, 0)
        XCTAssertGreaterThanOrEqual(ramMetrics.inactiveBytes, 0)
        XCTAssertGreaterThanOrEqual(ramMetrics.wiredBytes, 0)
    }
    
    func testNetworkMetricsCollection() throws {
        let manager = SystemMetricsManager()
        
        let networkMetrics = try manager.getOnDemandNetworkMetrics()
        
        XCTAssertNotNil(networkMetrics.interfaces)
        XCTAssertGreater(networkMetrics.interfaces.count, 0)
        
        for interface in networkMetrics.interfaces {
            XCTAssertFalse(interface.name.isEmpty)
            XCTAssertGreaterThanOrEqual(interface.bytesSent, 0)
            XCTAssertGreaterThanOrEqual(interface.bytesReceived, 0)
            XCTAssertGreaterThanOrEqual(interface.packetsSent, 0)
            XCTAssertGreaterThanOrEqual(interface.packetsReceived, 0)
            XCTAssertGreaterThanOrEqual(interface.errorsSent, 0)
            XCTAssertGreaterThanOrEqual(interface.errorsReceived, 0)
            XCTAssertGreaterThanOrEqual(interface.droppedPackets, 0)
        }
    }
    
    func testOnDemandMetricsRetrieval() throws {
        let manager = SystemMetricsManager()
        
        let cpu = try manager.getOnDemandCPUMetrics()
        let ram = try manager.getOnDemandRAMMetrics()
        let network = try manager.getOnDemandNetworkMetrics()
        
        XCTAssertNotNil(cpu)
        XCTAssertNotNil(ram)
        XCTAssertNotNil(network)
    }
    
    func testMetricsTimestamps() throws {
        let manager = SystemMetricsManager()
        let before = Date()
        
        let cpuMetrics = try manager.getOnDemandCPUMetrics()
        let ramMetrics = try manager.getOnDemandRAMMetrics()
        let networkMetrics = try manager.getOnDemandNetworkMetrics()
        
        let after = Date()
        
        XCTAssertGreaterThanOrEqual(cpuMetrics.timestamp, before)
        XCTAssertLessThanOrEqual(cpuMetrics.timestamp, after)
        
        XCTAssertGreaterThanOrEqual(ramMetrics.timestamp, before)
        XCTAssertLessThanOrEqual(ramMetrics.timestamp, after)
        
        XCTAssertGreaterThanOrEqual(networkMetrics.timestamp, before)
        XCTAssertLessThanOrEqual(networkMetrics.timestamp, after)
    }
    
    func testMultipleMetricsCollections() throws {
        let manager = SystemMetricsManager()
        
        let firstCPU = try manager.getOnDemandCPUMetrics()
        let secondCPU = try manager.getOnDemandCPUMetrics()
        
        XCTAssertNotEqual(firstCPU.timestamp, secondCPU.timestamp)
    }
    
    func testCPUMetricsCodable() throws {
        let manager = SystemMetricsManager()
        let original = try manager.getOnDemandCPUMetrics()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CPUMetrics.self, from: data)
        
        XCTAssertEqual(decoded.totalUsagePercent, original.totalUsagePercent)
        XCTAssertEqual(decoded.systemUsagePercent, original.systemUsagePercent)
        XCTAssertEqual(decoded.userUsagePercent, original.userUsagePercent)
        XCTAssertEqual(decoded.idlePercent, original.idlePercent)
    }
    
    func testRAMMetricsCodable() throws {
        let manager = SystemMetricsManager()
        let original = try manager.getOnDemandRAMMetrics()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RAMMetrics.self, from: data)
        
        XCTAssertEqual(decoded.totalBytes, original.totalBytes)
        XCTAssertEqual(decoded.usedBytes, original.usedBytes)
        XCTAssertEqual(decoded.availableBytes, original.availableBytes)
        XCTAssertEqual(decoded.usagePercent, original.usagePercent)
    }
    
    func testNetworkMetricsCodable() throws {
        let manager = SystemMetricsManager()
        let original = try manager.getOnDemandNetworkMetrics()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(NetworkMetrics.self, from: data)
        
        XCTAssertEqual(decoded.interfaces.count, original.interfaces.count)
        
        for (originalInterface, decodedInterface) in zip(original.interfaces, decoded.interfaces) {
            XCTAssertEqual(decodedInterface.name, originalInterface.name)
            XCTAssertEqual(decodedInterface.bytesSent, originalInterface.bytesSent)
            XCTAssertEqual(decodedInterface.bytesReceived, originalInterface.bytesReceived)
        }
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
