import ComposableArchitecture
import SwiftUI

@Reducer
struct MainFeature {
    @ObservableState
    struct State: Equatable {
        var route: Route = .map
        var isInitial = false
    }
    
    enum Action {
        case map
        case graph
        case setting
    }
    
    enum Route: Equatable {
        case map
        case graph
        case setting
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .map:
                state.route = .map
                return .none
            case .graph:
                state.route = .graph
                return .none
            case .setting:
                state.route = .setting
                return .none
            }
        }
    }
}

