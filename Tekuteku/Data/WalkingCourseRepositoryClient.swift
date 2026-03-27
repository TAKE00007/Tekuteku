import Dependencies
import Foundation
import MapKit

struct WalkingCourseRepositoryClient: Sendable {
    var createCourse: @Sendable (CourseRequest) async throws -> WalkingCourse
}

extension WalkingCourseRepositoryClient: DependencyKey {
    static let liveValue: Self = .live
    
    static let testValue: Self = .init(
        createCourse: { request in
            switch request {
            case let .byDistance(start, distance):
                return WalkingCourse(
                    id: UUID(),
                    route: [start],
                    distance: distance,
                    expectedMinutes: Int(distance / 4000) // 歩く速度を時速4kmとする
                )
            }
        }
    )
}

extension DependencyValues {
    var walkingCourseRepository: WalkingCourseRepositoryClient {
        get { self[WalkingCourseRepositoryClient.self] }
        set { self[WalkingCourseRepositoryClient.self] = newValue }
    }
}

extension WalkingCourseRepositoryClient {
    static let live = Self(
        createCourse: { request in
            switch request {
            case let .byDistance(start, distance):
                return try await WalkingRouteBuilder.makeWalkingCourse(from: start.clLocationCoordinate2D, distanceMeters: distance)
            }
        }
    )
}

enum WalkingRouteBuilder {
    static func makeWalkingCourse(
        from start: CLLocationCoordinate2D,
        distanceMeters: Double
    ) async throws -> WalkingCourse {
        let bearingDegreesList: [Double] = [0.0, 270.0]
        let scales: [Double] = [0.7, 0.8]
        
        var bestRoutes: [MKRoute] = []
        var bestDiff = Double.greatestFiniteMagnitude
        
        for scale in scales {
            let edgeDistance = (distanceMeters * scale) / 4
            
            for bearingDegree in bearingDegreesList {
                let firstPoint = fetchPoint(from: start, distanceMeters: edgeDistance, bearingDegrees: bearingDegree)
                let secondPoint = fetchPoint(from: firstPoint, distanceMeters: edgeDistance, bearingDegrees: bearingDegree + 90)
                let thirdPoint = fetchPoint(from: secondPoint, distanceMeters: edgeDistance, bearingDegrees: bearingDegree + 180)
                
                do {
                    async let firstRoute = fetchWalkingRoute(from: start, to: firstPoint)
                    async let secondRoute = fetchWalkingRoute(from: firstPoint, to: secondPoint)
                    async let thirdRoute = fetchWalkingRoute(from: secondPoint, to: thirdPoint)
                    async let finalRoute = fetchWalkingRoute(from: thirdPoint, to: start)
                    
                    let routes = try await [firstRoute, secondRoute, thirdRoute, finalRoute]
                    let totalDistance = routes.map(\.distance).reduce(0, +)
                    let diff = abs(totalDistance - distanceMeters)
                    
                    if diff < bestDiff {
                        bestDiff = diff
                        bestRoutes = routes
                    }
                } catch let error as WalkingCourseError{
                    throw error
                } catch {
                    throw WalkingCourseError.mapKitError(error.localizedDescription)
                }
            }
        }
        
        guard !bestRoutes.isEmpty else {
            throw WalkingCourseError.routeNotFound
        }
        
        let mergedRoute = mergeRoutes(bestRoutes)
        let totalDistance = bestRoutes.map(\.distance).reduce(0, +)
        let expectedMinutes = max(1, Int((totalDistance) / 4_000) * 60)
        
        return WalkingCourse(
            id: UUID(),
            route: mergedRoute,
            distance: totalDistance,
            expectedMinutes: expectedMinutes
        )
    }
    
    static func mergeRoutes(_ routes: [MKRoute]) -> [Coordinate] {
        routes.enumerated().flatMap { index, route in
            let coordinates = route.polyline.domainCoordinates
            if index == 0 {
                return coordinates
            } else {
                // コースの最後の地点と次のコースの最初の地点で重複するため
                return Array(coordinates.dropFirst())
            }
        }
    }
    
    static func fetchPoint(
        from start: CLLocationCoordinate2D,
        distanceMeters: Double,
        bearingDegrees: Double
    ) -> CLLocationCoordinate2D {
        let earthRadius = 6_371_000.0
        let bearing = bearingDegrees * .pi / 180
        let lat1 = start.latitude * .pi / 180
        let lon1 = start.longitude * .pi / 180
        
        let angularDistance = distanceMeters / earthRadius
        
        let lat2 = asin(
            sin(lat1) * cos(angularDistance) +
            cos(lat1) * sin(angularDistance) * cos(bearing)
        )
        
        let lon2 = lon1 + atan2(
            sin(bearing) * sin(angularDistance) * cos(lat1),
            cos(angularDistance) - sin(lat1) * sin(lat2)
        )
        
        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi, longitude: lon2 * 180 / .pi)
    }
    
    static func fetchWalkingRoute(
        from start: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(
            location: CLLocation(latitude: start.latitude, longitude: start.longitude),
            address: nil
        )
        request.destination = MKMapItem(
            location: CLLocation(latitude: destination.latitude, longitude: destination.longitude),
            address: nil
        )
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard let route = response.routes.first else {
            throw WalkingCourseError.routeNotFound
        }
        
        return route
    }
    
}
