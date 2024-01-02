import SwiftUI

struct AnimatedView: View {
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Image("animation")
            .resizable()
            .frame(width: 50, height: 50)  // Adjust the frame size to fit your asset
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(Animation.easeOut(duration: 2.0)) {
                    self.opacity = 0.0
                }
            }
    }
}
