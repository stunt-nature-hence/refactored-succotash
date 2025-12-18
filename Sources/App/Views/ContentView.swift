import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MetricsViewModel()
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            BackgroundGradient()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    HeaderView(isLoading: viewModel.isLoading)
                    
                    if let errorMessage = viewModel.errorMessage {
                        ErrorBannerView(message: errorMessage)
                            .padding(.horizontal, 12)
                    }
                    
                    let networkDownload = viewModel.networkInterfaces.reduce(0) { $0 + $1.download }
                    let networkUpload = viewModel.networkInterfaces.reduce(0) { $0 + $1.upload }
                    
                    // Quick stats bar
                    QuickStatsView(
                        cpuUsage: viewModel.cpuUsage,
                        ramUsage: viewModel.ramUsagePercent,
                        networkDownload: networkDownload,
                        networkUpload: networkUpload
                    )
                    .padding(.horizontal, 12)
                    
                    // System health summary
                    SystemDashboardSummary(
                        cpuUsage: viewModel.cpuUsage,
                        ramUsage: viewModel.ramUsagePercent,
                        networkActive: networkDownload > 0 || networkUpload > 0
                    )
                    .padding(.horizontal, 12)
                    
                    // Primary metrics - gauges
                    HStack(spacing: 12) {
                        CircularGaugeView(
                            value: viewModel.cpuUsage,
                            total: 100,
                            label: "CPU",
                            color: .blue,
                            size: 70
                        )
                        
                        CircularGaugeView(
                            value: viewModel.ramUsagePercent,
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
                        value: viewModel.cpuUsage,
                        subtitle: "System performance",
                        color: .blue,
                        details: [
                            ("System", String(format: "%.1f%%", viewModel.cpuSystemUsage)),
                            ("User", String(format: "%.1f%%", viewModel.cpuUserUsage)),
                            ("Idle", String(format: "%.1f%%", viewModel.cpuIdlePercent))
                        ]
                    )
                    .padding(.horizontal, 12)
                    
                    // RAM Details
                    let ramUsedGB = Double(viewModel.ramUsedBytes) / (1024 * 1024 * 1024)
                    let ramTotalGB = Double(viewModel.ramTotalBytes) / (1024 * 1024 * 1024)
                    
                    ResourceMetricView(
                        title: "Memory Usage",
                        systemIcon: "memorychip",
                        value: viewModel.ramUsagePercent,
                        subtitle: String(format: "%.1f GB of %.1f GB used", ramUsedGB, ramTotalGB),
                        color: .red,
                        details: [
                            ("Used", formatBytes(Double(viewModel.ramUsedBytes))),
                            ("Available", formatBytes(Double(viewModel.ramTotalBytes - viewModel.ramUsedBytes)))
                        ]
                    )
                    .padding(.horizontal, 12)
                    
                    // Network interfaces
                    if !viewModel.networkInterfaces.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Network Interfaces", systemImage: "network")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                            
                            VStack(spacing: 8) {
                                ForEach(0..<viewModel.networkInterfaces.count, id: \.self) { index in
                                    let iface = viewModel.networkInterfaces[index]
                                    NetworkCardView(
                                        name: iface.name,
                                        upload: iface.upload,
                                        download: iface.download,
                                        connected: iface.connected
                                    )
                                    .padding(.horizontal, 12)
                                }
                            }
                        }
                    }
                    
                    // Top CPU processes
                    ProcessListView(
                        title: "Top CPU Processes",
                        icon: "chart.bar.fill",
                        processes: viewModel.topCPUProcesses.map { ProcessItem(id: $0.id, name: $0.name, usage: $0.usage, icon: $0.icon) },
                        color: .blue,
                        unit: "%"
                    )
                    .padding(.horizontal, 12)
                    
                    // Top RAM processes
                    ProcessListView(
                        title: "Top Memory Processes",
                        icon: "chart.pie.fill",
                        processes: viewModel.topRAMProcesses.map { ProcessItem(id: $0.id, name: $0.name, usage: $0.usage, icon: $0.icon) },
                        color: .red,
                        unit: "GB"
                    )
                    .padding(.horizontal, 12)
                    
                    // Footer
                    FooterView(lastUpdate: viewModel.lastUpdateTime)
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
    let isLoading: Bool
    
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
                        .fill(isLoading ? Color.yellow : Color.green)
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .stroke((isLoading ? Color.yellow : Color.green).opacity(0.5), lineWidth: 2)
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

struct ErrorBannerView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(10)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
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
