import SwiftUI

struct BlurView: NSViewRepresentable {
    var radius: CGFloat = 10
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        
        let blur = CAFilter()
        blur.name = CAFilter.Name("CIGaussianBlur")
        blur.setDefaults()
        blur.setValue(radius, forKey: "inputRadius")
        
        view.layer?.filters = [blur]
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.layer?.filters = []
        
        let blur = CAFilter()
        blur.name = CAFilter.Name("CIGaussianBlur")
        blur.setDefaults()
        blur.setValue(radius, forKey: "inputRadius")
        
        nsView.layer?.filters = [blur]
    }
}

struct ModernBlurView<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            VisualEffectView(style: .hudWindow)
                .cornerRadius(cornerRadius)
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            content
        }
    }
}

#Preview {
    ModernBlurView {
        VStack(spacing: 12) {
            Text("Blurred Content")
                .font(.headline)
            Text("With glassmorphism effect")
                .font(.caption)
        }
        .padding()
    }
}
