import SwiftUI
import ComposableArchitecture
import MapKit

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    @Namespace var mapScope
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $store.position, scope: mapScope) {
                UserAnnotation()
                
                if let coursePolyline = store.course?.route.mkPolyline {
                    MapPolyline(coursePolyline)
                        .stroke(.blue, lineWidth: 5)
                }
            }
            .mapStyle(store.mapStyleOption.mapStyle)
            .mapControls {
                // 標準の方を消す必要がある
                MapCompass(scope: mapScope)
                    .mapControlVisibility(.hidden)
            }
            .mapScope(mapScope)
            .onChange(of: store.course?.id) { _, _ in
                guard let coursePolyline = store.course?.route.mkPolyline else { return }
                store.send(.updatePosition(.rect(coursePolyline.boundingMapRect.padded(by: 0.15))))
            }
        }
        .overlay(alignment: .topLeading) {
            if let weatherData = store.weatherData {
                let temperature = weatherData.temperature.formatted(.number.precision(.fractionLength(1)))
                HStack {
                    Image(systemName: weatherData.weather.imageName)
                    Text("\(temperature)℃")
                }
                .padding(8)
                .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.leading, 16)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            switch store.displayState {
            case .normal:
                flootingButtons
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .preview:
                if let course = store.course {
                    SelectFooterView(
                        course: course,
                        confirmAction: { store.send(.tapConfirm) },
                        unconfirmAction: { store.send(.tapUnConfirm) }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                EmptyView()
            case .confirm:
                VStack {
                    HStack {
                        Spacer()
                        flootingButtons
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    if let course = store.course {
                        ConfirmFooterView(course: course, cancelAction: { store.send(.tapCancel) })
                    }
                    
                }

            }
        }
        .task {
            store.send(.onAppear)
        }
        .sheet(
            isPresented: $store.isWalkingSheetPresented
        ) {
            SliderView(store: store.scope(state: \.slider, action: \.slider))
                .presentationDetents([.fraction(0.25), .medium])
        }
        .sheet(
            isPresented: $store.isMapChangeSheetPreseted
        ) {
            MapKindSelectView(selectedMapStyle: store.mapStyleOption, onSelect: { store.send(.changeMapStyle($0)) })
            .presentationDetents([.fraction(0.25), .medium])
        }
        .animation(.easeInOut(duration: 0.25), value: store.displayState)
    }
    
    
    private var flootingButtons: some View {
        VStack {
            MapCompass(scope: mapScope)
                .mapControlVisibility(.visible)
            VStack(spacing: 8) {
                Button {
                    store.send(.tapChangeMap)
                } label: {
                    Image(systemName: "map.fill")
                        .foregroundStyle(.black)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                
                Button {
                    store.send(.tapUserLocation)
                } label: {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
            }
            .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            if store.displayState == .normal {
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
            
        }
        .padding( .trailing, 10)
        .buttonBorderShape(.circle)
    }
}

private extension MKMapRect {
    func padded(by ratio: Double) -> MKMapRect {
        let dx = size.width * ratio
        let dy = size.height * ratio
        return insetBy(dx: -dx, dy: -dy)
    }
}

#Preview {
    HomeView(store: Store(initialState: HomeFeature.State(), reducer: {
        HomeFeature()
    }))
}
