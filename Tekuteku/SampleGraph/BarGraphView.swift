import SwiftUI
import Charts

struct BarGraphView: View {
    var body: some View {
        ScrollView {
            // 基本的な使い方
            Text("基本的な使い方")
            Chart {
                BarMark(x: .value("Category", "A"), y: .value("value", 100), stacking: .unstacked)
                BarMark(x: .value("Category", "B"), y: .value("value", 200), stacking: .unstacked)
            }
            .frame(height: 200)
            .padding()
            
            // ForEachの使用
            Text("ForEachの使用")
            let data: [Data] = [
                .init(category: "A", value: 100),
                .init(category: "B", value: 200)
            ]
            
            Chart {
                ForEach(data) {
                    BarMark(
                        x: .value("Category", $0.category),
                        y: .value("value", $0.value)
                    )
                }
            }
            .frame(height: 200)
            
            // グラフの向きを変える
            Text("グラフの向きを変える")
            Chart {
                ForEach(data) {
                    BarMark(
                        x: .value("Value", $0.value),
                        y: .value("Category", $0.category)
                    )
                }
            }
            .frame(height: 200)
            
            // iPhoneのストレージの設定など
            Text("iPhoneストレージ設定風")
            let storageData: [Data] = [
                .init(category: "Applications", value: 50),
                .init(category: "Photos", value: 10),
                .init(category: "Music", value: 5),
                .init(category: "Podcasts", value: 3),
                .init(category: "iOS", value: 10),
                .init(category: "System Data", value: 10)
            ]
            Chart(storageData, id: \.id) {
                BarMark(
                    x: .value("File Size Percent", $0.value)
                )
                .foregroundStyle(by: .value("File Category", $0.category))
            }
            .chartXAxis(.hidden)
            .frame(height: 50)
            
            // グループ化された棒グラフ
            let groupData: [GroupData] = [
                .init(category: "A", value: 100, name: "hoge"),
                .init(category: "A", value: 200, name: "piyo"),
                .init(category: "B", value: 250, name: "hoge"),
                .init(category: "B", value: 300, name: "piyo"),
            ]
            Chart {
                ForEach(groupData) {
                    BarMark(
                        x: .value("Category", $0.category),
                        y: .value("Value", $0.value)
                    )
                    .foregroundStyle(by: .value("name", $0.name))
                    .position(by: .value("name", $0.name))
                }
            }
            
        }
        
    }
}

#Preview {
    BarGraphView()
}

fileprivate struct Data: Identifiable {
    var id: String { category }
    let category: String
    let value: Int
}

fileprivate struct GroupData: Identifiable {
    var id: String { category }
    let category: String
    let value: Int
    let name: String
}
