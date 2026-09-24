import SwiftUI
import ComposableArchitecture
import Observation

@Reducer
struct BarGraphCommonFeature {
    @ObservableState
    struct State: Equatable {
        let calendar = Calendar.current
        
        let graphCategory: GraphCategory
        
        var scrollPosition: Date = Date()
        var selectedDate: Date?
        var data: [DailyRecord]
        
        var selectedData: DailyRecord?
        var visibleGraph: VisibleGraph
    }
    
    struct VisibleGraph: Equatable {
        let dailyRecords: [DailyRecord]
        let averageSteps: Double
        let maxSteps: Double

        let calendar = Calendar.current
        let locale = Locale(identifier: "ja_JP")
        
        init(dailyRecords: [DailyRecord]) {
            self.dailyRecords = dailyRecords
            self.averageSteps = dailyRecords.isEmpty ? 0.0 : dailyRecords.reduce(0) { $0 + $1.value } / Double(dailyRecords.count)
            let defaultSteps: Double = 5000
            let rawMax = dailyRecords.map(\.value).max() ?? defaultSteps
            self.maxSteps = max(defaultSteps, (rawMax / defaultSteps).rounded(.up) * defaultSteps)
        }
        
        func displayDate() -> (startDate: String, endDate: String) {
            let start = calendar.startOfDay(for: dailyRecords.first?.date ??  Date())
            let startComponents = calendar.dateComponents([.year, .month], from: start)
            let end = calendar.startOfDay(for: dailyRecords.last?.date ??  Date())
            let endComponents = calendar.dateComponents([.year, .month], from: end)
            
            let isSameYear = startComponents.year == endComponents.year
            let isSameMonth = startComponents.month == endComponents.month
            
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
        
    }

    enum GraphCategory {
        case week
        case month
        case halfYear
        case year
        
        var visibleDays: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .halfYear: return 180
            case .year: return 365
            }
        }
        
        var visibleLength: Int {
            switch self {
            case .week: return 7 * 24 * 60 * 60
            case .month: return 30 * 24 * 60 * 60
            case .halfYear: return 6 * 30 * 24 * 60 * 60
            case .year: return 12 * 30 * 24 * 60 * 60
            }
        }
        
        func endDate(from: Date, calendar: Calendar) -> Date {
            switch self {
            case .week:
                return calendar.date(byAdding: .day, value: 7, to: from) ?? from
            case .month:
                return calendar.date(byAdding: .month, value: 1, to: from) ?? from
            case .halfYear:
                return calendar.date(byAdding: .month, value: 6, to: from) ?? from
            case .year:
                return calendar.date(byAdding: .year, value: 1, to: from) ?? from
            }
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        case onAppear
        case updateVisibleData
        
        case tapBar(selectedDate: Date)
        
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
            case .binding:
                return .none
            case .onAppear:
                state.data = MockWeeklyHistoryData.twelveWeeks
                state.scrollPosition = generateScrollPosition(
                    data: state.data,
                    graphCategory: state.graphCategory,
                    calendar: state.calendar
                )
                let visibleData = generateVisibleData(
                    records: state.data,
                    scrollPosition: state.scrollPosition,
                    graphCategory: state.graphCategory,
                    calendar: state.calendar
                )
                state.visibleGraph = VisibleGraph(dailyRecords: visibleData)
                return .none
            case .updateVisibleData:
                let visibleData = generateVisibleData(
                    records: state.data,
                    scrollPosition: state.scrollPosition,
                    graphCategory: state.graphCategory,
                    calendar: state.calendar
                )
                state.visibleGraph = VisibleGraph(dailyRecords: visibleData)
                return .none
            case .tapBar(let selectedDate):
                state.selectedData = state.data.first {
                    state.calendar.isDate($0.date, inSameDayAs: selectedDate)
                }
                return .none
            }
        }
    }
    
    private func generateScrollPosition(data: [DailyRecord], graphCategory: GraphCategory, calendar: Calendar) -> Date {
        let lastDate = data.last?.date ?? Date()
        
        switch graphCategory {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: lastDate) ?? lastDate
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: lastDate) ?? lastDate
        case .halfYear:
            return calendar.date(byAdding: .month, value: -6, to: lastDate) ?? lastDate
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: lastDate) ?? lastDate
        }
    }
    
    private func generateVisibleData(records: [DailyRecord], scrollPosition: Date, graphCategory: GraphCategory, calendar: Calendar) -> [DailyRecord] {
        let start = calendar.startOfDay(for: scrollPosition)
        let end = switch graphCategory {
        case .week:
            calendar.date(byAdding: .day, value: 7, to: start) ?? start
        case .month:
            calendar.date(byAdding: .month, value: 1, to: start) ?? start
        case .halfYear:
            calendar.date(byAdding: .month, value: 6, to: start) ?? start
        case .year:
            calendar.date(byAdding: .year, value: 1, to: start) ?? start
        }
        
        return records.filter { data in
            start <= data.date && data.date < end
        }
    }
}
