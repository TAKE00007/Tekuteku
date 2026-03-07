import ComposableArchitecture
import SwiftUI

@Reducer
struct MainFeature {
    @ObservableState
    struct State: Equatable {
        var route: Route = .home
        var home = HomeFeature.State()
        var graph = GraphFeature.State()
        var setting = SettingFeature.State()
    }
    
    enum Action {
        case selectTab(Route)
        case home(HomeFeature.Action)
        case graph(GraphFeature.Action)
        case setting(SettingFeature.Action)
    }
    
    enum Route: Equatable {
        case home
        case graph
        case setting
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        
        Scope(state: \.graph, action: \.graph) {
            GraphFeature()
        }
        
        Scope(state: \.setting, action: \.setting) {
            SettingFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .selectTab(let route):
                state.route = route
                return .none
            case .home, .graph, .setting:
                return .none
            }
        }
    }
}

