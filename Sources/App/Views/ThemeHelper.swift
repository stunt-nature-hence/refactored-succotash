import SwiftUI

struct AppTheme {
    static let primaryBackground = Color(nsColor: NSColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1))
    static let secondaryBackground = Color(nsColor: NSColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1))
    static let glassOpacity: Double = 0.15
    static let glassStrokeOpacity: Double = 0.4
    
    static let colors = ThemeColors()
    
    struct ThemeColors {
        let cpu = Color.blue
        let memory = Color.red
        let network = Color.green
        let storage = Color.orange
        let system = Color.purple
    }
}

struct ThemeModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.dark)
    }
}

extension View {
    func applyAppTheme() -> some View {
        modifier(ThemeModifier())
    }
}

struct GradientHelper {
    static func glassmorphGradient(
        startColor: Color = .white,
        endColor: Color = .white,
        startOpacity: Double = 0.15,
        endOpacity: Double = 0.05
    ) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                startColor.opacity(startOpacity),
                endColor.opacity(endOpacity)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func accentGradient(color: Color) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                color.opacity(0.8),
                color.opacity(0.5)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct CornerRadiusPresets {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 20
    static let extraLarge: CGFloat = 24
}

struct SpacingPresets {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}
