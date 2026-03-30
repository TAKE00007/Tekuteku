import SwiftUI
import ComposableArchitecture
import MapKit

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    @Namespace var mapScope
    
    var body: some View {
        Group {
            switch store.displayState {
            case .normal:
                ZStack {
                    Map(position: $store.position, scope: mapScope) {
                        if let coursePolyline = store.course?.route.mkPolyline {
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
                        FlotingButtons(
                            mapScope: mapScope,
                            updatePosition: { store.send(
                                .updatePosition(.userLocation(followsHeading: false, fallback: .automatic)))
                            },
                            tapWalking: { store.send(.tapWalking) })
                    }
                    .mapScope(mapScope)
                    .onChange(of: store.course?.id) { _, _ in
                        guard let coursePolyline = store.course?.route.mkPolyline else { return }
                        store.send(.updatePosition(.rect(coursePolyline.boundingMapRect)))
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
            case .preview:
                ZStack(alignment: .bottom) {
                    Map(position: $store.position, scope: mapScope) {
                        if let coursePolyline = store.course?.route.mkPolyline {
                            MapPolyline(coursePolyline)
                                .stroke(.blue, lineWidth: 5)
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .mapScope(mapScope)
                    .onChange(of: store.course?.id) { _, _ in
                        guard let coursePolyline = store.course?.route.mkPolyline else { return }
                        store.send(.updatePosition(.rect(coursePolyline.boundingMapRect)))
                    }
                    FooterView(course: store.course!, confirmAction: {}, unconfirmAction: {})
                }
                .task {
                    store.send(.onAppear)
                }
            case .confirm:
                EmptyView()
            }
            
        }
    }
}

struct FlotingButtons: View {
    let mapScope: Namespace.ID
    let updatePosition: () -> Void
    let tapWalking: () -> Void
    var body: some View {
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
                    updatePosition()
                } label: {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
            }
            .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            Button {
                tapWalking()
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
}

struct FooterView: View {
    let course: WalkingCourse
    let confirmAction: () -> Void
    let unconfirmAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Text("\(course.stepCount) 歩")
                Text("\(course.expectedMinutes) 分")
                let distance = course.distance.formatted(.number.precision(.fractionLength(1)))
                Text("\(distance) km")
                Text("\(course.calories) kcal")
            }
            .font(.title3)
            .bold()
            .padding()
            
            HStack(spacing: 8) {
                PrimaryButton(title: "再検索する", variant: .outline, action: unconfirmAction)
                PrimaryButton(title: "このコース", variant: .primary, action: confirmAction)
                
            }
        }
        .padding(16)
        .background(.white)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

#Preview {
    HomeView(store: Store(initialState: HomeFeature.State(), reducer: {
        HomeFeature()
    }))
}
