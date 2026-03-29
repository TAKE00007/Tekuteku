import SwiftUI
import ComposableArchitecture
import MapKit

struct SliderView: View {
    @Bindable var store: StoreOf<SliderFeature>
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Text("\(Int(store.stepCount)) 歩")
                Text("\(store.expectedMinute) 分")
                let distance = store.distance.formatted(.number.precision(.fractionLength(1)))
                Text("\(distance) km")
                Text("\(store.calories) kcal")
            }
            .font(.title3)
            .bold()
            .padding()
            
            Slider(value: $store.stepCount, in: 0...20000, step: 100)
                .tint(Color.navy)
                .padding(.horizontal, 28)
        
            PrimaryButton(title: "コース作成", variant: .primary) {
                store.send(.tapCreateCourse(distance: store.courceDistance))
            }
        }
    }
}
