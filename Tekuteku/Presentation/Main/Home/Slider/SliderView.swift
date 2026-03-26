import SwiftUI
import ComposableArchitecture
import MapKit

struct SliderView: View {
    @Bindable var store: StoreOf<SliderFeature>
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Text("\(Int(store.stepCount)) 歩")
                Text("50 分") // TODO: 今後修正
                Text("\(store.distance) km") // TODO: 距離は小数点第一位まで計算できるようにする
                Text("170 kcal") // TODO: 今後修正
            }
            .font(.title3)
            .bold()
            .padding()
            
            Slider(value: $store.stepCount, in: 0...20000, step: 10)
                .tint(Color.navy)
                .padding(.horizontal, 28)
        
            PrimaryButton(title: "コース作成", variant: .primary) {
                store.send(.tapCreateCourse(distance: store.courceDistance))
            }
        }
    }
}
