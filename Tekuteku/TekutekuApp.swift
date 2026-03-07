import SwiftUI
import SwiftData
import ComposableArchitecture

@main
struct TekutekuApp: App {
    var body: some Scene {
        WindowGroup {
            CounterView(
                store: Store(initialState: CounterFeature.State()) {
                    CounterFeature()
                }
            )
        }
    }
}
