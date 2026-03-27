import Foundation
import Dependencies

struct WalkingCourseServiceClient: Sendable {
    var createCourse: @MainActor @Sendable (CourseRequest) async throws -> WalkingCourse
}

extension WalkingCourseServiceClient: DependencyKey {
    static let liveValue: Self = .live
    
    static let testValue: Self = .init(
        createCourse: { request in
            @Dependency(\.walkingCourseRepository) var repository
            return try await repository.createCourse(request)
        }
    )
}

extension DependencyValues {
    var walkingCourseService: WalkingCourseServiceClient {
        get { self[WalkingCourseServiceClient.self] }
        set { self[WalkingCourseServiceClient.self] = newValue }
    }
}

extension WalkingCourseServiceClient {
    static let live: Self = .init(
        createCourse: { request in
            @Dependency(\.walkingCourseRepository) var repository
            
            let course = try await repository.createCourse(request)
            
            guard !course.route.isEmpty else {
                throw WalkingCourseError.routeNotFound
            }
            
            return course
        }
    )
}
