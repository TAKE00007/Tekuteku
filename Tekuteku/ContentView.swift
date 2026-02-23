import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Text("これから散歩アプリを作ります")
    }
}

#Preview {
    ContentView()
}
