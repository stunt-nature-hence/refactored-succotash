import SwiftUI

struct QuickStatsView: View {
    let cpuUsage: Double
    let ramUsage: Double
    let networkDownload: Double
    let networkUpload: Double
    
    var body: some View {
        HStack(spacing: 10) {
            QuickStatItem(
                icon: "cpu",
                label: "CPU",
                value: String(format: "%.0f", cpuUsage),
                unit: "%",
                color: .blue
            )
            
            QuickStatItem(
                icon: "memorychip",
                label: "RAM",
                value: String(format: "%.0f", ramUsage),
                unit: "%",
                color: .red
            )
            
            QuickStatItem(
                icon: "arrow.down.circle.fill",
                label: "Down",
                value: formatSpeed(networkDownload),
                unit: "",
                color: .green
            )
            
            QuickStatItem(
                icon: "arrow.up.circle.fill",
                label: "Up",
                value: formatSpeed(networkUpload),
                unit: "",
                color: .orange
            )
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return "\(String(format: "%.0f", bytesPerSecond)) B"
        } else if bytesPerSecond < 1024 * 1024 {
            return "\(String(format: "%.1f", bytesPerSecond / 1024)) KB"
        } else {
            return "\(String(format: "%.1f", bytesPerSecond / (1024 * 1024))) MB"
        }
    }
}

struct QuickStatItem: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 3) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    QuickStatsView(
        cpuUsage: 45,
        ramUsage: 68,
        networkDownload: 1024 * 512,
        networkUpload: 1024 * 256
    )
    .padding()
}
