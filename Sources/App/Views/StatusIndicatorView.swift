import SwiftUI

struct StatusIndicatorView: View {
    let status: SystemStatus
    let message: String
    
    enum SystemStatus {
        case optimal
        case warning
        case critical
        
        var color: Color {
            switch self {
            case .optimal:
                return .green
            case .warning:
                return .orange
            case .critical:
                return .red
            }
        }
        
        var icon: String {
            switch self {
            case .optimal:
                return "checkmark.circle.fill"
            case .warning:
                return "exclamationmark.circle.fill"
            case .critical:
                return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Text(statusText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var statusText: String {
        switch status {
        case .optimal:
            return "System performing optimally"
        case .warning:
            return "Monitor system resources"
        case .critical:
            return "Immediate attention needed"
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        StatusIndicatorView(status: .optimal, message: "All systems operational")
        StatusIndicatorView(status: .warning, message: "Memory usage elevated")
        StatusIndicatorView(status: .critical, message: "CPU temperature critical")
    }
    .padding()
}
