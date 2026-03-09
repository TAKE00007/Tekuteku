import SwiftUI
import ComposableArchitecture

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var homeValue = 0
        var isWalkingSheetPresented = false
    }
    
    enum Action {
        case onAppear
        case tapWalking
        case setWalkingSheet(isPresented: Bool)
    }
    
    var body: some Reducer<State, Action> {
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
            }
        }
    }
}
