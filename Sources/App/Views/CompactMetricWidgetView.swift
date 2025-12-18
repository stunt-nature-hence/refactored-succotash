import SwiftUI

struct CompactMetricWidgetView: View {
    let label: String
    let value: Double
    let icon: String
    let color: Color
    let compact: Bool
    
    var body: some View {
        if compact {
            CompactStyle()
        } else {
            ExpandedStyle()
        }
    }
    
    @ViewBuilder
    func CompactStyle() -> some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(String(format: "%.0f", value))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.6))
                        .frame(width: geometry.size.width * (value / 100))
                }
            }
            .frame(height: 3)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    func ExpandedStyle() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(String(format: "%.1f", value))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.8),
                                    color.opacity(0.5)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (value / 100))
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 12) {
            CompactMetricWidgetView(label: "CPU", value: 45, icon: "cpu", color: .blue, compact: true)
            CompactMetricWidgetView(label: "RAM", value: 68, icon: "memorychip", color: .red, compact: true)
        }
        
        CompactMetricWidgetView(label: "Disk Usage", value: 82, icon: "internaldrive", color: .orange, compact: false)
    }
    .padding()
}
