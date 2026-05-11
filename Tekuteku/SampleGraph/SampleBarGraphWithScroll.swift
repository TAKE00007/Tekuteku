import SwiftUI
import Charts

struct DailyRecord: Identifiable {
    let date: Date
    let value: Double
    var id: Date { date }
}

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

enum MockWeeklyHistoryData {
    static let twelveWeeks: [DailyRecord] = [
        record("2026-02-16", 22),
        record("2026-02-17", 28),
        record("2026-02-18", 26),
        record("2026-02-19", 31),
        record("2026-02-20", 34),
        record("2026-02-21", 40),
        record("2026-02-22", 37),

        record("2026-02-23", 24),
        record("2026-02-24", 30),
        record("2026-02-25", 27),
        record("2026-02-26", 33),
        record("2026-02-27", 36),
        record("2026-02-28", 42),
        record("2026-03-01", 39),

        record("2026-03-02", 25),
        record("2026-03-03", 31),
        record("2026-03-04", 29),
        record("2026-03-05", 35),
        record("2026-03-06", 38),
        record("2026-03-07", 44),
        record("2026-03-08", 41),

        record("2026-03-09", 27),
        record("2026-03-10", 32),
        record("2026-03-11", 30),
        record("2026-03-12", 36),
        record("2026-03-13", 39),
        record("2026-03-14", 46),
        record("2026-03-15", 42),

        record("2026-03-16", 29),
        record("2026-03-17", 35),
        record("2026-03-18", 33),
        record("2026-03-19", 38),
        record("2026-03-20", 41),
        record("2026-03-21", 47),
        record("2026-03-22", 45),

        record("2026-03-23", 28),
        record("2026-03-24", 34),
        record("2026-03-25", 32),
        record("2026-03-26", 37),
        record("2026-03-27", 40),
        record("2026-03-28", 48),
        record("2026-03-29", 44),

        record("2026-03-30", 31),
        record("2026-03-31", 36),
        record("2026-04-01", 34),
        record("2026-04-02", 39),
        record("2026-04-03", 42),
        record("2026-04-04", 49),
        record("2026-04-05", 46),

        record("2026-04-06", 30),
        record("2026-04-07", 37),
        record("2026-04-08", 35),
        record("2026-04-09", 40),
        record("2026-04-10", 43),
        record("2026-04-11", 50),
        record("2026-04-12", 47),

        record("2026-04-13", 33),
        record("2026-04-14", 39),
        record("2026-04-15", 36),
        record("2026-04-16", 42),
        record("2026-04-17", 45),
        record("2026-04-18", 52),
        record("2026-04-19", 48),

        record("2026-04-20", 35),
        record("2026-04-21", 40),
        record("2026-04-22", 38),
        record("2026-04-23", 44),
        record("2026-04-24", 47),
        record("2026-04-25", 53),
        record("2026-04-26", 50),

        record("2026-04-27", 34),
        record("2026-04-28", 41),
        record("2026-04-29", 39),
        record("2026-04-30", 45),
        record("2026-05-01", 49),
        record("2026-05-02", 55),
        record("2026-05-03", 52),

        record("2026-05-04", 36),
        record("2026-05-05", 42),
        record("2026-05-06", 40),
        record("2026-05-07", 46),
        record("2026-05-08", 50),
        record("2026-05-09", 57),
        record("2026-05-10", 54)
    ]

    private static func record(_ dateString: String, _ value: Double) -> DailyRecord {
        DailyRecord(date: formatter.date(from: dateString) ?? Date(), value: value)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter
    }()
}
