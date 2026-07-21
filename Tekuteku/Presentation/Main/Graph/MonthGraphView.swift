import SwiftUI
import Charts

struct MonthGraphView: View {
    let sampleData: [DailyRecord] = MockWeeklyHistoryData.twelveWeeks
    private let visibleMonth = 1
    private static let calendar = Calendar.current
    
    @State private var rawSelectedDate: Date?
    @State private var selectedData: DailyRecord?
    @State private var scrollPosition: Date = {
        let lastDate = MockWeeklyHistoryData.twelveWeeks.last?.date ?? Date()
        return calendar.date(byAdding: .day, value: -29, to: lastDate) ?? lastDate
    }()
    
    private var visibleData: [DailyRecord] {
        let start = MonthGraphView.calendar.startOfDay(for: scrollPosition)
        let end = MonthGraphView.calendar.date(byAdding: .month, value: 1, to: start) ?? start
        
        return sampleData.filter { data in
            start <= data.date && data.date < end
        }
    }
    
    private var visibleDate: (startDate: String, endDate: String) {
        let start = visibleData.first?.date ?? Date()
        let startComponent = MonthGraphView.calendar.dateComponents([.year, .month], from: start)
        let end = MonthGraphView.calendar.date(byAdding: .month, value: visibleMonth,to: start) ?? start
        let endComponent = MonthGraphView.calendar.dateComponents([.year, .month], from: end)
        let locale = Locale(identifier: "ja_JP")
        
        let isSameYear = startComponent.year == endComponent.year
        let isSameMonth = startComponent.month == endComponent.month
        
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
                return .dateTime.year().month().day().locale(locale)
            } else {
                return .dateTime.year().month().day().locale(locale)
            }
        }()
        
        let endDate = end.formatted(endStyle)
        
        return (startDate, endDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            
            VStack(alignment: .leading) {

                if selectedData == nil {
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
                    Text("\(visibleDate.startDate)~\(visibleDate.endDate)")
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
        .onChange(of: rawSelectedDate) { _, newValue in
            guard let newValue else {
                return
            }
            
            let newData = handleSelection(selectedDate: newValue)
            
            if let selectedData, selectedData == newData {
                self.selectedData = nil
            } else {
                selectedData = newData
            }
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
        .chartXSelection(value: $rawSelectedDate)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.gray.opacity(0.8))
            }
            
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                if value.as(Date.self) != nil {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.day().locale(Locale(identifier: "ja_JP")))
                }
            }
        }
        .chartBackground { chartProxy in
            selectionBackground(chartProxy: chartProxy)
        }
        .chartOverlay { chartProxy in
            selectionOverlay(chartProxy: chartProxy)
        }
    }
    
    private func selectionBackground(chartProxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            if let selectedData,
               let plotFrame = chartProxy.plotFrame,
               let x = centerX(for: selectedData.date, chartProxy: chartProxy) {
                let frame = geometry[plotFrame]
                let lineX = frame.minX + x
                
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(width: 2, height: frame.height + 40)
                    .position(
                        x: lineX,
                        y: frame.minY + frame.height / 2 - 20
                    )
            }
        }
    }
    
    private func selectionOverlay(chartProxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            if let selectedData,
               let plotFrame = chartProxy.plotFrame,
               let x = centerX(for: selectedData.date, chartProxy: chartProxy) {
                let frame = geometry[plotFrame]
                let lineX = frame.minX + x
                
                AnnotationView
                    .position(
                        x: lineX,
                        y: frame.minY - 40
                    )
            }
        }
    }
    
    private var AnnotationView: some View {
        VStack(alignment: .leading) {
            Text("合計")
                .font(.caption)
                .foregroundStyle(.gray)
            HStack(alignment: .lastTextBaseline) {
                let step = Int(selectedData?.value ?? 0.0)
                Text("\(step)")
                    .font(.title2)
                Text("歩")
                    .foregroundStyle(.gray)
            }
            .bold()
            
            if let selectedData {
                Text(selectedData.date, format: Date.FormatStyle(date: .numeric, time: .none))
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    
    private func centerX(for date: Date, chartProxy: ChartProxy) -> CGFloat? {
        let startOfDay = MonthGraphView.calendar.startOfDay(for: date)
        
        guard
            let nextDay = MonthGraphView.calendar.date(byAdding: .day, value: 1, to: startOfDay),
            let startX = chartProxy.position(forX: startOfDay),
            let endX = chartProxy.position(forX: nextDay)
        else {
            return nil
        }
        
        return (startX + endX) / 2
    }
    
    private func handleSelection(selectedDate: Date) -> DailyRecord? {
        let closet = sampleData.min(by: { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) })
        return sampleData.first { data in data.date == closet?.date }
    }
}

#Preview {
    MonthGraphView()
}
