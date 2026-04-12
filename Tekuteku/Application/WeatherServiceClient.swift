import Foundation
import Dependencies

struct WeatherServiceClient: Sendable {
    var fetchWeatherData: @MainActor @Sendable (Coordinate) async throws -> WeatherData
}

extension WeatherServiceClient: DependencyKey {
    static let liveValue: Self = .live

    static let testValue: Self = .init(
        fetchWeatherData: { _ in
            return WeatherData(
                weather: .sunny,
                temperature: 18.5,
                apparentTemperature: 20.0,
                windSpeed: 10,
                windDirection: 180.0
            )
        }
    )
}

extension DependencyValues {
    var weatherServiceClient: WeatherServiceClient {
        get { self[WeatherServiceClient.self] }
        set { self[WeatherServiceClient.self] = newValue }
    }
}

extension WeatherServiceClient {
    static let live: Self = .init(
        fetchWeatherData: { coordinate in
            @Dependency(\.weatherRepository) var repository
            let weatherData = try await repository.fetchWeatherData(coordinate)
            return weatherData
        }
    )
}
