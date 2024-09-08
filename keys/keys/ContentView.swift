import SwiftUI

struct ContentView: View {
    @State private var keyPosition = CGPoint(x: 100, y: 100)
    @State private var isKeyDropped = false
    @State private var codeText: [String] = [""]
    @State private var showHelpText = false
    @State private var inputText = ""
    @State private var typedText = ""
    @State private var circleColor = Color.white
    @State private var colorAnimationTimer: Timer?
    @State private var colorAnimationSpeed: Double = 0.1
    private let circleCenter = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                if showHelpText {
                    Color.white.edgesIgnoringSafeArea(.all)
                } else {
                    Color.black.edgesIgnoringSafeArea(.all)
                }
                
                // Animated Color-Changing Circle
                if !showHelpText {
                    Circle()
                        .fill(circleColor)
                        .frame(width: circleDiameter(), height: circleDiameter())
                        .position(circleCenter)
                        .animation(.easeInOut(duration: colorAnimationSpeed), value: circleColor)
                        .animation(.easeInOut, value: isKeyDropped)
                        .onAppear {
                            startColorAnimation()
                        }
                }
                
                // Text "Drop Key Here" or Animating Code
                if !showHelpText {
                    if isKeyDropped {
                        VStack(spacing: 5) {
                            ForEach(0..<codeText.count, id: \.self) { index in
                                Text(codeText[index])
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundColor(.black)
                            }
                        }
                        .position(circleCenter)
                    } else {
                        Text("Drop Key Here")
                            .font(.system(size: 20, design: .monospaced))
                            .foregroundColor(.white)
                            .position(circleCenter)
                    }
                }
                
                // "How can I help?" Text with Typewriter Effect
                if showHelpText {
                    Text(typedText)
                        .font(.system(size: 20, design: .monospaced))
                        .foregroundColor(.black)
                        .position(circleCenter)
                        .onAppear {
                            animateText()
                        }
                }
                
                // Old Key Emoji 🗝️
                if !showHelpText {
                    Text("🗝️")
                        .font(.system(size: 64))
                        .position(keyPosition)
                        .opacity(isKeyDropped ? 0 : 1)
                        .animation(.easeOut, value: isKeyDropped)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    keyPosition = gesture.location
                                }
                                .onEnded { _ in
                                    if distanceToCenter() < 100 {
                                        isKeyDropped = true
                                        slowDownColorAnimation()
                                        startCodeAnimation()
                                    }
                                }
                        )
                }
                
                // Input Field
                if showHelpText {
                    VStack {
                        Spacer()
                        HStack {
                            TextField("Type your question", text: $inputText)
                                .font(.system(size: 16))
                                .padding()
                                .background(Color(white: 0.95))
                                .cornerRadius(100)
                                .frame(width: 300, height: 40)
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .statusBar(hidden: false)
    }
    
    // Start color animation
    private func startColorAnimation() {
        updateColorAnimation()
    }
    
    // Update color animation based on current speed
    private func updateColorAnimation() {
        colorAnimationTimer?.invalidate()
        colorAnimationTimer = Timer.scheduledTimer(withTimeInterval: colorAnimationSpeed, repeats: true) { _ in
            withAnimation {
                circleColor = Color(
                    red: .random(in: 0...1),
                    green: .random(in: 0...1),
                    blue: .random(in: 0...1)
                )
            }
        }
    }
    
    // Slow down color animation
    private func slowDownColorAnimation() {
        colorAnimationSpeed = 2.0
        updateColorAnimation()
    }
    
    // Stop color animation
    private func stopColorAnimation() {
        colorAnimationTimer?.invalidate()
        colorAnimationTimer = nil
    }
    
    // Calculate the distance between the key position and the circle center
    private func distanceToCenter() -> CGFloat {
        return hypot(keyPosition.x - circleCenter.x, keyPosition.y - circleCenter.y)
    }
    
    // Calculate the diameter of the circle based on key's proximity to the center
    private func circleDiameter() -> CGFloat {
        if isKeyDropped {
            let screenDiagonal = hypot(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            return screenDiagonal * 2 // Expand circle to cover the entire screen
        } else {
            let originalDiameter: CGFloat = 200
            let maxDistance = originalDiameter / 2
            let growthFactor = 1.5 + min(2.5, (maxDistance - distanceToCenter()) / maxDistance * 2.5)
            return originalDiameter * growthFactor
        }
    }
    
    // Start the code animation
    private func startCodeAnimation() {
        var rowCount = 1
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            for i in 0..<rowCount {
                if i < codeText.count {
                    codeText[i] = generateRandomCodeText()
                } else {
                    codeText.append(generateRandomCodeText())
                }
            }
            
            if rowCount < 10 {
                rowCount += 1
            }
            
            // Stop the animation after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                timer.invalidate()
                stopColorAnimation()
                showHelpText = true
            }
        }
    }
    
    // Generate random code text
    private func generateRandomCodeText() -> String {
        let characters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String((0..<20).map { _ in characters.randomElement()! })
    }
    
    // Animate text with typewriter effect
    private func animateText() {
        let fullText = "How can I help?"
        for (index, character) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                typedText.append(character)
            }
        }
    }
}

#Preview {
    ContentView()
}
