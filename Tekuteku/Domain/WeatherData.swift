import Foundation

struct WeatherData: Equatable, Sendable {
    let weather: Weather
    let temperature: Float
    let apparentTemperature: Float
    let windSpeed10m: Float
    let windDirection10m: Float
}


enum Weather: Equatable, Sendable {
    case sunny
    case cloud
    case rainy
}

/// 下記にWMOコードが書いてある
/// https://open-meteo.com/en/docs?timezone=Asia%2FTokyo&forecast_days=1&hourly=temperature_2m,weather_code
extension Weather {
    init(from code: Int) {
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

struct WeatherResponse: Decodable {
    let current: Current
    
    struct Current: Decodable {
        let temperature_2m: Float
        let apparent_temperature: Float
        let wind_speed_10m: Float
        let wind_direction_10m: Float
        let weather_code: Float
    }
    
    func toDomain() -> WeatherData? {
        let weather = Weather(from: Int(current.weather_code))
        return WeatherData(
            weather: weather,
            temperature: current.temperature_2m,
            apparentTemperature: current.apparent_temperature,
            windSpeed10m: current.wind_speed_10m,
            windDirection10m: current.wind_direction_10m
        )
    }
}
