import SwiftUI

struct NetworkCardView: View {
    let name: String
    let upload: Double
    let download: Double
    let connected: Bool
    
    var body: some View {
        GlassView(cornerRadius: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "network")
                            .font(.caption)
                        Text(name)
                            .font(.caption)
                    }
                    .foregroundColor(connected ? .green : .red)
                    
                    Spacer()
                    
                    Circle()
                        .fill(connected ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label("↓", systemImage: "arrow.down")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text(formatBytes(download))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack {
                        Label("↑", systemImage: "arrow.up")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(formatBytes(upload))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(10)
        }
    }
    
    private func formatBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .decimal
        return formatter.string(fromByteCount: Int64(bytes)) + "/s"
    }
}

#Preview {
    HStack {
        NetworkCardView(
            name: "Wi-Fi",
            upload: 1024 * 512,
            download: 1024 * 1024 * 5,
            connected: true
        )
        
        NetworkCardView(
            name: "Ethernet",
            upload: 0,
            download: 0,
            connected: false
        )
    }
    .padding()
}
