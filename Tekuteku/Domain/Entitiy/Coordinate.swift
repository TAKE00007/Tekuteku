import Foundation

struct Coordinate: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
}

extension Coordinate {
    nonisolated func distance(to other: Coordinate) -> Double {
        let earthRadius = 6_371_000.0

        let lat1 = latitude * .pi / 180
        let lon1 = longitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let lon2 = other.longitude * .pi / 180

        let dLat = lat2 - lat1
        let dLon = lon2 - lon1

        let a =
            sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1) * cos(lat2) *
            sin(dLon / 2) * sin(dLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }
}
