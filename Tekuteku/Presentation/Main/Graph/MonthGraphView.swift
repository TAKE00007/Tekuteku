import SwiftUI
import Charts

struct MonthGraphView: View {
    let sampleData: [DailyRecord] = MockWeeklyHistoryData.twelveWeeks
    
    @State private var selectedDate: Date? = nil
    @State private var scrollPosition: Date = {
        let calendar = Calendar.current
        let lastDate = MockWeeklyHistoryData.twelveWeeks.last?.date ?? Date()
        return calendar.date(byAdding: .day, value: -6, to: lastDate) ?? lastDate
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            
            VStack(alignment: .leading) {

                if selectedDate != nil {
                    Text("平均")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    HStack {
                        Text("3000")
                            .font(.largeTitle)
                        Text("歩")
                            .bold()
                            .foregroundStyle(.gray)
                    }
                    Text("2026年5月15日〜6月14日")
                        .foregroundStyle(.gray)
                } else {
                    EmptyView()
                }
            }
            .frame(height: 80)
            .padding(.top, 4)
            .padding(.horizontal, 16)
            
            chartContent
                .frame(height: 400)
                .padding()
            
            Spacer()
            
        }
    }
    
    private var chartContent: some View {
        Chart(sampleData) { data in
            BarMark(
                x: .value("Day", data.date, unit: .day),
                y: .value("Step", data.value)
            )
        }
        .chartScrollPosition(x: $scrollPosition)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: 30 * 24 * 60 * 60)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.gray.opacity(0.8))
            }
            
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                if let date = value.as(Date.self) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.day().locale(Locale(identifier: "ja_JP")))
                }
            }
        }
    }
}

#Preview {
    MonthGraphView()
}
