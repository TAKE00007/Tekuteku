import SwiftUI
import ComposableArchitecture

struct SettingView: View {
    let store: StoreOf<SettingFeature>
    
    var body: some View {
        VStack {
            Text("設定を表示する")
        }
        .task {
            store.send(.onAppear)
        }
    }
}

#Preview {
    SettingView(store: Store(initialState: SettingFeature.State(), reducer: {
        SettingFeature()
    }))
}
