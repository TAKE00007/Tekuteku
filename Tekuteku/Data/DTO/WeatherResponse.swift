import Foundation

struct WeatherResponse: Decodable, Sendable {
    let current: Current
    
    enum CodingKeys: String, CodingKey {
        case current
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.current = try container.decode(Current.self, forKey: .current)
    }
    
    struct Current: Decodable, Sendable {
        let temperature2m: Float
        let apparentTemperature: Float
        let windSpeed10m: Float
        let windDirection10m: Float
        let weatherCode: Float
        
        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case apparentTemperature = "apparent_temperature"
            case windSpeed10m = "wind_speed_10m"
            case windDirection10m = "wind_direction_10m"
            case weatherCode = "weather_code"
        }
        
        nonisolated init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.temperature2m = try container.decode(Float.self, forKey: .temperature2m)
            self.apparentTemperature = try container.decode(Float.self, forKey: .apparentTemperature)
            self.windSpeed10m = try container.decode(Float.self, forKey: .windSpeed10m)
            self.windDirection10m = try container.decode(Float.self, forKey: .windDirection10m)
            self.weatherCode = try container.decode(Float.self, forKey: .weatherCode)
        }
    }
    
    nonisolated func toDomain() -> WeatherData {
        let weather = Weather(from: Int(current.weatherCode))
        return WeatherData(
            weather: weather,
            temperature: current.temperature2m,
            apparentTemperature: current.apparentTemperature,
            windSpeed: current.windSpeed10m,
            windDirection: current.windDirection10m
        )
    }
}
