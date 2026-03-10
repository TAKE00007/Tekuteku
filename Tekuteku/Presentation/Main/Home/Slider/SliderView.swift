import SwiftUI
import ComposableArchitecture

struct SliderView: View {
    @Bindable var store: StoreOf<SliderFeature>
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Text("\(Int(store.stepCount)) 歩")
                Text("50 分")
                Text("3.5 km")
                Text("170 kcal")
            }
            .font(.title3)
            .bold()
            .padding()
            
            Slider(value: $store.stepCount, in: 0...20000, step: 10)
                .tint(Color.navy)
                .padding(.horizontal, 28)
        
            PrimaryButton(title: "コース作成", variant: .primary) {
                store.send(.tapCreateCourse)
            }
        }
    }
}
