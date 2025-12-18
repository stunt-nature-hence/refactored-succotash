import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("System Monitor")
                .font(.headline)
            
            Divider()
            
            Text("Monitoring active")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}
