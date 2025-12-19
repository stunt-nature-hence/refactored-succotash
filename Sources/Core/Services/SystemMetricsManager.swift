import Foundation

public actor SystemMetricsManager {
    public static let shared = SystemMetricsManager()
    
    private let cpuCollector: CPUMetricsCollector
    private let ramCollector: RAMMetricsCollector
    private let networkCollector: NetworkMetricsCollector
    private let processMonitor: OptimizedProcessMonitor
    
    private var samplingInterval: TimeInterval = 1.0
    private var minSamplingInterval: TimeInterval = 0.5
    private var isMonitoring: Bool = false
    private var monitoringTask: Task<Void, Never>?
    
    private var cpuUpdateInterval: TimeInterval = 1.0
    private var ramUpdateInterval: TimeInterval = 2.0
    private var networkUpdateInterval: TimeInterval = 3.0
    
    private var consecutiveErrors: Int = 0
    private var maxConsecutiveErrors: Int = 5
    private var isInErrorState: Bool = false
    
    private nonisolated(unsafe) var lastCPUMetrics: CPUMetrics?
    private nonisolated(unsafe) var lastRAMMetrics: RAMMetrics?
    private nonisolated(unsafe) var lastNetworkMetrics: NetworkMetrics?
    
    private nonisolated(unsafe) var lastCPUUpdateTime: TimeInterval = 0
    private nonisolated(unsafe) var lastRAMUpdateTime: TimeInterval = 0
    private nonisolated(unsafe) var lastNetworkUpdateTime: TimeInterval = 0
    
    private let logger = Logger.shared
    
    public init() {
        self.cpuCollector = CPUMetricsCollector()
        self.ramCollector = RAMMetricsCollector()
        self.networkCollector = NetworkMetricsCollector()
        self.processMonitor = OptimizedProcessMonitor()
        logger.info("SystemMetricsManager initialized")
    }
    
    public func setSamplingInterval(_ interval: TimeInterval) {
        samplingInterval = max(minSamplingInterval, interval)
        logger.info("Sampling interval set to \(samplingInterval)s")
    }
    
    public func startMonitoring() {
        guard !isMonitoring else { 
            logger.warning("Monitoring already started, ignoring")
            return 
        }
        isMonitoring = true
        logger.info("Starting background monitoring")
        
        monitoringTask = Task {
            while !Task.isCancelled && isMonitoring {
                await collectMetricsWithErrorHandling()
                
                try? await Task.sleep(nanoseconds: UInt64(samplingInterval * 1_000_000_000))
            }
            logger.info("Monitoring task completed")
        }
    }
    
    public func stopMonitoring() {
        guard isMonitoring else { return }
        logger.info("Stopping background monitoring")
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    private func collectMetricsWithErrorHandling() async {
        do {
            try await collectMetrics()
            
            if isInErrorState {
                logger.info("Recovered from error state")
                consecutiveErrors = 0
                isInErrorState = false
            }
            
            MemoryProfiler.shared.logMemoryUsageIfNeeded()
            
            if MemoryProfiler.shared.checkMemoryPressure() {
                logger.warning("High memory pressure detected, triggering cache cleanup")
                processMonitor.resetCache()
            }
        } catch {
            consecutiveErrors += 1
            logger.error("Error collecting metrics (\(consecutiveErrors)/\(maxConsecutiveErrors)): \(error)")
            
            if consecutiveErrors >= maxConsecutiveErrors && !isInErrorState {
                isInErrorState = true
                logger.error("Entered error state after \(consecutiveErrors) consecutive errors")
            }
            
            if consecutiveErrors > maxConsecutiveErrors * 2 {
                logger.warning("Too many errors, backing off")
                try? await Task.sleep(nanoseconds: UInt64(samplingInterval * 3 * 1_000_000_000))
            }
        }
    }
    
    public func collectMetrics() async throws {
        let now = Date().timeIntervalSince1970
        
        var cpuMetrics: CPUMetrics? = nil
        var ramMetrics: RAMMetrics? = nil
        var networkMetrics: NetworkMetrics? = nil
        
        if now - lastCPUUpdateTime >= cpuUpdateInterval {
            do {
                cpuMetrics = try cpuCollector.collectMetrics()
                lastCPUUpdateTime = now
            } catch {
                logger.warning("Failed to collect CPU metrics: \(error)")
            }
        }
        
        if now - lastRAMUpdateTime >= ramUpdateInterval {
            do {
                ramMetrics = try ramCollector.collectMetrics()
                lastRAMUpdateTime = now
            } catch {
                logger.warning("Failed to collect RAM metrics: \(error)")
            }
        }
        
        if now - lastNetworkUpdateTime >= networkUpdateInterval {
            do {
                networkMetrics = try networkCollector.collectMetrics()
                lastNetworkUpdateTime = now
            } catch {
                logger.warning("Failed to collect network metrics: \(error)")
            }
        }
        
        if let cpu = cpuMetrics { lastCPUMetrics = cpu }
        if let ram = ramMetrics { lastRAMMetrics = ram }
        if let network = networkMetrics { lastNetworkMetrics = network }
    }
    
    public func getCPUMetrics() -> CPUMetrics? {
        return lastCPUMetrics
    }
    
    public func getRAMMetrics() -> RAMMetrics? {
        return lastRAMMetrics
    }
    
    public func getNetworkMetrics() -> NetworkMetrics? {
        return lastNetworkMetrics
    }
    
    public func getAllMetrics() -> (cpu: CPUMetrics?, ram: RAMMetrics?, network: NetworkMetrics?) {
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
    
    public func resetCaches() {
        logger.info("Resetting all caches")
        processMonitor.resetCache()
        
        lastCPUMetrics = nil
        lastRAMMetrics = nil
        lastNetworkMetrics = nil
        lastCPUUpdateTime = 0
        lastRAMUpdateTime = 0
        lastNetworkUpdateTime = 0
    }
    
    public func getHealthStatus() -> (isHealthy: Bool, errorCount: Int, isMonitoring: Bool) {
        return (!isInErrorState, consecutiveErrors, isMonitoring)
    }
    
    deinit {
        logger.info("SystemMetricsManager deinit")
        stopMonitoring()
    }
}
