import SwiftUI

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
                MapKindView(image: .standardMap, mapStyle: .standard, selectedMapStyle: selectedMapStyle, onSelect: { onSelect($0) })
                MapKindView(image: .hybridMap, mapStyle: .hybrid, selectedMapStyle: selectedMapStyle, onSelect: { onSelect($0) })
            }
        }
    }
}

#Preview {
    MapKindSelectView(selectedMapStyle: .standard, onSelect: {_ in })
}

private struct MapKindView: View {
    let image: ImageResource
    let mapStyle: MapStyleOption
    let selectedMapStyle: MapStyleOption
    let onSelect: (MapStyleOption) -> Void
    var body: some View {
        VStack {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(5)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selectedMapStyle == mapStyle ? .blue : .clear, lineWidth: 3)
                }
                .onTapGesture {
                    onSelect(mapStyle)
                }

            Text(mapStyle.name)
        }
    }
}
