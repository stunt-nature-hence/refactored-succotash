import SwiftUI

struct DetailedStatsView: View {
    let stats: [StatItem]
    
    struct StatItem: Identifiable {
        let id: String
        let label: String
        let value: String
        let icon: String
        let color: Color
    }
    
    var body: some View {
        GlassView {
            VStack(alignment: .leading, spacing: 12) {
                Text("System Details")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Divider()
                    .opacity(0.5)
                
                VStack(spacing: 8) {
                    ForEach(stats) { stat in
                        HStack(spacing: 10) {
                            Image(systemName: stat.icon)
                                .font(.caption)
                                .foregroundColor(stat.color)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stat.label)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(stat.value)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                        }
                        
                        if stat.id != stats.last?.id {
                            Divider()
                                .opacity(0.3)
                        }
                    }
                }
            }
            .padding(12)
        }
    }
}

#Preview {
    DetailedStatsView(
        stats: [
            .init(
                id: "uptime",
                label: "System Uptime",
                value: "42 days, 5 hours",
                icon: "hourglass",
                color: .blue
            ),
            .init(
                id: "temp",
                label: "CPU Temperature",
                value: "58°C",
                icon: "thermometer",
                color: .orange
            ),
            .init(
                id: "processes",
                label: "Running Processes",
                value: "248",
                icon: "square.stack.3d.up",
                color: .purple
            ),
            .init(
                id: "threads",
                label: "Active Threads",
                value: "1,024",
                icon: "square.split.2x1",
                color: .green
            )
        ]
    )
    .padding()
}
