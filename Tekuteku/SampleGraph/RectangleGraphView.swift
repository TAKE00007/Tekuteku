import SwiftUI
import Charts

struct RectangleGraphView: View {
    var body: some View {
        // ヒートマップ
        Text("ヒートマップ")
        let data: [RectangleData] = [
            .init(category: "A", positive: "+", negative: "+", num: 125),
            .init(category: "A", positive: "+", negative: "-", num: 10),
            .init(category: "A", positive: "-", negative: "-", num: 80),
            .init(category: "A", positive: "-", negative: "+", num: 1),
        ]
        Chart(data) {
            RectangleMark(
                x: .value("Positive", $0.positive),
                y: .value("Negative", $0.negative)
            )
            .foregroundStyle(by: .value("Number", $0.num))
        }
        .aspectRatio(contentMode: .fit)
        .padding()
        
    }
}

#Preview {
    RectangleGraphView()
}

fileprivate struct Data: Identifiable {
    var id: String { category }
    let category: String
    let value: Int
}

fileprivate struct RectangleData: Identifiable {
    var id: String { category }
    let category: String
    let positive: String
    let negative: String
    let num: Int
}
