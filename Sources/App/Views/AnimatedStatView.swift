import SwiftUI

struct AnimatedStatView: View {
    @State private var isAnimating = false
    
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    HStack {
        AnimatedStatView(label: "CPU", value: "45%", icon: "cpu", color: .blue)
        AnimatedStatView(label: "RAM", value: "68%", icon: "memorychip", color: .red)
        AnimatedStatView(label: "Disk", value: "82%", icon: "internaldrive", color: .orange)
    }
    .padding()
}
