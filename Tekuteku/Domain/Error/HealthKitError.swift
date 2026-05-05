import Foundation

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
