import Foundation

enum WetherError: Error, Equatable {
    case failLoadWeatherData
    case unknown
    
    var message: String {
        switch self {
        case .failLoadWeatherData:
            return "天気情報の取得に失敗しました"
        case .unknown:
            return "不明なエラーです"
        }
    }
}
