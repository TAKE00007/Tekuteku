import Foundation

struct WeatherData: Equatable, Sendable {
    let weather: Weather
    let temperature: Float
    let apparentTemperature: Float
    let windSpeed: Float
    let windDirection: Float
}


enum Weather: Equatable, Sendable {
    case sunny
    case cloud
    case rainy
}

/// 下記にWMOコードが書いてある
/// https://open-meteo.com/en/docs?timezone=Asia%2FTokyo&forecast_days=1&hourly=temperature_2m,weather_code
extension Weather {
    nonisolated init(from code: Int) {
        switch code {
        case 0, 1:
            self = .sunny
        case 2, 3, 45, 48:
            self = .cloud
        default:
            self = .rainy
        }
    }
}
