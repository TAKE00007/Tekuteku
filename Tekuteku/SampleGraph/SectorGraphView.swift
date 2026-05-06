import SwiftUI
import Charts

struct SectorGraphView: View {
    var body: some View {
        ScrollView {
            // 基本的な円グラフ
            Text("基本的な円グラフ")
            let data: [Data] = [
                .init(name: "USA", value: 50),
                .init(name: "France", value: 20),
                .init(name: "Japan", value: 30),
            ]
            Chart(data) {
                SectorMark(angle: .value("Value", $0.value))
                    .foregroundStyle(by: .value("Country", $0.name))
            }
            .padding()
            
            // 基本的なドーナツグラフ
            Text("基本的なドーナツグラフ")
            Chart(data) {
                SectorMark(
                    angle: .value("Value", $0.value),
                    innerRadius: .ratio(0.6),
                    outerRadius: .inset(3.0),
                    angularInset: 1
                )
                .foregroundStyle(by: .value("Country", $0.name))
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let plotFrame = chartProxy.plotFrame {
                        let frame = geometry[plotFrame]
                        VStack {
                            Text("Smaple")
                                .font(.callout)
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }   
                }
            }
        }
    }
}

#Preview {
    SectorGraphView()
}

fileprivate struct Data: Identifiable {
    var id: String { name }
    let name: String
    let value: Int
}
