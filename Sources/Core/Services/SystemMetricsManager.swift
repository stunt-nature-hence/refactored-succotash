import Foundation

public actor SystemMetricsManager {
    public static let shared = SystemMetricsManager()
    
    private let cpuCollector: CPUMetricsCollector
    private let ramCollector: RAMMetricsCollector
    private let networkCollector: NetworkMetricsCollector
    private let processMonitor: ProcessMonitor
    
    private var samplingInterval: TimeInterval = 1.0
    private var isMonitoring: Bool = false
    private var monitoringTask: Task<Void, Never>?
    
    private var lastCPUMetrics: CPUMetrics?
    private var lastRAMMetrics: RAMMetrics?
    private var lastNetworkMetrics: NetworkMetrics?
    
    private let metricsLock = NSLock()
    
    public init() {
        self.cpuCollector = CPUMetricsCollector()
        self.ramCollector = RAMMetricsCollector()
        self.networkCollector = NetworkMetricsCollector()
        self.processMonitor = ProcessMonitor()
    }
    
    public func setSamplingInterval(_ interval: TimeInterval) {
        samplingInterval = max(0.1, interval)
    }
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitoringTask = Task {
            while !Task.isCancelled && isMonitoring {
                do {
                    try await collectMetrics()
                } catch {
                    print("Error collecting metrics: \(error)")
                }
                
                try? await Task.sleep(nanoseconds: UInt64(samplingInterval * 1_000_000_000))
            }
        }
    }
    
    public func stopMonitoring() {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    public func collectMetrics() async throws {
        let cpuMetrics = try cpuCollector.collectMetrics()
        let ramMetrics = try ramCollector.collectMetrics()
        let networkMetrics = try networkCollector.collectMetrics()
        
        metricsLock.lock()
        defer { metricsLock.unlock() }
        
        lastCPUMetrics = cpuMetrics
        lastRAMMetrics = ramMetrics
        lastNetworkMetrics = networkMetrics
    }
    
    public func getCPUMetrics() -> CPUMetrics? {
        metricsLock.lock()
        defer { metricsLock.unlock() }
        return lastCPUMetrics
    }
    
    public func getRAMMetrics() -> RAMMetrics? {
        metricsLock.lock()
        defer { metricsLock.unlock() }
        return lastRAMMetrics
    }
    
    public func getNetworkMetrics() -> NetworkMetrics? {
        metricsLock.lock()
        defer { metricsLock.unlock() }
        return lastNetworkMetrics
    }
    
    public func getAllMetrics() -> (cpu: CPUMetrics?, ram: RAMMetrics?, network: NetworkMetrics?) {
        metricsLock.lock()
        defer { metricsLock.unlock() }
        return (lastCPUMetrics, lastRAMMetrics, lastNetworkMetrics)
    }
    
    public func getOnDemandCPUMetrics() throws -> CPUMetrics {
        try cpuCollector.collectMetrics()
    }
    
    public func getOnDemandRAMMetrics() throws -> RAMMetrics {
        try ramCollector.collectMetrics()
    }
    
    public func getOnDemandNetworkMetrics() throws -> NetworkMetrics {
        try networkCollector.collectMetrics()
    }
    
    public func getTopProcesses(limit: Int = 5, by metric: ProcessSortMetric) -> [ProcessMetrics] {
        return processMonitor.topProcesses(limit: limit, by: metric)
    }
}
