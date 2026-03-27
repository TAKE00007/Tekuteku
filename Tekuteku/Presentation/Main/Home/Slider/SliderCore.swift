import ComposableArchitecture
import MapKit

@Reducer
struct SliderFeature {
    @ObservableState
    struct State: Equatable {
        var stepCount: Double = 5000
        // 一歩を0.7 mとして計算
        var distance: Double {
            return stepCount * 0.7 / 1000
        }
        // 4km/1h → 1km/15min
        var expectedMinute: Int {
            return Int(distance * 15)
        }
        // 1歩で0.04kcl
        var calories: Int {
            Int(stepCount * 0.04)
        }

        var courceDistance: Double {
            return Double(distance) * 1000.0
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case tapCreateCourse(distance: Double)
    }
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .tapCreateCourse:
                return .none
            }
        }
    }
}
