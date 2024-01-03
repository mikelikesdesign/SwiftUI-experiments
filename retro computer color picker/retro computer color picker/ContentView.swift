import SwiftUI

struct ContentView: View {
    @State private var selectedColor: Color = .white

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea(.all) // Ignore safe areas

                VStack {
                    // Header Text
                    Text("Customize Color")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 16)

                    // Computer illustration
                    Image("computer") // Replace with your image name
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .overlay(
                            // Colored rectangle overlaid on the image
                            Rectangle()
                                .fill(selectedColor)
                                .frame(width: 270, height: 240) // Adjust size as needed
                                .cornerRadius(8)
                                .offset(y: -24)
                        )
                        .clipped()

                    Spacer().frame(height: 16) // 16px spacing between the image and color picker

                    SpectrumColorPicker(selectedColor: $selectedColor)
                        .frame(width: 250, height: 240)
                        .clipShape(Circle())
                        .padding(.top, 8) // 8px top padding for the color picker

                    Spacer() // Spacer to center the "Next" button vertically
                    Button(action: {
                        // Add your action for the "Next" button here
                    }) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24) // 24px left and right padding
                            .padding(12)
                            .background(Color(red: 0.09, green: 0.09, blue: 0.09))
                            .cornerRadius(100) // 100px border radius
                            .overlay(
                                RoundedRectangle(cornerRadius: 100)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1) // 10% white opacity border stroke
                            )
                    }
                    .padding(.bottom, 16) // Add bottom padding to the button
                }
            }
        }
        .navigationBarTitle("", displayMode: .inline)
    }
}

struct SpectrumColorPicker: View {
    @Binding var selectedColor: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Circular gradient
                Circle()
                    .fill(AngularGradient(gradient: Gradient(colors: Color.hueColors), center: .center))
                    .contentShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let point = value.location
                                let adjustedPoint = adjustPointToCircleBounds(point: point, in: geometry.size)
                                selectedColor = getColor(at: adjustedPoint, in: geometry.size)
                            }
                    )
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
