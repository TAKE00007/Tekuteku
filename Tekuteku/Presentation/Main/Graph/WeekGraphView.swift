import SwiftUI
import Charts


struct WeekGraphView: View {
    let sampleData: [DailyRecord] = MockWeeklyHistoryData.twelveWeeks
    private let visibleDays = 7
    private let step: Double = 5000
    
    @State private var targetY: Double = 5000
    @State private var averageSteps: Double = 0
    @State private var scrollPosition: Date = {
        let calendar = Calendar.current
        let lastDate = MockWeeklyHistoryData.twelveWeeks.last?.date ?? Date()
        return calendar.date(byAdding: .day, value: -6, to: lastDate) ?? lastDate
    }()
    
    private var visibleData: [DailyRecord] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: scrollPosition)
        let end = calendar.date(byAdding: .day, value: visibleDays, to: start) ?? start
        
        return sampleData.filter { data in
            data.date >= start && data.date < end
        }
    }
    
    private var visibleDataAverage: Double {
        return visibleData.averageValue
    }
    
    private var maxY: Double {
        let rawMax = visibleData.map(\.value).max() ?? step
        return max(step, (rawMax / step).rounded(.up) * step)
    }
    
    private var visibleDate: (startDate: String, endDate: String) {
        let calendar = Calendar.current
        let locale = Locale(identifier: "ja_JP")
        
        let start = calendar.startOfDay(for: scrollPosition)
        let startComponents = calendar.dateComponents([.year, .month], from: start)
        let end = calendar.date(byAdding: .day, value: visibleDays, to: start) ?? start
        let endConponents = calendar.dateComponents([.year, .month], from: end)
        
        let isSameYear = startComponents.year == endConponents.year
        let isSameMonth = startComponents.month == endConponents.month
        
        let startDate = start.formatted(.dateTime
            .year()
            .month()
            .day()
            .locale(locale)
        )
        
        let endStyle: Date.FormatStyle = {
            if isSameYear && isSameMonth {
                return .dateTime.day().locale(locale)
            } else if isSameYear {
                return .dateTime.month().day().locale(locale)
            } else {
                return .dateTime.year().month().day().locale(locale)
            }
        }()
        
        let endDate = end.formatted(endStyle)
        
        return (startDate, endDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading) {
                Text("平均")
                    .font(.caption)
                    .foregroundStyle(.gray)
                HStack {
                    Text("\(Int(averageSteps))")
                        .font(.largeTitle)
                    Text("歩")
                        .bold()
                        .foregroundStyle(.gray)
                }
                Text("\(visibleDate.startDate)~\(visibleDate.endDate)")
                    .foregroundStyle(.gray)
            }
            .padding(.top, 4)
            .padding(.horizontal, 16)
            
            Chart(sampleData) { data in
                BarMark(
                    x: .value("Day", data.date, unit: .day),
                    y: .value("Step", data.value)
                )
            }
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 7*24*60*60)
            .chartXScale(range: .plotDimension(startPadding: 8, endPadding: 8))
            .chartScrollTargetBehavior(.valueAligned(matching: DateComponents(hour: 0)))
            .chartScrollPosition(x: $scrollPosition)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        let day = shortWeekday(for: date)
                        if day != "月" {
                            AxisGridLine()
                            AxisValueLabel {
                                Text(day)
                            }
                            AxisTick()
                        } else {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                            AxisValueLabel { Text(day) }
                            AxisTick(stroke: StrokeStyle(lineWidth: 1))
                        }
                    }
                }
            }
            .chartYScale(domain: 0...targetY)
            .chartYAxis {
                AxisMarks(values: Array(stride(from: 0, through: maxY, by: step)))  { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .onAppear {
                scrollPosition = sampleData.last?.date ?? Date()
                targetY = maxY
                averageSteps = visibleDataAverage
            }
            .onChange(of: visibleData) { _, newValue in
                averageSteps = visibleDataAverage
                targetY = maxY
            }
            .padding()
        }
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

struct DailyRecord: Identifiable, Equatable {
    let date: Date
    let value: Double
    var id: Date { date }
}

extension Array where Element == DailyRecord {
    var averageValue: Double {
        guard !isEmpty else { return 0 }
        return map(\.value).reduce(0, +) / Double(count)
    }
}

enum MockWeeklyHistoryData {
    static let twelveWeeks: [DailyRecord] = [
        record("2026-02-16", 22000),
        record("2026-02-17", 2800),
        record("2026-02-18", 26000),
        record("2026-02-19", 3100),
        record("2026-02-20", 3400),
        record("2026-02-21", 4000),
        record("2026-02-22", 3700),

        record("2026-02-23", 2400),
        record("2026-02-24", 3000),
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

        record("2026-04-27", 3400),
        record("2026-04-28", 4100),
        record("2026-04-29", 3900),
        record("2026-04-30", 4500),
        record("2026-05-01", 4900),
        record("2026-05-02", 5500),
        record("2026-05-03", 5200),

        record("2026-05-04", 10000),
        record("2026-05-05", 4200),
        record("2026-05-06", 4000),
        record("2026-05-07", 4600),
        record("2026-05-08", 5000),
        record("2026-05-09", 5700),
        record("2026-05-10", 5400)
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

#Preview {
    WeekGraphView()
}
