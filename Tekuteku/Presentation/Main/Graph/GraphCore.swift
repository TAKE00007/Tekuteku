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
        var isLoading = false
    }
    
    enum Action {
        case onAppear
        case healthDataResponse(Result<[HKSample], HealthKitError>)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.statusMessage = "HealthKit を読み込み中..."
                return .run { send in
                    do {
                        let samples = try await Self.prepareHealthData()
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
    private static func prepareHealthData() async throws -> [HKSample] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.unavailable
        }

        let healthStore = HKHealthStore()
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        try await requestAuthorization(
            healthStore: healthStore,
            readTypes: Set([stepCountType])
        )

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        return try await fetchSamples(
            healthStore: healthStore,
            sampleType: stepCountType,
            startDate: startDate,
            endDate: endDate
        )
    }

    private static func requestAuthorization(
        healthStore: HKHealthStore,
        readTypes: Set<HKObjectType>
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.underlying(error.localizedDescription))
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: HealthKitError.authorizationDenied)
                }
            }
        }
    }

    private static func fetchSamples(
        healthStore: HKHealthStore,
        sampleType: HKSampleType,
        startDate: Date,
        endDate: Date
    ) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: HKQuery.predicateForSamples(withStart: startDate, end: endDate),
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]
            ) { _, results, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.underlying(error.localizedDescription))
                } else {
                    continuation.resume(returning: results ?? [])
                }
            }

            healthStore.execute(query)
        }
    }
}

enum HealthKitError: Error {
    case unavailable
    case authorizationDenied
    case underlying(String)

    var message: String {
        switch self {
        case .unavailable:
            return "このデバイスでは HealthKit を利用できません"
        case .authorizationDenied:
            return "HealthKit の権限がありません"
        case .underlying(let message):
            return "HealthKit の取得に失敗しました: \(message)"
        }
    }
}
