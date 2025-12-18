import SwiftUI

struct InfoCardView: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        GlassView(cornerRadius: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(10)
        }
    }
}

struct DividerView: View {
    var opacity: Double = 0.3
    
    var body: some View {
        Divider()
            .opacity(opacity)
    }
}

#Preview {
    VStack(spacing: 8) {
        InfoCardView(
            title: "CPU Usage",
            description: "Processor load and thread information",
            icon: "cpu",
            color: .blue
        )
        
        InfoCardView(
            title: "Memory Usage",
            description: "RAM consumption and page cache",
            icon: "memorychip",
            color: .red
        )
    }
    .padding()
}
