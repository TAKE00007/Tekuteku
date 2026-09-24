import SwiftUI
import Charts
import ComposableArchitecture

struct StepsHistoryChartView: View {
    @Bindable var store: StoreOf<StepsHistoryChartFeature>
    
    @State private var chartFrame: CGRect = .zero
    @State private var containerFrame: CGRect = .zero
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            
            VStack(alignment: .leading) {
                if store.selectedDate == nil {
                    Text("平均")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    HStack {
                        Text(Int(store.visibleChart.averageSteps), format: .number)
                            .font(.largeTitle)
                        Text("歩")
                            .bold()
                            .foregroundStyle(.gray)
                    }
                    let (startDate, endDate) = store.visibleChart.formattedDateRange()
                    Text("\(startDate)~ \(endDate)")
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
                .background {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                chartFrame = geometry.frame(in: .global)
                            }
                            .onChange(of: geometry.frame(in: .global)) { _, newValue in
                                chartFrame = newValue
                            }
                    }
                }
                .padding()
            
            Spacer()
        }
        .task {
            store.send(.task)
        }
        .background {
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        containerFrame = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, newValue in
                        containerFrame = newValue
                    }
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            SpatialTapGesture()
                .onEnded { value in
                    let globalLocation = CGPoint(
                        x: containerFrame.minX + value.location.x,
                        y: containerFrame.minY + value.location.y
                    )
                    
                    guard chartFrame != .zero else { return }
                    guard !chartFrame.contains(globalLocation) else { return }
                    store.send(.selectionCleared)
                }
        )
    }
    
    private var chartContent: some View {
        Chart(store.records) { data in
            BarMark(
                x: .value("Day", data.date, unit: .day),
                y: .value("Step", data.value)
            )
        }
        .chartXSelection(value: $store.selectedDate)
        .chartScrollPosition(x: $store.scrollPosition)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: store.visibleChart.dateInterval.duration)
        .chartXAxis {
            xAxisContent
        }
        .chartYScale(domain: 0...store.visibleChart.maximumSteps)
        .chartYAxis {
            AxisMarks(
                position: .trailing,
                values: [
                    0,
                    store.visibleChart.maximumSteps / 2,
                    store.visibleChart.maximumSteps
                ]
            ) {
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartBackground { chartProxy in
            selectionBackground(chartProxy: chartProxy)
        }
        .chartOverlay { chartProxy in
            selectionOverlay(chartProxy: chartProxy)
        }
        .chartGesture { chartProxy in
            SpatialTapGesture()
                .onEnded { value in
                    chartProxy.selectXValue(at: value.location.x)
                }
                .exclusively(
                    before: DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            chartProxy.selectXValue(at: value.location.x)
                        }
                )
        }
    }
    
    private func selectionBackground(chartProxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            if let selectedDate = store.selectedDate,
               let plotFrame = chartProxy.plotFrame,
               let x = centerX(for: selectedDate, chartProxy: chartProxy) {
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
            if let selectedDate = store.selectedDate,
               let plotFrame = chartProxy.plotFrame,
               let x = centerX(for: selectedDate, chartProxy: chartProxy) {
                let frame = geometry[plotFrame]
                let lineX = frame.minX + x

                selectionAnnotation
                    .position(
                        x: lineX,
                        y: frame.minY - 40
                    )
            }
        }
    }
    
    private var selectionAnnotation: some View {
        VStack(alignment: .leading) {
            Text("合計")
                .font(.caption)
                .foregroundStyle(.gray)
            HStack(alignment: .lastTextBaseline) {
                let step = Int(store.selectedRecord?.value ?? 0.0)
                Text("\(step)")
                    .font(.title2)
                Text("歩")
                    .foregroundStyle(.gray)
            }
            .bold()
            
            if let selectedDate = store.selectedDate {
                Text(selectedDate, format: Date.FormatStyle(date: .numeric, time: .none))
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func centerX(
        for date: Date,
        chartProxy: ChartProxy
    ) -> CGFloat? {
        let startOfDay = store.calendar.startOfDay(for: date)

        guard
            let nextDay = store.calendar.date(byAdding: .day, value: 1, to: startOfDay),
            let startX = chartProxy.position(forX: startOfDay),
            let endX = chartProxy.position(forX: nextDay)
        else {
            return nil
        }

        return (startX + endX) / 2
    }
}

private extension StepsHistoryChartView {
    @AxisContentBuilder
    var xAxisContent: some AxisContent {
        switch store.graphCategory {
        case .week: weeklyXAxis
        default: longTermXAxis
        }
    }
    
    @AxisContentBuilder
    var weeklyXAxis: some AxisContent {
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
    
    @AxisContentBuilder
    var longTermXAxis: some AxisContent {
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
    
    private func shortWeekday(for date: Date) -> String {
        var formatStyle = Date.FormatStyle.dateTime
            .weekday(.narrow)
            .locale(store.locale)
        
        formatStyle.calendar = store.calendar
        
        return date.formatted(formatStyle)
    }
}

#Preview {
    StepsHistoryChartView(
        store: Store(
            initialState: StepsHistoryChartFeature.State(
                graphCategory: .week,
                records: MockWeeklyHistoryData.twelveWeeks,
                scrollPosition: Date(),
                visibleChart: StepsHistoryChartFeature.VisibleChartSummary(
                    dailyRecords: MockWeeklyHistoryData.twelveWeeks,
                    interval: DateInterval(),
                    calendar: Calendar.current,
                    locale: Locale(identifier: "ja_JP")
                )
            ),
            reducer:  { StepsHistoryChartFeature() }
        )
    )
}
