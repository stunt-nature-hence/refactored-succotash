# UI Integration Guide - Liquid Glass Dashboard

## Quick Start

The liquid glass UI is fully implemented with mock data. To integrate with real data from SystemMetricsManager and ProcessMonitor:

## Step 1: Import Required Modules in ContentView

```swift
import SwiftUI
import SystemMonitorCore
```

## Step 2: Add Observable State

Replace the mock data with actual data from SystemMetricsManager:

```swift
struct ContentView: View {
    @State private var systemMetricsManager = SystemMetricsManager.shared
    @State private var currentCPUMetrics: CPUMetrics?
    @State private var currentRAMMetrics: RAMMetrics?
    @State private var topProcessesCPU: [ProcessMetrics] = []
    @State private var topProcessesRAM: [ProcessMetrics] = []
    
    // Remove mock data definitions
}
```

## Step 3: Add Data Collection in .onAppear

```swift
.onAppear {
    // Start background monitoring
    Task {
        await systemMetricsManager.startBackgroundMonitoring(samplingInterval: 1.0)
        
        // Fetch initial metrics
        await fetchMetrics()
        
        // Set up periodic updates
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task {
                await fetchMetrics()
            }
        }
    }
}

private func fetchMetrics() async {
    if let cpuMetrics = await systemMetricsManager.getLatestCPUMetrics() {
        await MainActor.run {
            self.currentCPUMetrics = cpuMetrics
        }
    }
    
    if let ramMetrics = await systemMetricsManager.getLatestRAMMetrics() {
        await MainActor.run {
            self.currentRAMMetrics = ramMetrics
        }
    }
}
```

## Step 4: Replace Mock Values with Real Data

### CPU Gauge
```swift
// Before (mock)
CircularGaugeView(
    value: cpuValue,  // 45.5
    total: 100,
    label: "CPU",
    color: .blue,
    size: 70
)

// After (real data)
CircularGaugeView(
    value: currentCPUMetrics?.totalUsagePercent ?? 0,
    total: 100,
    label: "CPU",
    color: .blue,
    size: 70
)
```

### CPU Details Card
```swift
// Before (mock)
ResourceMetricView(
    title: "CPU Usage",
    systemIcon: "cpu",
    value: cpuValue,
    subtitle: "System is performing well",
    color: .blue,
    details: [
        ("System", String(format: "%.1f%%", cpuSystemUsage)),
        ("User", String(format: "%.1f%%", cpuUserUsage)),
        ("Idle", String(format: "%.1f%%", cpuIdlePercent))
    ]
)

// After (real data)
ResourceMetricView(
    title: "CPU Usage",
    systemIcon: "cpu",
    value: currentCPUMetrics?.totalUsagePercent ?? 0,
    subtitle: "System is performing well",
    color: .blue,
    details: [
        ("System", String(format: "%.1f%%", currentCPUMetrics?.systemUsagePercent ?? 0)),
        ("User", String(format: "%.1f%%", currentCPUMetrics?.userUsagePercent ?? 0)),
        ("Idle", String(format: "%.1f%%", currentCPUMetrics?.idlePercent ?? 0))
    ]
)
```

### RAM Gauge and Details
```swift
// Before (mock)
CircularGaugeView(
    value: ramUsagePercent,  // 68.2
    total: 100,
    label: "RAM",
    color: .red,
    size: 70
)

// After (real data)
CircularGaugeView(
    value: currentRAMMetrics?.usagePercent ?? 0,
    total: 100,
    label: "RAM",
    color: .red,
    size: 70
)
```

## Step 5: Connect Top Processes

### Update ProcessListView with Real Data

```swift
// Before (mock data)
let topCPUProcesses = [
    ProcessItem(id: 1, name: "Safari", usage: 45.5, icon: "app.fill"),
    // ... more mock items
]

// After (real data)
var topCPUProcesses: [ProcessItem] {
    topProcessesCPU.prefix(4).map { process in
        ProcessItem(
            id: Int(process.id),
            name: process.name,
            usage: process.cpuUsagePercent,
            icon: "app.fill"
        )
    }
}
```

## Step 6: Network Integration

For network metrics, use NetworkMetricsCollector:

```swift
@State private var networkMetrics: NetworkMetrics?

private func fetchNetworkMetrics() async {
    let collector = NetworkMetricsCollector()
    if let metrics = try? await collector.collectMetrics() {
        await MainActor.run {
            self.networkMetrics = metrics
        }
    }
}
```

Then update NetworkCardView:

