import Foundation
import CoreLocation
import ComposableArchitecture

struct LocationServiceClient {
    var requestWhenInUserAuthorization:@MainActor @Sendable  () -> Void
    var locationUpdates: @MainActor @Sendable () -> AsyncStream<LocationUpdate>
}

struct LocationUpdate: Sendable {
    let coordinate: CLLocationCoordinate2D
    let heading: CLLocationDirection?
}

extension LocationServiceClient: DependencyKey {
    static let liveValue: Self = {
        Self(
            requestWhenInUserAuthorization:  {
                let holder = CLLocationManagerHolder.shared
                let manager = holder.manager
                manager.requestWhenInUseAuthorization()
            },
            locationUpdates: {
                AsyncStream { continuation in
                    let holder = CLLocationManagerHolder.shared
                    let manager = holder.manager
                    let delegate = LocationManagerDelegateProxy(
                        didUpdateLocation: { locationUpdate in
                            continuation.yield(locationUpdate)
                        },
                        didFinish: {
                            continuation.finish()
                        }
                    )
                    holder.delegate = delegate
                    manager.delegate = delegate
                    
                    switch manager.authorizationStatus {
                    case .notDetermined:
                        manager.requestWhenInUseAuthorization()
                    case .authorizedAlways, .authorizedWhenInUse:
                        manager.startUpdatingLocation()
                        if CLLocationManager.headingAvailable() {
                            manager.startUpdatingHeading()
                        }
                    case .denied, .restricted:
                        break
                    @unknown default:
                        continuation.finish()
                    }
                    
                    continuation.onTermination = { _ in
                        manager.stopUpdatingLocation()
                        manager.stopUpdatingHeading()
                    }
                }
            }
        )
    }()
}

extension DependencyValues {
    var locationServiceClient: LocationServiceClient {
        get { self[LocationServiceClient.self] }
        set { self[LocationServiceClient.self] = newValue }
    }
}

@MainActor
private final class CLLocationManagerHolder {
    static let shared = CLLocationManagerHolder()
    
    let manager = CLLocationManager()
    var delegate: LocationManagerDelegateProxy?
}

private final class LocationManagerDelegateProxy: NSObject, CLLocationManagerDelegate {
    private let didUpdateLocation: (LocationUpdate) -> Void
    private let didFinish: () -> Void
    
    private var latestCoordinate: CLLocationCoordinate2D?
    private var latestHeading: CLLocationDirection?
    
    init(
        didUpdateLocation: @escaping (LocationUpdate) -> Void,
        didFinish: @escaping () -> Void
    ) {
        self.didUpdateLocation = didUpdateLocation
        self.didFinish = didFinish
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
        case .denied, .restricted:
            manager.stopUpdatingLocation()
            manager.stopUpdatingHeading()
            didFinish()
        case .notDetermined:
            break
        @unknown default:
            didFinish()
        }
    }
    
    func locationManager(_ merger: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        latestCoordinate = coordinate
        emitIfPossible()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }

        let heading = newHeading.trueHeading >= 0
                ? newHeading.trueHeading
                : newHeading.magneticHeading
        latestHeading = heading
        emitIfPossible()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        didFinish()
    }
    
    private func emitIfPossible() {
        guard let latestCoordinate else { return }
        didUpdateLocation(
            LocationUpdate(coordinate: latestCoordinate, heading: latestHeading)
        )
    }
}
