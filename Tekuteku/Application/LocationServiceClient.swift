import Foundation
import CoreLocation
import ComposableArchitecture

struct LocationServiceClient {
    var requestWhenInUserAuthorization:@MainActor @Sendable  () -> Void
    var locationUpdates: @MainActor @Sendable () -> AsyncStream<CLLocationCoordinate2D>
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
                        didUpdateLocation: { coordinate in
                            continuation.yield(coordinate)
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
                    case .denied, .restricted:
                        break
                    @unknown default:
                        continuation.finish()
                    }
                    
                    continuation.onTermination = { _ in
                        manager.stopUpdatingLocation()
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
    private let didUpdateLocation: (CLLocationCoordinate2D) -> Void
    private let didFinish: () -> Void
    
    init(
        didUpdateLocation: @escaping (CLLocationCoordinate2D) -> Void,
        didFinish: @escaping () -> Void
    ) {
        self.didUpdateLocation = didUpdateLocation
        self.didFinish = didFinish
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            manager.stopUpdatingLocation()
        case .notDetermined:
            break
        @unknown default:
            didFinish()
        }
    }
    
    func locationManager(_ merger: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        didUpdateLocation(coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        didFinish()
    }
}
