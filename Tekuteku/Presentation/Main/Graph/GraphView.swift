import SwiftUI
import ComposableArchitecture

struct GraphView: View {
    let store: StoreOf<GraphFeature>
    
    var body: some View {
        VStack {
            Text("記録を表示する")
        }
        .task {
            store.send(.onAppear)
        }
    }
}

#Preview {
    GraphView(store: Store(initialState: GraphFeature.State(), reducer: {
        GraphFeature()
    }))
}
