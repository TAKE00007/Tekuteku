import SwiftUI
import Charts

struct MonthGraphView: View {
    let sampleData: [DailyRecord] = MockWeeklyHistoryData.twelveWeeks
    private static let calendar = Calendar.current
    
    @State private var rawSelectedDate: Date?
    @State private var selectedData: DailyRecord?
    @State private var scrollPosition: Date = {
        let lastDate = MockWeeklyHistoryData.twelveWeeks.last?.date ?? Date()
        return calendar.date(byAdding: .day, value: -6, to: lastDate) ?? lastDate
    }()
    
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
        .onChange(of: rawSelectedDate) { _, newValue in
            guard let newValue else {
                selectedData = nil
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
                if let date = value.as(Date.self) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.day().locale(Locale(identifier: "ja_JP")))
                }
            }
        }
        .chartBackground { chartProxy in
            selectionBackground(chartProxy: chartProxy)
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
