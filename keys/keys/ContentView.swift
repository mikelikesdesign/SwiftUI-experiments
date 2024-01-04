import SwiftUI

struct ContentView: View {
    @State private var keyPosition = CGPoint(x: 100, y: 100)
    private let circleCenter = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // White Circle
                Circle()
                    .fill(Color.white)
                    .frame(width: circleDiameter(), height: circleDiameter())
                    .position(circleCenter)
                
                // Text "Drop Key Here"
                Text("Drop Key Here")
                    .font(.system(size: 16))
                    .foregroundColor(textColor())
                    .position(circleCenter)
                    .animation(.easeIn, value: textColor()) // Ease-in animation for color change
                
                // Old Key Emoji 🗝️
                Text("🗝️")
                    .font(.system(size: 64))
                    .position(keyPosition)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                keyPosition = gesture.location
                            }
                    )
            }
        }
        .statusBar(hidden: false) // Make sure the status bar is visible
    }
    
    // Calculate the diameter of the circle based on key's proximity to the center
    private func circleDiameter() -> CGFloat {
        let distanceToCenter = hypot(keyPosition.x - circleCenter.x, keyPosition.y - circleCenter.y)
        let originalDiameter: CGFloat = 200
        let maxDistance = originalDiameter / 2
        let growthFactor = 1.5 + min(2.5, (maxDistance - distanceToCenter) / maxDistance * 2.5) // 4x growth
        
        return originalDiameter * growthFactor
    }
    
    // Determine the text color based on whether the white circle is visible
    private func textColor() -> Color {
        let distanceToCenter = hypot(keyPosition.x - circleCenter.x, keyPosition.y - circleCenter.y)
        return distanceToCenter < 200 ? .black : .white
    }
}
