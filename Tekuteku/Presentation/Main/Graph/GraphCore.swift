import SwiftUI
import ComposableArchitecture
import HealthKit

@Reducer
struct GraphFeature {
    @ObservableState
    struct State: Equatable {
        var graphValue = 0
        var sampleCount = 0
        var statusMessage: String?
        var healthData: [HealthData] = []
        var isLoading = false
    }
    
    enum Action {
        case onAppear
        case healthDataResponse(Result<[HealthData], HealthKitError>)
    }
    @Dependency(\.healthDataServiceClient) var healthDataService
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.statusMessage = "HealthKit を読み込み中..."
                return .run { send in
                    do {
                        let samples = try await healthDataService.fetchHealthData()
                        await send(.healthDataResponse(.success(samples)))
                    } catch let error as HealthKitError {
                        await send(.healthDataResponse(.failure(error)))
                    } catch {
                        await send(.healthDataResponse(.failure(.underlying(error.localizedDescription))))
                    }
                }
                .cancellable(id: "graph-health-data", cancelInFlight: true)
            case .healthDataResponse(.success(let samples)):
                state.isLoading = false
                state.sampleCount = samples.count
                state.statusMessage = "取得件数: \(samples.count)件"
                return .none
            case .healthDataResponse(.failure(let error)):
                state.isLoading = false
                state.sampleCount = 0
                state.statusMessage = error.message
                return .none
            }
        }
    }
}
