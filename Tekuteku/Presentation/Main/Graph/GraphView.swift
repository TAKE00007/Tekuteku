import SwiftUI
import ComposableArchitecture
import Charts

enum TopTab: String, Identifiable, Hashable, CaseIterable {
    case day = "日"
    case week = "週"
    case month = "月"
    case halfYear = "6か月"
    case year = "年"
    
    var id: String { rawValue }
}

struct GraphView: View {
    let store: StoreOf<GraphFeature>

    @Binding var selection: TopTab
    @Namespace private var ns
    
    var tabs: [TopTab] = TopTab.allCases
    
    var body: some View {
        VStack {
            Picker("kind", selection: $selection) {
                ForEach(TopTab.allCases) { type in
                    Text(type.rawValue)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(16)
            
            switch selection {
            case .day:
                DayGraphView(isActive: selection == .day)
            case .week:
                StepsHistoryChartView(
                    store: store.scope(
                        state: \.weekChart,
                        action: \.weekChart
                    )
                )
            case .month:
                MonthGraphView()
            case .halfYear:
                GraphPage(title: "6か月")
            case .year:
                GraphPage(title: "年")
            }
            
            if store.isLoading {
                ProgressView()
            }
        }
        .task {
//            store.send(.onAppear)
        }
    }
}


struct WeekGraphData: Identifiable {
    var id: String { day }
    var day: String
    var value: Double
}

struct GraphPage: View {
    let title: String
    
    var body: some View {
        Text(title)
    }
}

#Preview {
    GraphViewPreview()
}

private struct GraphViewPreview: View {
    @State private var selection: TopTab = .day
    
    var body: some View {
        GraphView(
            store: Store(initialState: GraphFeature.State(), reducer: {
                GraphFeature()
            }),
            selection: $selection
        )
    }
}

struct GraphData: Identifiable, Equatable {
    var id: String { name }
    let value: Double
    let name: String
}
