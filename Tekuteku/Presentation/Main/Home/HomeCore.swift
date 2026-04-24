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
        var isFollowingUser: Bool = false
        let cameraDistance: Double = 1_000
        var selectedCourseID: UUID? = nil

        var courses: [WalkingCourse]?
        var course: WalkingCourse?
        var currentLocation: Coordinate?
        var weatherData: WeatherData?
        var errorMessage: String?
        
        var isWalkingSheetPresented = false
        var isMapChangeSheetPreseted = false

        var slider = SliderFeature.State()
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
        case updateCourseID(UUID)
        case currentLocationUpdated(LocationUpdate)
        case fetchWeather(Coordinate)
        
        case tapUserLocation
        case tapChangeMap
        case tapWalking
        case tapConfirm
        case tapUnConfirm
        case tapCancel
        case changeMapStyle(MapStyleOption)

        case courseResponse(Result<[WalkingCourse], WalkingCourseError>)
        case weatherResponse(Result<WeatherData, WeatherError>)
        
        case setWalkingSheet(isPresented: Bool)
        case slider(SliderFeature.Action)
    }
    @Dependency(\.walkingCourseService) var walkingCourseService
    @Dependency(\.locationServiceClient) var locationService
    @Dependency(\.weatherServiceClient) var weatherService
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Scope(state: \.slider, action: \.slider) {
            SliderFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .binding(\.position):
                if state.displayState == .confirm,
                   state.isFollowingUser,
                   state.position.positionedByUser {
                    state.isFollowingUser = false
                }
                return .none
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
            case .updatePosition(let position):
                state.position = position
                return .none
            case .updateCourseID(let id):
                if let courses = state.courses {
                    state.course = courses.first { $0.id == id }
                }
                state.selectedCourseID = id
                return .none
            case .currentLocationUpdated(let locationUpdate):
                let coordinate = locationUpdate.coordinate.domain
                state.currentLocation = coordinate
                if state.position == .automatic {
                    state.position = .userLocation(followsHeading: false, fallback: .automatic)
                }
                if state.isFollowingUser {
                    state.position = .camera(MapCamera(centerCoordinate: locationUpdate.coordinate, distance: state.cameraDistance))
                }
                return .run { send in
                    await send(.fetchWeather(coordinate))
                }
            case .fetchWeather(let coordinate):
                return .run { send in
                    do {
                        let weatherData = try await weatherService.fetchWeatherData(coordinate)
                        await send(.weatherResponse(.success(weatherData)))
                    } catch let error as WeatherError {
                        await send(.weatherResponse(.failure(error)))
                    } catch {
                        await send(.weatherResponse(.failure(WeatherError.unknown)))
                    }
                }

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
                state.courses = nil
                state.course = nil
                state.isWalkingSheetPresented = true
                state.displayState = .normal
                return .run { send in
                    await send(.tapUserLocation)
                }
            case .tapConfirm:
                state.displayState = .confirm
                state.isFollowingUser = true
                return .run { send in
                    await send(.tapUserLocation)
                }
            case .tapCancel:
                state.courses = nil
                state.course = nil
                state.displayState = .normal
                state.isFollowingUser = false
                return .run { send in
                    await send(.tapUserLocation)
                }
            case .changeMapStyle(let mapStyle):
                state.mapStyleOption = mapStyle
                return .none

            case .slider(.tapCreateCourse(let distance)):
                guard let currentLocation = state.currentLocation else {
                    state.errorMessage = "現在地を取得できていません"
                    return .none
                }
                return .run { send in
                    do {
                        let courses = try await walkingCourseService.createCourse(.byDistance(start: currentLocation, distance: distance)
                        )
                        await send(.courseResponse(.success(courses)))
                    } catch let error as WalkingCourseError {
                        await send(.courseResponse(.failure(error)))
                    } catch {
                        await send(.courseResponse(.failure(.unknown)))
                    }
                }

            case .courseResponse(let result):
                switch result {
                case .success(let courses):
                    state.courses = courses
                    state.course = courses.first
                    state.selectedCourseID = courses.first?.id
                    state.displayState = .preview
                    state.isWalkingSheetPresented = false
                    return .none
                case .failure(let error):
                    state.errorMessage = error.message
                    return .none
                }
            case .weatherResponse(let result):
                switch result {
                case .success(let weatherData):
                    state.weatherData = weatherData
                    return .none
                case .failure(let error):
                    state.errorMessage = error.message
                    return .none
                }

            case .setWalkingSheet(let isPresented):
                state.isWalkingSheetPresented = isPresented
                return .none
            case .slider:
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
