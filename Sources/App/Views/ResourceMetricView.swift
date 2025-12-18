import SwiftUI

struct ResourceMetricView: View {
    let title: String
    let systemIcon: String
    let value: Double
    let subtitle: String
    let color: Color
    let details: [(label: String, value: String)]
    
    var body: some View {
        GlassView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(title, systemImage: systemIcon)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", value))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                    .opacity(0.5)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(details, id: \.label) { detail in
                        HStack {
                            Text(detail.label)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(detail.value)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .padding(12)
        }
    }
}

#Preview {
    ResourceMetricView(
        title: "CPU",
        systemIcon: "cpu",
        value: 45.5,
        subtitle: "System load is normal",
        color: .blue,
        details: [
            ("System", "12.3%"),
            ("User", "33.2%"),
            ("Idle", "54.5%")
        ]
    )
    .padding()
}
