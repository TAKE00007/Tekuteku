import SwiftUI
import ComposableArchitecture

struct MainView: View {
    @Bindable var store: StoreOf<MainFeature>
    
    var body: some View {
        TabView(
            selection: Binding(
                get: { store.route },
                set: { store.send(.selectTab($0)) }
            )
        ) {
            HomeView(
                store: store.scope(state: \.home, action: \.home)
            )
            .tag(MainFeature.Route.home)
            .tabItem {
                Label("ホーム", systemImage: "house")
            }
            
            GraphView(
                store: store.scope(state: \.graph, action: \.graph)
            )
            .tag(MainFeature.Route.graph)
            .tabItem {
                Label("記録", systemImage: "chart.bar")
            }
            
            SettingView(
                store: store.scope(state: \.setting, action: \.setting)
            )
            .tag(MainFeature.Route.setting)
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    MainView(store: Store(initialState: MainFeature.State(), reducer: {
        MainFeature()
    }))
}
