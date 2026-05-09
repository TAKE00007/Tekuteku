import SwiftUI
import Charts

struct DayGraphView: View {
    let isActive: Bool
    @State private var animatedActual: Double = 0
    let weekGoal: Double = 8000
    let weekStep: Double = 5000
    
    var graphData: [GraphData] {
        let safeGoal = max(weekGoal, 0)
        let safeActual = max(animatedActual, 0)
        let actual = min(safeActual, safeGoal)
        let remaining = max(safeGoal - actual, 0)
        
        return [
            .init(value: remaining, name: "remaining"),
            .init(value: actual, name: "actual"),
        ]
        .filter { $0.value.isFinite && $0.value > 0 }
    }

    var body: some View {
        if graphData.isEmpty {
            ContentUnavailableView("表示できるデータがありません", systemImage: "chart.pie")
                .padding(.horizontal, 28)
        } else {
            Chart(graphData) { item in
                SectorMark(
                    angle: .value("Value", item.value),
                    innerRadius: .ratio(0.8),
                    outerRadius: .inset(1.0)
                )
                .foregroundStyle(by: .value("Name", item.name))
            }
            .chartForegroundStyleScale(
                [
                    "actual": .blue,
                    "remaining": .gray
                ]
            )
            .scaleEffect(x: -1, y: 1)
            .chartLegend(.hidden)
            .animation(.easeInOut(duration: 1.0), value: animatedActual)
            .onAppear {
                guard isActive else { return }
                animateGraph()
            }
            .onChange(of: isActive) { _, active in
                guard active else {
                    animatedActual = 0
                    return
                }
                animateGraph()
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let plotFrame = chartProxy.plotFrame {
                        let frame = geometry[plotFrame]
                        VStack {
                            Text("\(Int(weekStep))歩")
                                .font(.largeTitle)
                            HStack {
                                Text("/ \(Int(weekGoal))歩")
                                Button {
                                    print("")
                                } label: {
                                    Image(systemName: "pencil")
                                        .bold()
                                }
                            }
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
            .padding(.horizontal, 28)
        }
    }
    
    private func animateGraph() {
        animatedActual = 0
        
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedActual = 5000
            }
        }
    }
}

#Preview {
    DayGraphView(isActive: true)
}
