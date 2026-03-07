import ComposableArchitecture
import SwiftUI

struct InitialSettingView: View {
    let store: StoreOf<InitialSettingFeature>
    
    var body: some View {
        Button("目標を設定する") {
            store.send(.settingGoal)
        }
        Button("ホームへ行く") {
            store.send(.finishButtonTapped)
        }
    }
}

#Preview {
    InitialSettingView(store: Store(initialState: InitialSettingFeature.State(), reducer: {
        InitialSettingFeature()
    }))
}
