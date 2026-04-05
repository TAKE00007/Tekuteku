import SwiftUI
import ComposableArchitecture
import MapKit

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var mapStyleOption: MapStyleOption = .standard
        var displayState: DisplayState = .normal
        var position: MapCameraPosition = .automatic
        var course: WalkingCourse?
        var currentLocation: Coordinate?
        var isWalkingSheetPresented = false
        var isMapChangeSheetPreseted = false
        var slider = SliderFeature.State()
        var errorMessage: String?
        let cameraDistance: Double = 1_000
    }
    
    enum DisplayState: Equatable {
        case normal
        case preview
        case confirm
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case locationTask
        case updatePosition(MapCameraPosition)
        case tapUserLocation
        case tapChangeMap
        case tapWalking
        case tapConfirm
        case tapUnConfirm
        case tapCancel
        case changeMapStyle(MapStyleOption)
        case currentLocationUpdated(CLLocationCoordinate2D)
        case courseResponse(Result<WalkingCourse, WalkingCourseError>)
        case setWalkingSheet(isPresented: Bool)
        case slider(SliderFeature.Action)
    }
    @Dependency(\.walkingCourseService) var walkingCourseService
    @Dependency(\.locationServiceClient) var locationService
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Scope(state: \.slider, action: \.slider) {
            SliderFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .onAppear:
                return .run { send in
                    await locationService.requestWhenInUserAuthorization()
                    await send(.locationTask)
                }
            case .locationTask:
                return .run { send in
                    for await location in await locationService.locationUpdates() {
                        await send(.currentLocationUpdated(location))
                    }
                }
                .cancellable(id: "locationUpdates", cancelInFlight: true)
            case .tapUserLocation:
                guard let centerCoordinate = state.currentLocation?.clLocationCoordinate2D else { return .none }
                let camera = MapCamera(centerCoordinate: centerCoordinate, distance: state.cameraDistance)
                return .run { send in
                    await send(.updatePosition(.camera(camera)))
                }
            case .tapChangeMap:
                state.isMapChangeSheetPreseted = true
                return .none
            case .tapWalking:
                state.isWalkingSheetPresented = true
                return .none
            case .tapUnConfirm:
                state.course = nil
                state.isWalkingSheetPresented = true
                state.displayState = .normal
                return .run { send in
                    await send(.tapUserLocation)
                }
            case .tapConfirm:
                state.displayState = .confirm
                return .run { send in
                    await send(.tapUserLocation)
                }
            case .tapCancel:
                state.course = nil
                state.displayState = .normal
                return .run { send in
                    await send(.tapUserLocation)
                }
            case .changeMapStyle(let mapStyle):
                state.mapStyleOption = mapStyle
                return .none
            case .currentLocationUpdated(let location):
                state.currentLocation = location.domain
                if state.position == .automatic {
                    state.position = .userLocation(followsHeading: false, fallback: .automatic)
                }
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
            case .courseResponse(let result):
                switch result {
                case .success(let course):
                    state.course = course
                    state.displayState = .preview
                    state.isWalkingSheetPresented = false
                    return .none
                case .failure(let error):
                    state.errorMessage = error.message
                    return .none
                }
            case .updatePosition(let position):
                state.position = position
                return .none
            }
        }
    }
}


extension Array where Element == Coordinate {
    var mkPolyline: MKPolyline {
        MKPolyline(coordinates: self.map(\.clLocationCoordinate2D), count: self.count)
    }
}
