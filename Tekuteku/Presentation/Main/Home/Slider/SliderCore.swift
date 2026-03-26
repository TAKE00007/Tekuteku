import ComposableArchitecture
import MapKit

@Reducer
struct SliderFeature {
    @ObservableState
    struct State: Equatable {
        var stepCount: Double = 5000
        var distance: Int {
            return Int(stepCount * 0.7 / 1000)
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
