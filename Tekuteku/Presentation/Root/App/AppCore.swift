import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var route: Route = .initialSetting
        var initialSetting =  InitialSettingFeature.State()
        var main = MainFeature.State()
    }
    
    enum Route: Equatable {
        case initialSetting
        case main
    }
    
    enum Action {
        case initialSetting(InitialSettingFeature.Action)
        case main(MainFeature.Action)
        case finishInitialSetting
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \.initialSetting, action: \.initialSetting) {
            InitialSettingFeature()
        }
        
        Scope(state: \.main, action: \.main) {
            MainFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .initialSetting(.finishButtonTapped):
                state.route = .main
                return .none
            case .initialSetting:
                return .none
            case .main:
                return .none
            case .finishInitialSetting:
                state.route = .main
                return .none
            }
        }
    }
}
