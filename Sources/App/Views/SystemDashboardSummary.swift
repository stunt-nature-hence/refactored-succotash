import SwiftUI

struct SystemDashboardSummary: View {
    let cpuUsage: Double
    let ramUsage: Double
    let networkActive: Bool
    
    var healthStatus: HealthStatus {
        let avgUsage = (cpuUsage + ramUsage) / 2
        if avgUsage > 80 {
            return .critical
        } else if avgUsage > 60 {
            return .warning
        } else {
            return .healthy
        }
    }
    
    enum HealthStatus {
        case healthy
        case warning
        case critical
        
        var color: Color {
            switch self {
            case .healthy:
                return .green
            case .warning:
                return .orange
            case .critical:
                return .red
            }
        }
        
        var label: String {
            switch self {
            case .healthy:
                return "System Healthy"
            case .warning:
                return "System Warning"
            case .critical:
                return "System Critical"
            }
        }
        
        var icon: String {
            switch self {
            case .healthy:
                return "checkmark.seal.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            case .critical:
                return "xmark.octagon.fill"
            }
        }
    }
    
    var body: some View {
        GlassView {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: healthStatus.icon)
                        .font(.title3)
                        .foregroundColor(healthStatus.color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(healthStatus.label)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Performance Overview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Divider()
                    .opacity(0.5)
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CPU")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.0f", cpuUsage))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.colors.cpu)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Memory")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.0f", ramUsage))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.colors.memory)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Network")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Image(systemName: networkActive ? "network" : "xmark.circle")
                            .font(.title3)
                            .foregroundColor(networkActive ? AppTheme.colors.network : .secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding(12)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SystemDashboardSummary(cpuUsage: 25, ramUsage: 35, networkActive: true)
        SystemDashboardSummary(cpuUsage: 65, ramUsage: 72, networkActive: true)
        SystemDashboardSummary(cpuUsage: 85, ramUsage: 92, networkActive: false)
    }
    .padding()
}
