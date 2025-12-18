import SwiftUI

extension AnyTransition {
    static var glassSlide: AnyTransition {
        let insertion = AnyTransition.move(edge: .bottom).combined(with: .opacity)
        let removal = AnyTransition.move(edge: .bottom).combined(with: .opacity)
        return .asymmetric(insertion: insertion, removal: removal)
    }
    
    static var glassScale: AnyTransition {
        let insertion = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        let removal = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        return .asymmetric(insertion: insertion, removal: removal)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension Button {
    func glassButton() -> some View {
        self.buttonStyle(ScaleButtonStyle())
    }
}

struct PulseModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .opacity(isAnimating ? 1.0 : 0.95)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func pulse() -> some View {
        modifier(PulseModifier())
    }
}
