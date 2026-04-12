import Foundation
import MapKit

struct WalkingCourse: Equatable, Sendable {
    let id: UUID
    let route: [Coordinate]
    let stepCount: Int
    let distance: Double
    let expectedMinutes: Int
    let calories: Int
}

enum CourseRequest: Equatable, Sendable {
    case byDistance(start: Coordinate, distance: Double)
}

extension CLLocationCoordinate2D {
    var domain: Coordinate {
        Coordinate(latitude: latitude, longitude: longitude)
    }
}

extension MKPolyline {
    var domainCoordinates: [Coordinate] {
        var coords = Array(
            repeating: CLLocationCoordinate2D(),
            count: pointCount
        )
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords.map { $0.domain }
    }
}

extension Coordinate {
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum WalkingCourseError: Error, Equatable {
    case routeNotFound
    case mapKitError(String)
    case unknown
    
    var message: String {
        switch self {
        case .routeNotFound:
            return "コースが見つかりません"
        case .mapKitError(let error):
            return "mapKitのエラーが出ました: \(error)"
        case .unknown:
            return "不明なエラーです"
        }
    }
}
