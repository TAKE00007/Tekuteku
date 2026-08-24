import SwiftUI
import Charts

struct SelectableBarGraphView: View {
    private let records: [DailyRecord]
    private let visibleDays = 7
    private let yAxisStep: Double = 5_000

    @State private var scrollPosition: Date
    @State private var selectedRecord: DailyRecord?
    @State private var chartFrame: CGRect = .zero

    init(records: [DailyRecord] = MockWeeklyHistoryData.twelveWeeks) {
        self.records = records

        let calendar = Calendar.current
        let lastDate = records.last?.date ?? Date()
        let initialStart = calendar.date(byAdding: .day, value: -6, to: lastDate) ?? lastDate
        _scrollPosition = State(initialValue: initialStart)
    }

    private var visibleData: [DailyRecord] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: scrollPosition)
        let end = calendar.date(byAdding: .day, value: visibleDays, to: start) ?? start

        return records.filter { record in
            record.date >= start && record.date < end
        }
    }

    private var averageSteps: Double {
        visibleData.averageValue
    }

    private var visibleDateText: String {
        let calendar = Calendar.current
        let locale = Locale(identifier: "ja_JP")
        let start = calendar.startOfDay(for: scrollPosition)
        let end = calendar.date(byAdding: .day, value: visibleDays - 1, to: start) ?? start

        return "\(start.formatted(.dateTime.year().month().day().locale(locale)))〜\(end.formatted(endDateStyle(start: start, end: end, locale: locale)))"
    }

    private var maxY: Double {
        let rawMax = visibleData.map(\.value).max() ?? yAxisStep
        return max(yAxisStep, (rawMax / yAxisStep).rounded(.up) * yAxisStep)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            summaryView

            Chart(records) { record in
                BarMark(
                    x: .value("日付", record.date, unit: .day),
                    y: .value("歩数", record.value)
                )
                .foregroundStyle(isSelected(record) ? Color.orange : Color.blue)
                .cornerRadius(6)
            }
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: TimeInterval(visibleDays * 24 * 60 * 60))
            .chartScrollTargetBehavior(.valueAligned(matching: DateComponents(hour: 0)))
            .chartScrollPosition(x: $scrollPosition)
            .chartXScale(range: .plotDimension(startPadding: 12, endPadding: 12))
            .chartYScale(domain: 0...maxY)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(shortWeekday(for: date))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: Array(stride(from: 0, through: maxY, by: yAxisStep))) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartBackground { _ in
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ChartFramePreferenceKey.self,
                            value: geometry.frame(in: .named("SelectableBarGraphView"))
                        )
                }
            }
            .chartOverlay { chartProxy in
                GeometryReader { geometry in
                    if let plotFrame = chartProxy.plotFrame {
                        let frame = geometry[plotFrame]

                        ZStack(alignment: .topLeading) {
                            if let selectedRecord,
                               let x = centerX(for: selectedRecord.date, chartProxy: chartProxy),
                               let y = chartProxy.position(forY: selectedRecord.value) {
                                calloutView(for: selectedRecord)
                                    .position(
                                        x: frame.minX + x,
                                        y: max(frame.minY + y - 44, 32)
                                    )
                            }
                        }
                    }
                }
            }
            .chartGesture { chartProxy in
                SpatialTapGesture()
                    .onEnded { value in
                        selectedRecord = selectedRecord(
                            at: value.location,
                            chartProxy: chartProxy
                        )
                    }
            }
            .frame(height: 320)
        }
        .padding()
        .coordinateSpace(name: "SelectableBarGraphView")
        .contentShape(Rectangle())
        .simultaneousGesture(
            SpatialTapGesture()
                .onEnded { value in
                    guard !chartFrame.contains(value.location) else { return }
                    selectedRecord = nil
                }
        )
        .onPreferenceChange(ChartFramePreferenceKey.self) { frame in
            chartFrame = frame
        }
    }

    private var summaryView: some View {
        Group {
            if let selectedRecord {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedRecord.date.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ja_JP"))))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(Int(selectedRecord.value))")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("歩")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("平均")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(Int(averageSteps))")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("歩")
                            .foregroundStyle(.secondary)
                    }

                    Text(visibleDateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func calloutView(for record: DailyRecord) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(record.date.formatted(.dateTime.month().day().weekday(.abbreviated).locale(Locale(identifier: "ja_JP"))))
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(Int(record.value))")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("歩")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func selectedRecord(
        at location: CGPoint,
        chartProxy: ChartProxy
    ) -> DailyRecord? {
        guard let date: Date = chartProxy.value(atX: location.x) else {
            return selectedRecord
        }

        let calendar = Calendar.current
        let tappedDay = calendar.startOfDay(for: date)

        return visibleData.min(by: { lhs, rhs in
            abs(lhs.date.timeIntervalSince(tappedDay)) < abs(rhs.date.timeIntervalSince(tappedDay))
        })
    }

    private func isSelected(_ record: DailyRecord) -> Bool {
        selectedRecord?.id == record.id
    }

    private func centerX(for date: Date, chartProxy: ChartProxy) -> CGFloat? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        guard
            let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay),
            let startX = chartProxy.position(forX: startOfDay),
            let endX = chartProxy.position(forX: nextDay)
        else {
            return nil
        }

        return (startX + endX) / 2
    }

    private func endDateStyle(start: Date, end: Date, locale: Locale) -> Date.FormatStyle {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month], from: start)
        let endComponents = calendar.dateComponents([.year, .month], from: end)
        let isSameYear = startComponents.year == endComponents.year
        let isSameMonth = startComponents.month == endComponents.month

        if isSameYear && isSameMonth {
            return .dateTime.day().locale(locale)
        } else if isSameYear {
            return .dateTime.month().day().locale(locale)
        } else {
            return .dateTime.year().month().day().locale(locale)
        }
    }

    private func shortWeekday(for date: Date) -> String {
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

private struct ChartFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

#Preview {
    SelectableBarGraphView()
}
