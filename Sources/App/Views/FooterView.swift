import SwiftUI

struct FooterView: View {
    let lastUpdate: Date
    let updateFrequency: String = "Every 1s"
    
    var body: some View {
        VStack(spacing: 8) {
            Divider()
                .opacity(0.3)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last Updated")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(lastUpdate.formatted(date: .omitted, time: .standard))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Update Rate")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(updateFrequency)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            
            HStack(spacing: 8) {
                Button(action: {}) {
                    Label("Settings", systemImage: "gear")
                        .font(.caption2)
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Label("Quit", systemImage: "xmark.circle")
                        .font(.caption2)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    FooterView(lastUpdate: Date())
}
