import SwiftUI

struct ProcessItem: Identifiable {
    let id: Int
    let name: String
    let usage: Double
    let icon: String
}

struct ProcessListView: View {
    let title: String
    let icon: String
    let processes: [ProcessItem]
    let color: Color
    let unit: String
    
    var body: some View {
        GlassView {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Divider()
                    .opacity(0.5)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(processes.prefix(4)) { process in
                        ProcessRowView(
                            name: process.name,
                            usage: process.usage,
                            unit: unit,
                            color: color,
                            icon: process.icon
                        )
                    }
                }
            }
            .padding(12)
        }
    }
}

struct ProcessRowView: View {
    let name: String
    let usage: Double
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        color.opacity(0.7),
                                        color.opacity(0.5)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(usage / 100))
                    }
                }
                .frame(height: 4)
            }
            
            Text("\(String(format: "%.1f", usage))\(unit)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .frame(width: 45, alignment: .trailing)
        }
    }
}

#Preview {
    ProcessListView(
        title: "Top Processes",
        icon: "app.fill",
        processes: [
            ProcessItem(id: 1, name: "Chrome", usage: 45.5, icon: "app.fill"),
            ProcessItem(id: 2, name: "Safari", usage: 32.1, icon: "app.fill"),
            ProcessItem(id: 3, name: "Xcode", usage: 28.7, icon: "app.fill"),
            ProcessItem(id: 4, name: "Mail", usage: 12.3, icon: "app.fill")
        ],
        color: .blue,
        unit: "%"
    )
    .padding()
}
