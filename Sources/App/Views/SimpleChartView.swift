import SwiftUI

struct SimpleChartView: View {
    let title: String
    let data: [CGFloat]
    let color: Color
    let lineWidth: CGFloat = 2
    
    var body: some View {
        GlassView {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ZStack {
                    Canvas { context in
                        drawGrid(context: context)
                        drawChart(context: context)
                    }
                    .frame(height: 80)
                }
            }
            .padding(12)
        }
    }
    
    private func drawGrid(context: inout GraphicsContext) {
        let path = Path { p in
            for i in stride(from: 0, to: 100, by: 25) {
                let y = CGFloat(i) / 100
                p.move(to: CGPoint(x: 0, y: y * 80))
                p.addLine(to: CGPoint(x: 300, y: y * 80))
            }
        }
        context.stroke(path, with: .color(.white.opacity(0.05)), lineWidth: 1)
    }
    
    private func drawChart(context: inout GraphicsContext) {
        guard !data.isEmpty else { return }
        
        let width: CGFloat = 300
        let height: CGFloat = 80
        let step = width / CGFloat(data.count - 1)
        
        var path = Path()
        path.move(to: CGPoint(x: 0, y: height * (1 - data[0] / 100)))
        
        for (index, value) in data.enumerated() {
            let x = CGFloat(index) * step
            let y = height * (1 - min(value, 100) / 100)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        context.stroke(path, with: .color(color), lineWidth: lineWidth)
    }
}

#Preview {
    SimpleChartView(
        title: "CPU Usage History",
        data: [10, 20, 30, 45, 50, 55, 60, 50, 40, 30],
        color: .blue
    )
    .padding()
}
