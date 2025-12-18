import SwiftUI

struct CircularGaugeView: View {
    let value: Double
    let total: Double
    let label: String
    let color: Color
    let size: CGFloat
    
    var percentage: Double {
        min(max(value / total * 100, 0), 100)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: percentage / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                color.opacity(0.8),
                                color.opacity(0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(
                            lineWidth: 8,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: percentage)
                
                VStack(spacing: 2) {
                    Text("\(String(format: "%.0f", percentage))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: size, height: size)
        }
    }
}

#Preview {
    HStack {
        CircularGaugeView(
            value: 45,
            total: 100,
            label: "CPU",
            color: .blue,
            size: 80
        )
        
        CircularGaugeView(
            value: 32,
            total: 100,
            label: "RAM",
            color: .red,
            size: 80
        )
    }
    .padding()
}
