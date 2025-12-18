import Foundation
import SwiftUI
import Combine
import SystemMonitorCore

class MetricsViewModel: NSObject, ObservableObject {
    @Published var cpuUsage: Double = 0
    @Published var cpuSystemUsage: Double = 0
    @Published var cpuUserUsage: Double = 0
    @Published var cpuIdlePercent: Double = 100
    
    @Published var ramUsagePercent: Double = 0
    @Published var ramUsedBytes: UInt64 = 0
    @Published var ramTotalBytes: UInt64 = 0
    
    @Published var networkInterfaces: [(name: String, upload: UInt64, download: UInt64, connected: Bool)] = []
    
    @Published var topCPUProcesses: [ProcessMetricsUI] = []
    @Published var topRAMProcesses: [ProcessMetricsUI] = []
    
    @Published var lastUpdateTime: Date = Date()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let metricsManager: SystemMetricsManager
    private var updateTimer: Timer?
    private var updateInterval: TimeInterval = 1.0
    
    private let debounceDelay: TimeInterval = 0.1
    private var lastUpdateTrigger: Date = Date()
    
    override init() {
        self.metricsManager = SystemMetricsManager.shared
        super.init()
        setupMonitoring()
    }
    
    private func setupMonitoring() {
        Task {
            await metricsManager.startMonitoring()
            DispatchQueue.main.async {
                self.startUpdateTimer()
                Task {
                    await self.updateMetrics()
                }
            }
        }
    }
    
    private func startUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.triggerUpdate()
        }
    }
    
    private func triggerUpdate() {
        let now = Date()
        if now.timeIntervalSince(lastUpdateTrigger) >= debounceDelay {
            lastUpdateTrigger = now
            Task {
                await self.updateMetrics()
            }
        }
    }
    
    private func updateMetrics() async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        do {
            let (cpuMetrics, ramMetrics, networkMetrics) = await metricsManager.getAllMetrics()
            
            let cpuProcesses = await metricsManager.getTopProcesses(limit: 4, by: .cpu)
            let ramProcesses = await metricsManager.getTopProcesses(limit: 4, by: .memory)
            
            DispatchQueue.main.async {
                if let cpuMetrics = cpuMetrics {
                    self.cpuUsage = cpuMetrics.totalUsagePercent
                    self.cpuSystemUsage = cpuMetrics.systemUsagePercent
                    self.cpuUserUsage = cpuMetrics.userUsagePercent
                    self.cpuIdlePercent = cpuMetrics.idlePercent
                }
                
                if let ramMetrics = ramMetrics {
                    self.ramUsagePercent = ramMetrics.usagePercent
                    self.ramUsedBytes = ramMetrics.usedBytes
                    self.ramTotalBytes = ramMetrics.totalBytes
                }
                
                if let networkMetrics = networkMetrics {
                    self.networkInterfaces = networkMetrics.interfaces.map { iface in
                        (name: iface.name, upload: iface.bytesSent, download: iface.bytesReceived, connected: iface.isUp)
                    }
                }
                
                self.topCPUProcesses = cpuProcesses.map { ProcessMetricsUI(from: $0, displayMetric: .cpu) }
                self.topRAMProcesses = ramProcesses.map { ProcessMetricsUI(from: $0, displayMetric: .memory) }
                
                self.lastUpdateTime = Date()
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to collect metrics: \(error.localizedDescription)"
                print("Error updating metrics: \(error)")
            }
        }
    }
    
    func setUpdateInterval(_ interval: TimeInterval) {
        updateInterval = max(0.5, interval)
        Task {
            await metricsManager.setSamplingInterval(updateInterval)
        }
        startUpdateTimer()
    }
    
    deinit {
        updateTimer?.invalidate()
        Task {
            await metricsManager.stopMonitoring()
        }
    }
}

struct ProcessMetricsUI: Identifiable {
    let id: Int32
    let name: String
    let usage: Double
    let icon: String = "app.fill"
    
    init(from metrics: ProcessMetrics, displayMetric: ProcessSortMetric = .cpu) {
        self.id = metrics.id
        self.name = metrics.name
        
        switch displayMetric {
        case .cpu:
            self.usage = metrics.cpuUsagePercent
        case .memory:
            let memoryGB = Double(metrics.memoryUsageBytes) / (1024 * 1024 * 1024)
            self.usage = memoryGB
        case .network:
            let networkMB = Double(metrics.networkBytesSent + metrics.networkBytesReceived) / (1024 * 1024)
            self.usage = networkMB
        }
    }
}
