import SwiftUI
import ComposableArchitecture

@Reducer
struct GraphFeature {
    @ObservableState
    struct State: Equatable {
        var graphValue = 0
    }
    
    enum Action {
        case onAppear
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            }
        }
    }
}
