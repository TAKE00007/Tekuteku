import SwiftUI
import ComposableArchitecture
import CoreLocation
import MapKit
import Combine

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var course: WalkingCourse?
        var currentLocation: Coordinate?
        var isWalkingSheetPresented = false
        var slider = SliderFeature.State()
        var errorMessage: String?
    }
    
    enum Action {
        case onAppear
        case tapWalking
        case currentLocationUpdated(CLLocationCoordinate2D)
        case createByDistancetapped(start: CLLocationCoordinate2D, disstance: Double)
        case courseResponse(Result<WalkingCourse, WalkingCourseError>)
        case setWalkingSheet(isPresented: Bool)
        case slider(SliderFeature.Action)
    }
    
    @Dependency(\.walkingCourseService) var walkingCourseService
    
    var body: some Reducer<State, Action> {
        Scope(state: \.slider, action: \.slider) {
            SliderFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            case .tapWalking:
                state.isWalkingSheetPresented = true
                return .none
            case .currentLocationUpdated(let location):
                state.currentLocation = location.domain
                return .none
            case .setWalkingSheet(let isPresented):
                state.isWalkingSheetPresented = isPresented
                return .none
            case .slider(.tapCreateCourse(let distance)):
                guard let currentLocation = state.currentLocation else {
                    state.errorMessage = "現在地を取得できていません"
                    return .none
                }
                return .run { send in
                    do {
                        let course = try await walkingCourseService.createCourse(.byDistance(start: currentLocation, distance: distance)
                        )
                        await send(.courseResponse(.success(course)))
                    } catch let error as WalkingCourseError {
                        await send(.courseResponse(.failure(error)))
                    } catch {
                        await send(.courseResponse(.failure(.unknown)))
                    }
                }
            case .slider:
                return .none
            case let .createByDistancetapped(start, disstance):
                return .run { send in
                    do {
                        let course = try await walkingCourseService.createCourse(.byDistance(start: start.domain, distance: disstance)
                        )
                        await send(.courseResponse(.success(course)))
                    } catch let error as WalkingCourseError {
                        await send(.courseResponse(.failure(error)))
                    } catch {
                        await send(.courseResponse(.failure(.unknown)))
                    }
                }
            case .courseResponse(let result):
                switch result {
                case .success(let course):
                    state.course = course
                    return .none
                case .failure(let error):
                    state.errorMessage = error.message
                    return .none
                }
            }
        }
    }
}


final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last?.coordinate
    }
}

extension Array where Element == Coordinate {
    var mkPolyline: MKPolyline {
        MKPolyline(coordinates: self.map(\.clLocationCoordinate2D), count: self.count)
    }
}
