import SwiftUI
import ComposableArchitecture

struct CounterView: View {
    let store: StoreOf<CounterFeature>
    
    var body: some View {
        VStack(spacing: 16) {
            Text("\(store.count) ")
                .font(.largeTitle)
            
            HStack {
                Button("-") {
                    store.send(.decrementButtonTapped)
                }
                
                Button("+") {
                    store.send(.incrementButtonTapped)
                }
            }
        }
    }
}

#Preview {
    CounterView(store: Store(initialState: CounterFeature.State(), reducer: {
        CounterFeature()
    }))
}
