import SwiftUI

struct SampleGeometoryReader: View {
    var body: some View {
        VStack {
            Text("Hello World!")
        }
        .frame(width: 120, height: 120)
        .background(StrickyNoteView())
    }
}

#Preview {
    SampleGeometoryReader()
}


struct StrickyNoteView: View {
    var color: Color = .green
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    let w = geometry.size.width
                    let h = geometry.size.height
                    let m = min(w/5, h/5)
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.addLine(to: CGPoint(x: w-m, y: h))
                    path.addLine(to: CGPoint(x: w, y: h-m))
                    path.addLine(to: CGPoint(x: w, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                }
                .fill(self.color)
                Path { path in
                    let w = geometry.size.width
                    let h = geometry.size.height
                    let m = min(w/5, h/5)
                    path.move(to: CGPoint(x: w-m, y: h))
                    path.addLine(to: CGPoint(x: w-m, y: h-m))
                    path.addLine(to: CGPoint(x: w, y: h-m))
                    path.addLine(to: CGPoint(x: w-m, y: h))
                }
                .fill(Color.black).opacity(0.4)
            }
        }
    }
}

struct GeometryReaderView: View {
    let halfScreenWidth = UIScreen.main.bounds.width / 2
    let magnification: CGFloat = 1.8
    var body: some View {
        ScrollView( .horizontal, showsIndicators: false) {
            HStack {
                ForEach((0...10), id: \.self) { _ in
                    GeometryReader { geometry in
                        Circle()
                            .frame(width: 100, height: 100)
                            .foregroundStyle(Color.red)
                            .scaleEffect(max(1,-abs(self.magnification / self.halfScreenWidth * (geometry.frame(in: .global).midX - self.halfScreenWidth)) + self.magnification))
                    }
                    .frame(width: 100, height: self.magnification * 100)
                    .padding()
                }
            }
        }
    }
}

#Preview {
    GeometryReaderView()
}
