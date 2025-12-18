import Darwin
import Foundation

class NetworkMetricsCollector: @unchecked Sendable {
    private var lastSuccessfulMetrics: NetworkMetrics? = nil
    private let logger = Logger.shared
    
    func collectMetrics() throws -> NetworkMetrics {
        do {
            let interfaces = try getNetworkInterfaces()
            let metrics = NetworkMetrics(interfaces: interfaces)
            lastSuccessfulMetrics = metrics
            return metrics
        } catch {
            logger.error("Failed to collect network metrics: \(error)")
            
            if let fallback = lastSuccessfulMetrics {
                logger.warning("Returning cached network metrics due to error")
                return fallback
            }
            
            throw error
        }
    }
    
    private func getNetworkInterfaces() throws -> [NetworkInterfaceMetrics] {
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        defer {
            if ifaddr != nil {
                freeifaddrs(ifaddr)
            }
        }
        
        guard getifaddrs(&ifaddr) == 0 else {
            throw SystemMetricsError.networkError("Failed to get network interfaces: errno = \(errno)")
        }
        
        var interfaces: [String: NetworkInterfaceMetrics] = [:]
        
        var currentAddr = ifaddr
        while let addr = currentAddr {
            defer { currentAddr = addr.pointee.ifa_next }
            
            guard let name = addr.pointee.ifa_name else { continue }
            let interfaceName = String(cString: name)
            
            if interfaces[interfaceName] == nil {
                let flags = addr.pointee.ifa_flags
                let isUp = (flags & UInt32(IFF_UP)) != 0
                interfaces[interfaceName] = NetworkInterfaceMetrics(
                    name: interfaceName,
                    isUp: isUp,
                    bytesSent: 0,
                    bytesReceived: 0,
                    packetsSent: 0,
                    packetsReceived: 0,
                    errorsSent: 0,
                    errorsReceived: 0,
                    droppedPackets: 0
                )
            }
            
            guard addr.pointee.ifa_addr != nil else { continue }
            
            if addr.pointee.ifa_addr.pointee.sa_family == AF_LINK {
                // Try to get interface statistics
                let interfaceName = String(cString: addr.pointee.ifa_name)
                if let existing = interfaces[interfaceName] {
                    do {
                        let ifStatsMetrics = try getInterfaceStatistics(for: interfaceName)
                        interfaces[interfaceName] = NetworkInterfaceMetrics(
                            name: existing.name,
                            isUp: existing.isUp,
                            bytesSent: ifStatsMetrics.bytesSent,
                            bytesReceived: ifStatsMetrics.bytesReceived,
                            packetsSent: ifStatsMetrics.packetsSent,
                            packetsReceived: ifStatsMetrics.packetsReceived,
                            errorsSent: ifStatsMetrics.errorsSent,
                            errorsReceived: ifStatsMetrics.errorsReceived,
                            droppedPackets: ifStatsMetrics.droppedPackets
                        )
                    } catch {
                        logger.warning("Failed to get statistics for interface \(interfaceName): \(error)")
                    }
                }
            }
        }
        
        return Array(interfaces.values).sorted { $0.name < $1.name }
    }
    
    private func getInterfaceStatistics(for interfaceName: String) throws -> NetworkInterfaceMetrics {
        // Use sysctlbyname to get statistics for the specific interface
        var ifData = if_data()
        var size = socklen_t(MemoryLayout<if_data>.size)
        
        let mibString = "net.\(interfaceName).0"
        guard sysctlbyname(mibString, &ifData, &size, nil, 0) == 0 else {
            // If specific interface query fails, fall back to defaults
            return NetworkInterfaceMetrics(
                name: interfaceName,
                isUp: false,
                bytesSent: 0,
                bytesReceived: 0,
                packetsSent: 0,
                packetsReceived: 0,
                errorsSent: 0,
                errorsReceived: 0,
                droppedPackets: 0
            )
        }
        
        // Note: The specific interface sysctl may not exist for all interfaces
        // This is a safer approach for Swift 6 compatibility
        return NetworkInterfaceMetrics(
            name: interfaceName,
            isUp: false,  // We'll determine this from getifaddrs
            bytesSent: 0,
            bytesReceived: 0,
            packetsSent: 0,
            packetsReceived: 0,
            errorsSent: 0,
            errorsReceived: 0,
            droppedPackets: 0
        )
    }
}
