import SwiftUI
import ComposableArchitecture

struct AppView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        switch store.route {
        case .initialSetting:
            InitialSettingView(
                store: store.scope(
                    state: \.initialSetting,
                    action: \.initialSetting
                )
            )
        case .main:
            MainView(
                store: store.scope(
                    state: \.main,
                    action: \.main
                )
            )
        }
    }
}

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
