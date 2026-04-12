import Foundation
import Dependencies

struct WeatherRepositoryClient: Sendable {
    var fetchWeatherData: @Sendable (Coordinate) async throws -> WeatherData
}

extension WeatherRepositoryClient: DependencyKey {
    static let liveValue: Self = .live
}

extension DependencyValues {
    var weatherRepository: WeatherRepositoryClient {
        get { self[WeatherRepositoryClient.self] }
        set { self[WeatherRepositoryClient.self] = newValue }
    }
}

extension WeatherRepositoryClient {
    static let live = Self { coordinate in
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast?")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(coordinate.latitude)"),
            URLQueryItem(name: "longitude", value: "\(coordinate.longitude)"),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,wind_speed_10m,wind_direction_10m,weather_code")
        ]
        guard let url = components.url else { throw NSError() }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(WeatherResponse.self, from: data)
        guard let weatherData = response.toDomain() else { throw NSError() }
        
        return weatherData
    }
}

