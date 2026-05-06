import SwiftUI
import Charts

struct LineGraphView: View {
    var body: some View {
        ScrollView {
            // 基本的な折れ線グラフ
            Text("基本的な折れ線グラフ")
            let data: [Data] = [
                .init(category: "A", value: 100),
                .init(category: "B", value: 300),
                .init(category: "C", value: 200),
            ]
            Chart(data) {
                LineMark(
                    x: .value("Category", $0.category),
                    y: .value("value", $0.value)
                )
            }
            .frame(height: 200)
            
            // 複数種類の折れ線グラフ
            Text("複数種類の折れ線グラフ")
            let lineData: [LineData] = [
                .init(category: "A", value: 100, name: "hoge"),
                .init(category: "B", value: 200, name: "hoge"),
                .init(category: "C", value: 150, name: "hoge"),
                .init(category: "A", value: 50, name: "piyo"),
                .init(category: "B", value: 200, name: "piyo"),
                .init(category: "C", value: 300, name: "piyo"),
            ]
            Chart(lineData) {
                LineMark(
                    x: .value("Category", $0.category),
                    y: .value("Value", $0.value),
                    series: .value("name", $0.name)
                )
                .foregroundStyle(by: .value("name", $0.name))
            }
            .frame(height: 200)
            
            // 点のみ
            Text("点のみ")
            Chart(data) {
                PointMark(
                    x: .value("Category", $0.category),
                    y: .value("value", $0.value)
                )
            }
            
            // 点と線を組み合わせる
            // LineMarkに.symbol(.circle)で可能
            Text("点と線を組み合わせる")
            Chart(data) {
                PointMark(
                    x: .value("Category", $0.category),
                    y: .value("value", $0.value)
                )
                LineMark(
                    x: .value("Category", $0.category),
                    y: .value("value", $0.value)
                )
                
            }
            
            // 面グラフ
            Text("面グラフ")
            let foodData: [Food] = [
                .init(name: "Burger", price: 0.07, year: 1960),
                .init(name: "Cheese", price: 0.03, year: 1960),
                .init(name: "Bun", price: 0.05, year: 1960),
                .init(name: "Burger", price: 1.00, year: 1970),
                .init(name: "Cheese", price: 0.70, year: 1970),
                .init(name: "Bun", price: 0.60, year: 1970),
                .init(name: "Burger", price: 1.07, year: 1980),
                .init(name: "Cheese", price: 0.93, year: 1980),
                .init(name: "Bun", price: 0.95, year: 1980),
            ]
            
            Chart(foodData) {
                AreaMark(
                    x: .value("Date", $0.year),
                    y: .value("value", $0.price),
                )
            }
            .chartXScale(domain: 1960...1980)
            
            // 水平・垂直の罫線を使用してデータを表す
            Text("罫線を表示する")
            Chart(data) {
                BarMark(
                    x: .value("Category", $0.category),
                    y: .value("value", $0.value)
                )
                RuleMark(y: .value("average", 50))
                    .foregroundStyle(.red)
            }
        }
        
        
    }
}

#Preview {
    LineGraphView()
}

fileprivate struct Data: Identifiable {
    var id: String { category }
    let category: String
    let value: Int
}

fileprivate struct LineData: Identifiable {
    var id: String { category }
    let category: String
    let value: Int
    let name: String
}

fileprivate struct Food: Identifiable {
    var id: String { name }
    let name: String
    let price: Double
    let year: Int
}

