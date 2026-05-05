import Foundation
import ComposableArchitecture
import HealthKit

struct HealthDataServiceClient {
    var fetchHealthData: @Sendable () async throws -> [HealthData]
}

extension HealthDataServiceClient: DependencyKey {
    static let liveValue: Self = .live
    
    static let testValue: Self = .init {
        var dateComponent = DateComponents()
        dateComponent.year = 1999
        dateComponent.month = 11
        dateComponent.day = 3
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponent)!
        return [HealthData(date: date, stepCount: 5000.0, distanceKilometers: 3.0)]
    }
}

extension DependencyValues {
    var healthDataServiceClient: HealthDataServiceClient {
        get { self[HealthDataServiceClient.self] }
        set { self[HealthDataServiceClient.self] = newValue }
    }
}

extension HealthDataServiceClient {
    static let live = Self(
        fetchHealthData: {
            guard HKHealthStore.isHealthDataAvailable() else {
                throw HealthKitError.unavailable
            }
            let healthStore = HKHealthStore()
            let manager = HealthDataManager()
            let healthData = try await manager.fetchHealthDataForGraph(healthStore: healthStore)
            
            return healthData
        }
    )
}

nonisolated private struct HealthDataManager {
    fileprivate func fetchHealthDataForGraph(healthStore: HKHealthStore) async throws -> [HealthData] {
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let distanceWalkingRunningType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        
        try await requestAuthorization(
            healthStore: healthStore,
            readTypes: Set([stepCountType, distanceWalkingRunningType])
        )
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: endDate)) ?? endDate
        var interval = DateComponents()
        interval.day = 1
        
        let stepData = try await fetchHealthData(
            healthStore: healthStore,
            identifier: .stepCount,
            startDate: startDate,
            endDate: endDate,
            interval: interval
        )
        
        let distanceData = try await fetchHealthData(
            healthStore: healthStore,
            identifier: .distanceWalkingRunning,
            startDate: startDate,
            endDate: endDate,
            interval: interval
        )
        
        let healthData = stepData.map {
            HealthData(date: $0.key, stepCount: $0.value, distanceKilometers: distanceData[$0.key] ?? 0.0)
        }

        return healthData
    }

    private func requestAuthorization(healthStore: HKHealthStore, readTypes: Set<HKObjectType>) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.underlying(error.localizedDescription))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    private func fetchHealthData(
        healthStore: HKHealthStore,
        identifier: HKQuantityTypeIdentifier,
        startDate: Date,
        endDate: Date,
        interval: DateComponents
    ) async throws -> [Date: Double] {
        let quantityType = HKQuantityType(identifier)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let dailyData: [Date: Double] = try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: interval
            )
            
            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results else {
                    continuation.resume(returning: [:])
                    return
                }
                
                var dailyData: [Date: Double] = [:]
                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    var data: Double = 0.0
                    switch identifier {
                    case .stepCount:
                        data = statistics.sumQuantity()? .doubleValue(for: .count()) ?? 0
                    case .distanceWalkingRunning:
                        data = statistics.sumQuantity()? .doubleValue(for: .meterUnit(with: .kilo)) ?? 0
                    default:
                        break
                    }
                    dailyData[statistics.startDate] = data
                }
                
                continuation.resume(returning: dailyData)
            }
            healthStore.execute(query)
        }
        
        return dailyData
    }
}


struct HealthData: Identifiable, Equatable {
    let date: Date
    let stepCount: Double
    let distanceKilometers: Double
    var id: Date { date }
}
