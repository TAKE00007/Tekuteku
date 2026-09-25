import SwiftUI
import ComposableArchitecture
import Observation

@Reducer
struct StepsHistoryChartFeature {
    @ObservableState
    struct State: Equatable {
        var hasLoaded = false
        
        let calendar: Calendar
        let locale: Locale
        let graphCategory: GraphCategory
        
        var records: [DailyRecord] = []
        var visibleChart: VisibleChartSummary

        var scrollPosition: Date = Date()

        var selectedDate: Date?
        var selectedRecord: DailyRecord? {
            guard let selectedDate else { return nil }
            
            return records.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        }

        init(
            graphCategory: GraphCategory,
            calendar: Calendar = .current,
            locale: Locale = Locale(identifier: "ja_JP")
        ) {
            self.graphCategory = graphCategory
            self.calendar = calendar
            self.locale = locale
            self.visibleChart = VisibleChartSummary(
                dailyRecords: [],
                interval: DateInterval(),
                calendar: calendar,
                locale: locale
            )
        }
    }
    
    
    struct VisibleChartSummary: Equatable {
        let dateInterval: DateInterval
        let averageSteps: Double
        let maximumSteps: Double
        let calendar: Calendar
        let locale: Locale
        
        init(dailyRecords: [DailyRecord], interval: DateInterval, calendar: Calendar, locale: Locale) {
            self.dateInterval = interval
            self.calendar = calendar
            self.locale = locale
            self.averageSteps = dailyRecords.isEmpty ? 0.0 : dailyRecords.reduce(0) { $0 + $1.value } / Double(dailyRecords.count)
            let defaultSteps: Double = 5000
            let rawMax = dailyRecords.map(\.value).max() ?? defaultSteps
            self.maximumSteps = max(defaultSteps, (rawMax / defaultSteps).rounded(.up) * defaultSteps)
        }
        
        func formattedDateRange() -> (startDate: String, endDate: String) {
            let startComponents = calendar.dateComponents([.year, .month], from: dateInterval.start)
            let endComponents = calendar.dateComponents([.year, .month], from: dateInterval.end)
            
            let isSameYear = startComponents.year == endComponents.year
            let isSameMonth = startComponents.month == endComponents.month
            
            let startDate = dateInterval.start.formatted(.dateTime
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
            
            let displayEnd = calendar.date(
                byAdding: .day,
                value: -1,
                to: dateInterval.end
            ) ?? dateInterval.end
            let endDate = displayEnd.formatted(endStyle)
            
            return (startDate, endDate)
        }
        
    }

    enum GraphCategory {
        case week
        case month
        case halfYear
        case year
        
        func dateInterval(containing date: Date, calendar: Calendar) -> DateInterval {
            switch self {
            case .week:
                let start = calendar.startOfDay(for: date)
                let end = calendar.date(
                    byAdding: .day,
                    value: 7,
                    to: start
                ) ?? start
                
                return DateInterval(start: start, end: end)
            case .month:
                let start = calendar.startOfDay(for: date)
                let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
                return DateInterval(start: start, end: end)
            case .halfYear:
                let start = calendar.startOfDay(for: date)
                let end = calendar.date(byAdding: .month, value: 6, to: start) ?? start
                return DateInterval(start: start, end: end)
            case .year:
                let start = calendar.startOfDay(for: date)
                let end = calendar.date(byAdding: .year, value: 1, to: start) ?? start
                return DateInterval(start: start, end: end)

            }
        }
        
        func initialScrollPosition(
            latestDate: Date,
            calendar: Calendar
        ) ->  Date {
            let latestDay = calendar.startOfDay(for: latestDate)
            
            switch self {
            case .week:
                return calendar.date(
                    byAdding: .day,
                    value: -6,
                    to: latestDay
                ) ?? latestDay
            case .month:
                return calendar.date(
                    byAdding: .day,
                    value: -29,
                    to: latestDay
                ) ?? latestDay
            case .halfYear:
                return calendar.date(
                    byAdding: .month,
                    value: -6,
                    to: latestDay
                ) ?? latestDay
            case .year:
                return calendar.date(
                    byAdding: .year,
                    value: -1,
                    to: latestDay
                ) ?? latestDay

            }
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        case task
        case updateVisibleSummary
        case selectionCleared
    }

    @Dependency(\.continuousClock) var clock
    
    private nonisolated enum CancelID: Hashable, Sendable {
        case updateVisibleSummary
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding(\.scrollPosition):
                return .run { send in
                    try await clock.sleep(for: .milliseconds(150)) // TODO: 後で調整する
                    await send(.updateVisibleSummary)
                }
                .cancellable(
                    id: CancelID.updateVisibleSummary,
                    cancelInFlight: true
                )
            case .binding(\.selectedDate):
                return .none
            case .binding:
                return .none
            case .task:
                guard !state.hasLoaded else { return .none }
                defer { state.hasLoaded = true }
                state.records = MockWeeklyHistoryData.twelveWeeks // TODO: HealthKitから読み込む
                
                let latestDate = state.records.map(\.date).max() ?? Date()
                state.scrollPosition = state.graphCategory.initialScrollPosition(
                    latestDate: latestDate,
                    calendar: state.calendar
                )
                
                updateVisibleChart(&state)
                return .none
            case .updateVisibleSummary:
                updateVisibleChart(&state)
                return .none
            case .selectionCleared:
                state.selectedDate = nil
                return .none
            }
        }
    }
    
    private func updateVisibleChart(_ state: inout State) {
        let interval = state.graphCategory.dateInterval(
            containing: state.scrollPosition,
            calendar: state.calendar
        )
        let visibleData = state.records.filter { interval.contains($0.date) }
        
        state.visibleChart = VisibleChartSummary(
            dailyRecords: visibleData,
            interval: interval,
            calendar: state.calendar,
            locale: state.locale
        )
    }
}