```swift
ForEach(networkMetrics?.interfaces ?? [], id: \.name) { interface in
    NetworkCardView(
        name: interface.name,
        upload: interface.bytesSent,
        download: interface.bytesReceived,
        connected: interface.isUp
    )
}
```

## Component Data Mapping

### QuickStatsView
```swift
QuickStatsView(
    cpuUsage: currentCPUMetrics?.totalUsagePercent ?? 0,
    ramUsage: currentRAMMetrics?.usagePercent ?? 0,
    networkDownload: networkMetrics?.totalBytesReceived ?? 0,
    networkUpload: networkMetrics?.totalBytesSent ?? 0
)
```

### SystemDashboardSummary
```swift
SystemDashboardSummary(
    cpuUsage: currentCPUMetrics?.totalUsagePercent ?? 0,
    ramUsage: currentRAMMetrics?.usagePercent ?? 0,
    networkActive: networkMetrics?.interfaces.first?.isUp ?? false
)
```

## Error Handling

Wrap metric collection in try-catch:

```swift
private func fetchMetrics() async {
    do {
        if let cpuMetrics = try await systemMetricsManager.getLatestCPUMetrics() {
            await MainActor.run {
                self.currentCPUMetrics = cpuMetrics
            }
        }
    } catch {
        print("Error fetching CPU metrics: \(error)")
        // Show error UI if needed
    }
}
```

## Performance Considerations

1. **Update Frequency**: Set sampling interval based on UI responsiveness needs
2. **Main Thread**: Always update UI on MainActor
3. **Memory**: Consider limiting process list history
4. **Battery**: On laptop, reduce update frequency when on battery

## Cleanup

Don't forget to stop monitoring when the popover closes:

```swift
.onDisappear {
    Task {
        await systemMetricsManager.stopBackgroundMonitoring()
    }
}
```

## Testing Real Data

To test with real data before full integration:

```swift
#if DEBUG
let debugCPUMetrics = CPUMetrics(
    timestamp: Date(),
    totalUsagePercent: 45.5,
    systemUsagePercent: 12.3,
    userUsagePercent: 33.2,
    idlePercent: 54.5
)
#endif
```

## Available Data Sources

### CPUMetrics
- `timestamp: Date`
- `totalUsagePercent: Double`
- `systemUsagePercent: Double`
- `userUsagePercent: Double`
- `idlePercent: Double`

### RAMMetrics
- `timestamp: Date`
- `usedBytes: UInt64`
- `availableBytes: UInt64`
- `totalBytes: UInt64`
- `usagePercent: Double`
- `activeBytes: UInt64`
- `inactiveBytes: UInt64`
- `wiredBytes: UInt64`

### NetworkMetrics
- `timestamp: Date`
- `interfaces: [NetworkInterfaceMetrics]`
- `totalBytesSent: UInt64`
- `totalBytesReceived: UInt64`

### NetworkInterfaceMetrics
- `name: String`
- `isUp: Bool`
- `bytesSent: UInt64`
- `bytesReceived: UInt64`
- `packetsIn: UInt64`
- `packetsOut: UInt64`

### ProcessMetrics
- `id: Int32` (PID)
- `name: String`
- `cpuUsagePercent: Double`
- `memoryUsageBytes: UInt64`
- `networkBytesSent: UInt64`
- `networkBytesReceived: UInt64`

## Common Integration Patterns

### Pattern 1: Direct Value Replacement
```swift
value: currentCPUMetrics?.totalUsagePercent ?? 0
```

### Pattern 2: Conditional Rendering
```swift
if let metrics = currentCPUMetrics {
    Text(String(format: "%.1f%%", metrics.totalUsagePercent))
} else {
    Text("--")
}
```

### Pattern 3: Array Mapping
```swift
topProcessesCPU
    .sorted { $0.cpuUsagePercent > $1.cpuUsagePercent }
    .prefix(4)
    .map { process in
        ProcessItem(...)
    }
```

## Next Steps

1. Uncomment real data collection code
2. Remove mock data definitions
3. Add error handling UI
4. Test on actual system
5. Optimize update frequencies based on performance
6. Add user preferences for update rates

## Troubleshooting

**Metrics show as 0%?**
- Ensure SystemMetricsManager is started
- Check that sampling interval is set correctly

**UI doesn't update?**
- Verify MainActor.run() is used for UI updates
- Check that @State properties are being modified

**Popover jumps?**
- Ensure consistent frame sizes in ContentView
- Test with different data values

**Performance issues?**
- Reduce update frequency
- Limit process list size
- Use throttling for rapid updates
