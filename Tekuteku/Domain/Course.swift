import Foundation

struct Course {
    let id: UUID
    let name: String
    let route: String  // encoded polyline
    let expectedSteps: Int
    let expectedMinutes: Int
    let distanceMeters: Int
    let startRegion: String
    let createdAt: Date
}
