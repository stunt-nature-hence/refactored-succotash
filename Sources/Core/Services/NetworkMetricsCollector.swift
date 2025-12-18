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
                if let sdl = UnsafeMutableRawPointer(addr.pointee.ifa_addr)
                    .assumingMemoryBound(to: sockaddr_dl.self).pointee as sockaddr_dl? {
                    var ifStatsMetrics = try getInterfaceStatistics(for: interfaceName)
                    
                    if let existing = interfaces[interfaceName] {
                        ifStatsMetrics = NetworkInterfaceMetrics(
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
                        interfaces[interfaceName] = ifStatsMetrics
                    }
                }
            }
        }
        
        return Array(interfaces.values).sorted { $0.name < $1.name }
    }
    
    private func getInterfaceStatistics(for interfaceName: String) throws -> NetworkInterfaceMetrics {
        var mib = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var size: size_t = 0
        
        guard sysctl(&mib, 6, nil, &size, nil, 0) == 0 else {
            throw SystemMetricsError.networkError("Failed to get interface list size: errno = \(errno)")
        }
        
        var buf = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 6, &buf, &size, nil, 0) == 0 else {
            throw SystemMetricsError.networkError("Failed to get interface list: errno = \(errno)")
        }
        
        var bytesSent: UInt64 = 0
        var bytesReceived: UInt64 = 0
        var packetsSent: UInt64 = 0
        var packetsReceived: UInt64 = 0
        var errorsSent: UInt64 = 0
        var errorsReceived: UInt64 = 0
        var droppedPackets: UInt64 = 0
        var isUp = false
        
        var ptr = 0
        while ptr < buf.count {
            guard ptr + MemoryLayout<if_msghdr>.size <= buf.count else { break }
            
            let ifmPtr = UnsafeMutableRawPointer(mutating: buf).advanced(by: ptr)
            let ifm = ifmPtr.assumingMemoryBound(to: if_msghdr.self).pointee
            
            ptr += Int(ifm.ifm_len)
            
            guard ifm.ifm_type == RTM_IFINFO else { continue }
            
            let ifData = ifm.ifm_data
            let currentName = String(cString: ifm.ifm_name)
            
            guard currentName == interfaceName else { continue }
            
            bytesSent = ifData.ifi_obytes
            bytesReceived = ifData.ifi_ibytes
            packetsSent = ifData.ifi_opackets
            packetsReceived = ifData.ifi_ipackets
            errorsSent = ifData.ifi_oerrors
            errorsReceived = ifData.ifi_ierrors
            droppedPackets = ifData.ifi_iqdrops
            isUp = (ifm.ifm_flags & UInt16(IFF_UP)) != 0
            
            break
        }
        
        return NetworkInterfaceMetrics(
            name: interfaceName,
            isUp: isUp,
            bytesSent: bytesSent,
            bytesReceived: bytesReceived,
            packetsSent: packetsSent,
            packetsReceived: packetsReceived,
            errorsSent: errorsSent,
            errorsReceived: errorsReceived,
            droppedPackets: droppedPackets
        )
    }
}
