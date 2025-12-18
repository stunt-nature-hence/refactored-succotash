import SwiftUI

struct CollapsibleSectionView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    @State private var isExpanded = true
    
    init(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Label(title, systemImage: icon)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Divider()
                    .opacity(0.5)
                
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    CollapsibleSectionView(
        title: "Advanced Options",
        icon: "slider.horizontal.3"
    ) {
        VStack(alignment: .leading, spacing: 8) {
            Label("Option 1", systemImage: "checkmark.circle.fill")
                .font(.caption)
            Label("Option 2", systemImage: "checkmark.circle.fill")
                .font(.caption)
            Label("Option 3", systemImage: "xmark.circle.fill")
                .font(.caption)
        }
        .padding(12)
    }
    .padding()
}
