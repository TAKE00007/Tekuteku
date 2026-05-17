import SwiftUI
import Charts

struct SampleAnimationView: View {
    @State private var graphValue: Double = 0
    fileprivate var graphData: [SampleGraphData] {
        let main = max(graphValue, 0)
        let other = 100 - main
        return [
            .init(name: "other", value: other),
            .init(name: "main", value: main)
        ]
    }
    
    var body: some View {
        TabView {
            SampleGraphView(graphValue: $graphValue, graphData: graphData)
        }
    }
}


private struct SampleGraphView: View {
    @Binding var graphValue: Double
    let graphData: [SampleGraphData]
    
    var body: some View {
        Chart(graphData) { item in
            SectorMark(
                angle: .value("Value", item.value),
                innerRadius: .ratio(0.8),
                outerRadius: .inset(1.0),
            )
            .foregroundStyle(by: .value("Name", item.name))
        }
        .chartForegroundStyleScale(
            [
                "main": .blue,
                "other": .gray
            ]
        )
        .scaleEffect(x: -1, y: 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                graphValue = 70
            }
        }
    }
}

private struct SampleGraphData: Identifiable {
    var id: String { name }
    let name: String
    let value: Double
}

#Preview {
    SampleAnimationView()
}
