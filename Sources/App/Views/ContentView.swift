import SwiftUI

struct ContentView: View {
    @State private var scrollOffset: CGFloat = 0
    
    // Mock CPU data
    private let cpuValue = 45.5
    private let cpuSystemUsage = 12.3
    private let cpuUserUsage = 33.2
    private let cpuIdlePercent = 54.5
    
    // Mock RAM data
    private let ramUsagePercent = 68.2
    private let ramUsedGB = 11.2
    private let ramTotalGB = 16.0
    
    // Mock Network data
    private let networkInterfaces = [
        ("Wi-Fi", 524288.0, 5242880.0, true),
        ("Ethernet", 0.0, 0.0, false)
    ]
    
    // Mock top CPU processes
    private let topCPUProcesses = [
        ProcessItem(id: 1, name: "Safari", usage: 45.5, icon: "app.fill"),
        ProcessItem(id: 2, name: "Chrome", usage: 32.1, icon: "app.fill"),
        ProcessItem(id: 3, name: "Xcode", usage: 28.7, icon: "app.fill"),
        ProcessItem(id: 4, name: "Mail", usage: 12.3, icon: "app.fill")
    ]
    
    // Mock top RAM processes
    private let topRAMProcesses = [
        ProcessItem(id: 1, name: "Chrome", usage: 38.2, icon: "app.fill"),
        ProcessItem(id: 2, name: "Safari", usage: 25.4, icon: "app.fill"),
        ProcessItem(id: 3, name: "Xcode", usage: 18.9, icon: "app.fill"),
        ProcessItem(id: 4, name: "Final Cut Pro", usage: 14.7, icon: "app.fill")
    ]
    
    var body: some View {
        ZStack {
            BackgroundGradient()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    HeaderView()
                    
                    // Quick stats bar
                    QuickStatsView(
                        cpuUsage: cpuValue,
                        ramUsage: ramUsagePercent,
                        networkDownload: 5242880,
                        networkUpload: 524288
                    )
                    .padding(.horizontal, 12)
                    
                    // System health summary
                    SystemDashboardSummary(
                        cpuUsage: cpuValue,
                        ramUsage: ramUsagePercent,
                        networkActive: true
                    )
                    .padding(.horizontal, 12)
                    
                    // Primary metrics - gauges
                    HStack(spacing: 12) {
                        CircularGaugeView(
                            value: cpuValue,
                            total: 100,
                            label: "CPU",
                            color: .blue,
                            size: 70
                        )
                        
                        CircularGaugeView(
                            value: ramUsagePercent,
                            total: 100,
                            label: "RAM",
                            color: .red,
                            size: 70
                        )
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    
                    // CPU Details
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
                    .padding(.horizontal, 12)
                    
                    // RAM Details
                    ResourceMetricView(
                        title: "Memory Usage",
                        systemIcon: "memorychip",
                        value: ramUsagePercent,
                        subtitle: String(format: "%.1f GB of %.1f GB used", ramUsedGB, ramTotalGB),
                        color: .red,
                        details: [
                            ("Used", formatBytes(ramUsedGB * 1024 * 1024 * 1024)),
                            ("Available", formatBytes((ramTotalGB - ramUsedGB) * 1024 * 1024 * 1024))
                        ]
                    )
                    .padding(.horizontal, 12)
                    
                    // Network interfaces
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Network Interfaces", systemImage: "network")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                        
                        VStack(spacing: 8) {
                            ForEach(0..<networkInterfaces.count, id: \.self) { index in
                                let (name, upload, download, connected) = networkInterfaces[index]
                                NetworkCardView(
                                    name: name,
                                    upload: upload,
                                    download: download,
                                    connected: connected
                                )
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                    
                    // Top CPU processes
                    ProcessListView(
                        title: "Top CPU Processes",
                        icon: "chart.bar.fill",
                        processes: topCPUProcesses,
                        color: .blue,
                        unit: "%"
                    )
                    .padding(.horizontal, 12)
                    
                    // Top RAM processes
                    ProcessListView(
                        title: "Top Memory Processes",
                        icon: "chart.pie.fill",
                        processes: topRAMProcesses,
                        color: .red,
                        unit: "%"
                    )
                    .padding(.horizontal, 12)
                    
                    // Footer
                    FooterView(lastUpdate: Date())
                }
                .padding(.vertical, 12)
            }
        }
        .frame(width: 380, height: 850)
    }
    
    private func formatBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .decimal
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct HeaderView: View {
    @State private var isPulsing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("System Monitor")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Real-time metrics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .stroke(Color.green.opacity(0.5), lineWidth: 2)
                        .frame(width: 12, height: 12)
                        .scaleEffect(isPulsing ? 1.3 : 1.0)
                        .opacity(isPulsing ? 0.3 : 0.8)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            }
        }
        .padding(.horizontal, 12)
    }
}

struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(nsColor: NSColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)),
                Color(nsColor: NSColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1))
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
