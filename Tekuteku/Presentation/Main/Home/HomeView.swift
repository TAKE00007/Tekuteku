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
    
    var body: some View {
        ZStack {
            Map(position: $position, scope: mapScope)
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
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        
                        Button {
                            store.send(.tapWalking)
                        } label: {
                            Image(systemName: "figure.walk")
                                .foregroundStyle(.black)
                                .font(.title2)
                                .padding(10)
                                .background(.thinMaterial, in: Circle())
                        }
                        
                    }
                    .padding( .trailing, 10)
                    .buttonBorderShape(.circle)
                }
                .mapScope(mapScope)
        }
        .task {
            locationManager.requestPermission()
            store.send(.onAppear)
        }
        .sheet(
            isPresented: Binding(
                get: { store.isWalkingSheetPresented },
                set: { store.send(.setWalkingSheet(isPresented: $0)) }
            )) {
                VStack {
                    Text("散歩ルート作成")
                }
                .presentationDetents([.fraction(0.25), .medium])
            }
    }
}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    
}

#Preview {
    HomeView(store: Store(initialState: HomeFeature.State(), reducer: {
        HomeFeature()
    }))
}
