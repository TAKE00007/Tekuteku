import ComposableArchitecture
import SwiftUI

@Reducer
struct InitialSettingFeature {
    @ObservableState
    struct State: Equatable {
        var goal = 0
    }
    
    enum Action {
        case settingGoal
        case finishButtonTapped
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .settingGoal:
                state.goal += 1 // 一旦仮
                return .none
            case .finishButtonTapped:
                return .none
            }
        }
    }
}

