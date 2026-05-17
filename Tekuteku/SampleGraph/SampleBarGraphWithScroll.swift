import SwiftUI
import Charts


struct SampleBarGraphWithScroll: View {
    let records: [DailyRecord]
    
    var body: some View {
        Chart(records) { record in
            BarMark(
                x: .value("日付", record.date, unit: .day),
                y: .value("値", record.value)
            )
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(shortWeekday(for: date))
                    }
                }
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: 7 * 24 * 60 * 60)
        .chartScrollTargetBehavior(.valueAligned(matching: DateComponents(hour: 0)))
        .chartScrollPosition(initialX: records.last?.date ?? Date())
        .frame(height: 240)
        .padding()
    }
    
    func shortWeekday(for date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 2: return "月"
        case 3: return "火"
        case 4: return "水"
        case 5: return "木"
        case 6: return "金"
        case 7: return "土"
        case 1: return "日"
        default: return ""
        }
    }
}

#Preview {
    SampleBarGraphWithScroll(records: MockWeeklyHistoryData.twelveWeeks)
}

