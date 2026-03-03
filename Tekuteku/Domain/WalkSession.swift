import Foundation

struct WalkSession {
    let id: UUID
    let startedAt: Date
    let endAt: Date
    let steps: Int
    let distanceMeters: Double
    let durationSec: Int
    let courseId: UUID?
    let route: String?
    let weatherAtStart: String?
    let createdAt: Date
}
