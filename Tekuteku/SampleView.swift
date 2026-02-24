import SwiftUI
import MapKit

struct SampleView: View {
    
    @State private var position: MapCameraPosition = .automatic
    @State private var route: MKRoute?
    
    let start = CLLocationCoordinate2D(
        latitude: 35.681236,
        longitude: 139.767125
    )
    
    let goal = CLLocationCoordinate2D(
        latitude: 35.6895,
        longitude: 139.6917
    )
    
    var body: some View {
        Map(position: $position) {
            Marker("Start", coordinate: start)
            Marker("Goal", coordinate: goal)
            
            if let routePolyline = route?.polyline {
                MapPolyline(routePolyline)
                    .stroke(.blue, lineWidth: 6)
            }
        }
        .task {
            await fetchRoute(from: start, to: goal)
        }
    }
    
    func fetchRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async {
        let request = MKDirections.Request()
        request.source = MKMapItem(
            location: CLLocation(latitude: from.latitude, longitude: from.longitude),
            address: nil
        )
        request.destination = MKMapItem(
            location: CLLocation(latitude: to.latitude, longitude: to.longitude),
            address: nil
        )
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        
        do {
            let response = try await directions.calculate()
            route = response.routes.first
        } catch {
            print(error)
        }
    }
}

#Preview {
    SampleView()
}
