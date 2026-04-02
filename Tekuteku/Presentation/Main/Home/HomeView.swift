import SwiftUI
import ComposableArchitecture
import MapKit

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    @Namespace var mapScope
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $store.position, scope: mapScope) {
                if let coursePolyline = store.course?.route.mkPolyline {
                    MapPolyline(coursePolyline)
                        .stroke(.blue, lineWidth: 5)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                // 標準の方を消す必要がある
                MapCompass(scope: mapScope)
                    .mapControlVisibility(.hidden)
            }
            .mapScope(mapScope)
            .onChange(of: store.course?.id) { _, _ in
                guard let coursePolyline = store.course?.route.mkPolyline else { return }
                store.send(.updatePosition(.rect(coursePolyline.boundingMapRect)))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            switch store.displayState {
            case .normal:
                flootingButtons
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .preview:
                if let course = store.course {
                    FooterView(course: course, confirmAction: { store.send(.tapConfirm) }, unconfirmAction: { store.send(.tapUnConfirm) })
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
        .animation(.easeInOut(duration: 0.25), value: store.displayState)
    }
    
    
    private var flootingButtons: some View {
        VStack {
            MapCompass(scope: mapScope)
                .mapControlVisibility(.visible)
            VStack(spacing: 8) {
                Button {
                    print( "" ) //TODO: 地図の種類の選択をできるようにする
                } label: {
                    Image(systemName: "map.fill")
                        .foregroundStyle(.black)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                
                Button {
                    store.send(.updatePosition(.userLocation(followsHeading: false, fallback: .automatic)))
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

struct ConfirmFooterView: View {
    let course: WalkingCourse
    let cancelAction: () -> Void
    
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
            
            PrimaryButton(title: "経路を終了", variant: .cancel, action: cancelAction)
        }
        .padding(16)
        .background(.white)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}


#Preview {
    HomeView(store: Store(initialState: HomeFeature.State(), reducer: {
        HomeFeature()
    }))
}
