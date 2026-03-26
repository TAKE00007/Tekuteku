import SwiftUI
import Combine
import ComposableArchitecture
import MapKit
import CoreLocation

struct HomeView: View {
    let store: StoreOf<HomeFeature>
    @State var position: MapCameraPosition = .automatic
    @StateObject private var locationManager = LocationManager()
    @Namespace var mapScope

    var coursePolyline: MKPolyline? {
        guard let course = store.course, course.route.count >=  2 else {
            return nil
        }
        return course.route.mkPolyline
    }
    
    var body: some View {
        ZStack {
            Map(position: $position, scope: mapScope) {
                if let coursePolyline {
                    MapPolyline(coursePolyline)
                        .stroke(.blue, lineWidth: 5)
                }
            }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls({
                    // 標準の方を消す必要がある
                    MapCompass(scope: mapScope)
                        .mapControlVisibility(.hidden)
                })
                .overlay(alignment: .bottomTrailing) {
                    VStack {
                        MapCompass(scope: mapScope)
                            .mapControlVisibility(.visible)
                        VStack(spacing: 8) {
                            Button {
                                print( "" )
                            } label: {
                                Image(systemName: "map.fill")
                                    .foregroundStyle(.black)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                            }
                            
                            Button {
                                position = .userLocation(followsHeading: false, fallback: .automatic)
                            } label: {
                                Image(systemName: "location.fill")
                                    .foregroundStyle(.blue)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        
                        Button {
                            store.send(.tapWalking)
                        } label: {
                            Image(systemName: "figure.walk")
                                .foregroundStyle(.black)
                                .font(.title2)
                                .padding(10)
                                .background(.thickMaterial, in: Circle())
                        }
                        
                    }
                    .padding( .trailing, 10)
                    .buttonBorderShape(.circle)
                }
                .mapScope(mapScope)
                .onChange(of: store.course?.id) { _, _ in
                    guard let coursePolyline else { return }
                    position = .rect(coursePolyline.boundingMapRect)
                }
        }
        .task {
            locationManager.requestPermission()
            locationManager.startUpdatingLocation()
            store.send(.onAppear)
        }
        .onReceive(locationManager.$currentLocation.compactMap { $0 } ) { location in
            store.send(.currentLocationUpdated(location))
            if position == .automatic {
                position = .userLocation(followsHeading: false, fallback: .automatic)
            }
        }
        .sheet(
            isPresented: Binding(
                get: { store.isWalkingSheetPresented },
                set: { store.send(.setWalkingSheet(isPresented: $0)) }
            )) {
                SliderView(store: store.scope(state: \.slider, action: \.slider))
                .presentationDetents([.fraction(0.25), .medium])
            }
    }
}

#Preview {
    HomeView(store: Store(initialState: HomeFeature.State(), reducer: {
        HomeFeature()
    }))
}
