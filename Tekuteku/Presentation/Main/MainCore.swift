import ComposableArchitecture
import SwiftUI

@Reducer
struct MainFeature {
    @ObservableState
    struct State: Equatable {
        var route: Route = .home
    }
    
    enum Action {
        case selectTab(Route)
    }
    
    enum Route: Equatable {
        case home
        case graph
        case setting
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .selectTab(let route):
                state.route = route
                return .none
            }
        }
    }
}

