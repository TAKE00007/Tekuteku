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
            Text("Home")
                .tag(MainFeature.Route.home)
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }
            Text("Graph")
                .tag(MainFeature.Route.graph)
                .tabItem {
                    Label("記録", systemImage: "chart.bar")
                }
            Text("Setting")
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
