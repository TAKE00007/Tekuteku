import SwiftUI
import ComposableArchitecture

struct MapKindSelectView: View {
    let selectedMapStyle: MapStyleOption
    let onSelect: (MapStyleOption) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("地図モード")
                .font(.title2)
                .bold()
                .padding(.top, 16)
            HStack(spacing: 16) {
                VStack {
                    Image(.standardMap)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(5)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedMapStyle == .standard ? .blue : .clear, lineWidth: 3)
                        }
                        .onTapGesture {
                            onSelect(.standard)
                        }
                    Text("スタンダード")
                }
                VStack {
                    Image(.hybridMap)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(5)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedMapStyle == .hybrid ? .blue : .clear, lineWidth: 3)
                        }
                        .onTapGesture {
                            onSelect(.hybrid)
                        }

                    Text("航空写真")
                }
            }
        }
    }
}

#Preview {
    MapKindSelectView(selectedMapStyle: .standard, onSelect: {_ in })
}
