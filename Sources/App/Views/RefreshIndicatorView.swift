import SwiftUI

struct RefreshIndicatorView: View {
    @State private var isRotating = false
    let lastUpdated: Date
    
    var timeSinceUpdate: String {
        let seconds = Date().timeIntervalSince(lastUpdated)
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))m ago"
        } else {
            return "\(Int(seconds / 3600))h ago"
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.blue, lineWidth: 2)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
            }
            .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Updating")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(timeSinceUpdate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            isRotating = true
        }
    }
}

struct UpdateBadgeView: View {
    let count: Int
    
    var body: some View {
        Text("\(count)")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 16, height: 16)
            .background(Color.red)
            .clipShape(Circle())
    }
}

#Preview {
    VStack(spacing: 16) {
        RefreshIndicatorView(lastUpdated: Date().addingTimeInterval(-30))
        RefreshIndicatorView(lastUpdated: Date().addingTimeInterval(-300))
        RefreshIndicatorView(lastUpdated: Date().addingTimeInterval(-3600))
    }
    .padding()
}
