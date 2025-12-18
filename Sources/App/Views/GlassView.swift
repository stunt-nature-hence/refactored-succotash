import SwiftUI

struct GlassView<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    
    @State private var isHovered = false
    
    init(cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            VisualEffectView(style: .hudWindow)
                .cornerRadius(cornerRadius)
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(isHovered ? 0.15 : 0.1),
                            Color.white.opacity(isHovered ? 0.08 : 0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(isHovered ? 0.6 : 0.4),
                            Color.white.opacity(isHovered ? 0.2 : 0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
            
            content
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let style: NSVisualEffectView.Material
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = style
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = style
    }
}

#Preview {
    GlassView {
        VStack(spacing: 12) {
            Text("Glass Card")
                .font(.headline)
            Text("With frosted effect")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
