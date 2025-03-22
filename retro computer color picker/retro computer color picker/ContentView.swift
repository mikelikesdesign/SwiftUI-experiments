import SwiftUI

struct ContentView: View {
    @State private var selectedColor: Color = .white

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea(.all)

                VStack {
                    Text("Customize Color")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 16)

                    Image("computer")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .overlay(
                            Rectangle()
                                .fill(selectedColor)
                                .frame(width: 270, height: 240)
                                .cornerRadius(8)
                                .offset(y: -24)
                        )
                        .clipped()

                    Spacer().frame(height: 16)

                    SpectrumColorPicker(selectedColor: $selectedColor)
                        .frame(width: 250, height: 240)
                        .clipShape(Circle())
                        .padding(.top, 8)

                    Spacer()
                }
            }
        }
        .navigationBarTitle("", displayMode: .inline)
    }
}

struct SpectrumColorPicker: View {
    @Binding var selectedColor: Color
    @State private var indicatorPosition: CGPoint = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(AngularGradient(gradient: Gradient(colors: Color.hueColors), center: .center))
                    .contentShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let point = value.location
                                let adjustedPoint = adjustPointToCircleBounds(point: point, in: geometry.size)
                                selectedColor = getColor(at: adjustedPoint, in: geometry.size)
                                indicatorPosition = adjustedPoint
                            }
                    )
                
                // Color indicator
                Circle()
                    .fill(selectedColor)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .overlay(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.3)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 6, x: 0, y: 3)
                    .position(indicatorPosition)
                    .opacity(indicatorPosition == .zero ? 0 : 1)
            }
            .onAppear {
                // Set initial indicator position at center
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                indicatorPosition = center
            }
        }
    }

    private func adjustPointToCircleBounds(point: CGPoint, in size: CGSize) -> CGPoint {
        let radius = size.width / 2
        let center = CGPoint(x: radius, y: radius)
        let deltaX = point.x - center.x
        let deltaY = point.y - center.y
        let distance = sqrt(pow(deltaX, 2) + pow(deltaY, 2))
        if distance > radius {
            let angle = atan2(deltaY, deltaX)
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            return CGPoint(x: x, y: y)
        }
        return point
    }

    private func getColor(at point: CGPoint, in size: CGSize) -> Color {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let deltaX = point.x - center.x
        let deltaY = point.y - center.y
        let angle = atan2(deltaY, deltaX)
        let hue = (angle >= 0 ? angle : (2 * .pi + angle)) / (2 * .pi)
        return Color(hue: hue, saturation: 1, brightness: 1)
    }
}

extension Color {
    static var hueColors: [Color] {
        (0...360).map {
            Color(hue: Double($0) / 360.0, saturation: 1, brightness: 1)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
