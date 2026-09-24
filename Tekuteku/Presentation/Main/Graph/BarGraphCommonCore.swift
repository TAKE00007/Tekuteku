import SwiftUI
import ComposableArchitecture
import Observation

@Reducer
struct BarGraphCommonFeature {
    @ObservableState
    struct State: Equatable {
        let calendar = Calendar.current
        let graphCategory: GraphCategory
        var data: [DailyRecord]
        
        var scrollPosition: Date
        var selectedDate: Date?
        
        var selectedRecord: DailyRecord? {
            guard let selectedDate else { return nil }
            
            return data.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        }
        var visibleGraph: VisibleGraph
    }
    
    struct VisibleGraph: Equatable {
        let dailyRecords: [DailyRecord]
        let displayDates: DateInterval
        let averageSteps: Double
        let maxSteps: Double

        let calendar = Calendar.current
        let locale = Locale(identifier: "ja_JP")
        
        init(dailyRecords: [DailyRecord], interval: DateInterval) {
            self.dailyRecords = dailyRecords
            self.displayDates = interval
            self.averageSteps = dailyRecords.isEmpty ? 0.0 : dailyRecords.reduce(0) { $0 + $1.value } / Double(dailyRecords.count)
            let defaultSteps: Double = 5000
            let rawMax = dailyRecords.map(\.value).max() ?? defaultSteps
            self.maxSteps = max(defaultSteps, (rawMax / defaultSteps).rounded(.up) * defaultSteps)
        }
        
        func displayDate() -> (startDate: String, endDate: String) {
            let startComponents = calendar.dateComponents([.year, .month], from: displayDates.start)
            let endComponents = calendar.dateComponents([.year, .month], from: displayDates.end)
            
            let isSameYear = startComponents.year == endComponents.year
            let isSameMonth = startComponents.month == endComponents.month
            
            let startDate = displayDates.start.formatted(.dateTime
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
            
            let endDate = displayDates.end.formatted(endStyle)
            
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
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        case onAppear
        case updateVisibleData
        case selectionCleared
    }

    @Dependency(\.continuousClock) var clock
    
    private nonisolated enum CancelID: Hashable, Sendable {
        case updateVisibleData
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding(\.scrollPosition):
                return .run { send in
                    try await clock.sleep(for: .milliseconds(20)) // TODO: 後で調整する
                    await send(.updateVisibleData)
                }
                .cancellable(
                    id: CancelID.updateVisibleData,
                    cancelInFlight: true
                )
            case .binding(\.selectedDate):
                return .none
            case .binding:
                return .none
            case .onAppear:
                state.data = MockWeeklyHistoryData.twelveWeeks // TODO: HealthKitから読み込む
                
                let latestDate = state.data.map(\.date).max() ?? Date()
                let interval = state.graphCategory.dateInterval(
                    containing: latestDate,
                    calendar: state.calendar
                )
                state.scrollPosition = interval.start
                
                updateVisibleChart(&state, interval: interval)
                return .none
            case .updateVisibleData:
                let interval = state.graphCategory.dateInterval(containing: state.scrollPosition, calendar: state.calendar)
                updateVisibleChart(&state, interval: interval)
                return .none
            case .selectionCleared:
                state.selectedDate = nil
                return .none
            }
        }
    }
    
    private func updateVisibleChart(_ state: inout State, interval: DateInterval) {
        let visibleData = state.data.filter { interval.contains($0.date) }
        
        state.visibleGraph = VisibleGraph(dailyRecords: visibleData, interval: interval)
    }
}
