import SwiftUI
import SwiftData
import ComposableArchitecture

@main
struct TekutekuApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: AppFeature.State(), reducer: {
                AppFeature()
            }))
        }
    }
}
