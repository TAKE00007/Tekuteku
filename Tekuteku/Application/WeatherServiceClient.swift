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
    static let live: Self = {
        let cache = WeatherCache()

        return .init(
            fetchWeatherData: { coordinate in
                @Dependency(\.weatherRepository) var repository
                
                let now = Date()
                
                if let weatherCache = await cache.cacheValid(now: now, expiration: 60 * 60) {
                    return weatherCache
                }
                
                let weatherData = try await repository.fetchWeatherData(coordinate)
                await cache.save(fetchedAt: now, weatherData: weatherData)

                return weatherData
            }
        )
    }()
}

private actor WeatherCache {
    private var lastFetchedAt: Date?
    private var weatherData: WeatherData?
    
    func cacheValid(now: Date, expiration: TimeInterval) -> WeatherData? {
        guard let lastFetchedAt, let weatherData else { return nil }
        
        if now.timeIntervalSince(lastFetchedAt) < expiration {
            return weatherData
        } else {
            return nil
        }
    }
    
    func save(fetchedAt: Date, weatherData: WeatherData) {
        self.lastFetchedAt = fetchedAt
        self.weatherData = weatherData
    }
}
