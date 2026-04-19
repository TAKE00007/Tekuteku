import Dependencies
import Foundation
import MapKit

struct WalkingCourseRepositoryClient: Sendable {
    var createCourse: @Sendable (CourseRequest) async throws -> [WalkingCourse]
}

extension WalkingCourseRepositoryClient: DependencyKey {
    static let liveValue: Self = .live
    
    static let testValue: Self = .init(
        createCourse: { request in
            switch request {
            case let .byDistance(start, distance):
                let courseDistance = distance / 1_000
                return [WalkingCourse(
                    id: UUID(),
                    route: [start],
                    stepCount: 5000,
                    distance: courseDistance,
                    expectedMinutes: Int(courseDistance / 4000), // 歩く速度を時速4kmとする
                    calories: 135,
                )]
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
                return try await WalkingRouteBuilder.makeWalkingCourses(from: start.clLocationCoordinate2D, distanceMeters: distance)
            }
        }
    )
}

enum WalkingRouteBuilder {
    static func makeWalkingCourses(
        from start: CLLocationCoordinate2D,
        distanceMeters: Double
    ) async throws -> [WalkingCourse] {
        let bearingDegreesList: [Double] = [0.0, 90.0, 180.0, 270.0] // スタートする方向
        let scale: Double = 0.7 // 1km先の地点でも歩くと長くなるので、短めにして補正する
        
        var walkingCourses: [WalkingCourse] = []
        
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
                
                let mergeRoute = mergeRoutes(routes)
                let totalDistance = routes.map(\.distance).reduce(0, +) / 1_000
                let expectedMinutes = max(1, Int((totalDistance) / 4) * 60)
                let stepCount = totalDistance * 1_000 / 0.7 // 1歩0.7m
                let calories = stepCount * 0.04 // 1歩0.04kcal
                
                let walkingCourse = WalkingCourse(
                    id: UUID(),
                    route: mergeRoute,
                    stepCount: Int(stepCount),
                    distance: totalDistance,
                    expectedMinutes: expectedMinutes,
                    calories: Int(calories)
                )
                
                walkingCourses.append(walkingCourse)
            } catch let error as WalkingCourseError{
                throw error
            } catch {
                throw WalkingCourseError.mapKitError(error.localizedDescription)
            }
        }

        guard !walkingCourses.isEmpty else {
            throw WalkingCourseError.routeNotFound
        }
        
        let sortedWalkingCourses = walkingCourses.sorted {
            abs(($0.distance * 1_000) - distanceMeters) < abs(($1.distance * 1_000) - distanceMeters)
        }
        
        return sortedWalkingCourses
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
