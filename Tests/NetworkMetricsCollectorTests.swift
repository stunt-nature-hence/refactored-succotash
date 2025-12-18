import XCTest
@testable import SystemMonitorCore

final class NetworkMetricsCollectorTests: XCTestCase {
    
    func testNetworkMetricsStructure() throws {
        let collector = NetworkMetricsCollector()
        
        let metrics = try collector.collectMetrics()
        
        XCTAssertNotNil(metrics)
        XCTAssertNotNil(metrics.interfaces)
    }
    
    func testNetworkInterfacesExist() throws {
        let collector = NetworkMetricsCollector()
        
        let metrics = try collector.collectMetrics()
        
        XCTAssertGreater(metrics.interfaces.count, 0)
    }
    
    func testNetworkInterfaceProperties() throws {
        let collector = NetworkMetricsCollector()
        
        let metrics = try collector.collectMetrics()
        
        for interface in metrics.interfaces {
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
    
    func testNetworkInterfaceUniqueness() throws {
        let collector = NetworkMetricsCollector()
        
        let metrics = try collector.collectMetrics()
        
        let names = Set(metrics.interfaces.map { $0.name })
        XCTAssertEqual(names.count, metrics.interfaces.count)
    }
    
    func testNetworkInterfacesSorted() throws {
        let collector = NetworkMetricsCollector()
        
        let metrics = try collector.collectMetrics()
        
        let sortedNames = metrics.interfaces.map { $0.name }
        let expectedSorted = sortedNames.sorted()
        
        XCTAssertEqual(sortedNames, expectedSorted)
    }
    
    func testConsecutiveNetworkReadings() throws {
        let collector = NetworkMetricsCollector()
        
        let metrics1 = try collector.collectMetrics()
        let metrics2 = try collector.collectMetrics()
        
        XCTAssertNotNil(metrics1)
        XCTAssertNotNil(metrics2)
        
        XCTAssertGreater(metrics1.interfaces.count, 0)
        XCTAssertGreater(metrics2.interfaces.count, 0)
    }
}
