import ComposableArchitecture

@Reducer
struct SliderFeature {
    @ObservableState
    struct State: Equatable {
        var stepCount: Double = 5000
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case tapCreateCourse
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
