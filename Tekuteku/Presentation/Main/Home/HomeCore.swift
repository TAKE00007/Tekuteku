import SwiftUI
import ComposableArchitecture

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var isWalkingSheetPresented = false
        var slider = SliderFeature.State()
    }
    
    enum Action {
        case onAppear
        case tapWalking
        case setWalkingSheet(isPresented: Bool)
        case slider(SliderFeature.Action)
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \.slider, action: \.slider) {
            SliderFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            case .tapWalking:
                state.isWalkingSheetPresented = true
                return .none
            case .setWalkingSheet(let isPresented):
                state.isWalkingSheetPresented = isPresented
                return .none
            case .slider(.tapCreateCourse):
            // TODO: コース作成処理
                return .none
            case .slider:
                return .none
            }
        }
    }
}
