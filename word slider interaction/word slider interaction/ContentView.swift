//
//  ContentView.swift
//  word slider interaction
//
//  Created by Michael Lee on 11/9/24.
//

import SwiftUI

struct ContentView: View {
    @State private var sliderPosition: CGPoint = .zero
    @State private var text: String = "Hi. Status update?"
    @State private var fontSize: CGFloat = 40
    @State private var isKnobEnlarged: Bool = false
    @State private var trackpadRotation: (x: CGFloat, y: CGFloat) = (0, 0)
    @State private var isTrackpadExpanded: Bool = false

    let screenHeight = UIScreen.main.bounds.height
    let trackpadHeight: CGFloat = UIScreen.main.bounds.height * 0.4
    let knobSize: CGFloat = 40
    let knobEnlargementFactor: CGFloat = 1.5
    let gridLines = 10
    let maxRotation: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    Spacer(minLength: 40)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "C0EAFF"))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        Text(text)
                            .font(.system(size: fontSize, weight: .medium))
                            .minimumScaleFactor(0.5)
                            .padding()
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                            .id(text)
                    }
                    .frame(width: geometry.size.width - 32, height: geometry.size.width - 32)
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "121212"))
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        if isTrackpadExpanded {
                            Path { path in
                                for i in 1..<gridLines {
                                    let x = CGFloat(i) * geometry.size.width / CGFloat(gridLines)
                                    path.move(to: CGPoint(x: x, y: 0))
                                    path.addLine(to: CGPoint(x: x, y: trackpadHeight))
                                    
                                    let y = CGFloat(i) * trackpadHeight / CGFloat(gridLines)
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                                }
                            }
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                            
                            VStack {
                                Text("Professional")
                                    .padding(.top, 8)
                                    .foregroundColor(.gray.opacity(0.8))
                                Spacer()
                                Text("Fun")
                                    .padding(.bottom, 8)
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                            
                            HStack {
                                Text("Concise")
                                    .padding(.leading, 8)
                                    .foregroundColor(.gray.opacity(0.8))
                                Spacer()
                                Text("Detailed")
                                    .padding(.trailing, 8)
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: isKnobEnlarged ? knobSize * knobEnlargementFactor : knobSize,
                                       height: isKnobEnlarged ? knobSize * knobEnlargementFactor : knobSize)
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                                .position(sliderPosition)
                        } else {
                            Text("Adjust Tone")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .frame(
                        width: isTrackpadExpanded ? geometry.size.width - 32 : (geometry.size.width - 32) / 2,
                        height: isTrackpadExpanded ? trackpadHeight : 60
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                withAnimation(.spring(response: 0.3)) {
                                    isTrackpadExpanded = true
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3)) {
                                    isTrackpadExpanded = false
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                guard isTrackpadExpanded else { return }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    updateSliderPosition(value, in: geometry.size)
                                    isKnobEnlarged = true
                                }
                                updateText()
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isKnobEnlarged = false
                                }
                            }
                    )
                    .rotation3DEffect(
                        .degrees(trackpadRotation.x),
                        axis: (x: 1, y: 0, z: 0)
                    )
                    .rotation3DEffect(
                        .degrees(trackpadRotation.y),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            sliderPosition = CGPoint(x: knobSize/2, y: knobSize/2)
            updateText()
            adjustFontSize(for: CGSize(width: UIScreen.main.bounds.width - 64, height: UIScreen.main.bounds.width - 64))
        }
    }
    
    private func updateSliderPosition(_ value: DragGesture.Value, in size: CGSize) {
        let newPosition = value.location
        sliderPosition = limitPositionToTrackpad(newPosition, in: size)
        
        let normalizedX = (sliderPosition.x / size.width) * 2 - 1
        let normalizedY = (sliderPosition.y / trackpadHeight) * 2 - 1
        trackpadRotation.y = normalizedX * maxRotation
        trackpadRotation.x = -normalizedY * maxRotation
    }
    
    private func limitPositionToTrackpad(_ position: CGPoint, in size: CGSize) -> CGPoint {
        return CGPoint(
            x: min(max(position.x, knobSize/2), size.width - knobSize/2),
            y: min(max(position.y, knobSize/2), trackpadHeight - knobSize/2)
        )
    }
    
    private func normalizedPosition(for size: CGSize) -> CGPoint {
        return CGPoint(
            x: sliderPosition.x / size.width,
            y: sliderPosition.y / trackpadHeight
        )
    }
    
    private func updateText() {
        let normalizedPosition = normalizedPosition(for: UIScreen.main.bounds.size)
        
        if normalizedPosition.x < 0.5 && normalizedPosition.y < 0.5 {
            text = "Hi, please share your update."
        } else if normalizedPosition.x >= 0.5 && normalizedPosition.y < 0.5 {
            text = "Hello, I hope this message finds you well. I wanted to inquire about your current status and any updates you might have regarding our ongoing projects or tasks. Could you please provide a brief overview of your progress and any notable developments, thanks."
        } else if normalizedPosition.x < 0.5 && normalizedPosition.y >= 0.5 {
            text = "Yo! What's the scoop!"
        } else {
            text = "Hey there! How are you? Excited to hear about all the cool stuff happening! Any exciting adventures or mind blowing discoveries you want to share? I'm all ears and ready for a fun filled update extravaganza! 🎉"
        }
    }
    
    private func adjustFontSize(for size: CGSize) {
        let shortMessageFontSize: CGFloat = 40
        let longMessageFontSize: CGFloat = 38
        
        if text.count <= 30 {
            fontSize = shortMessageFontSize
        } else {
            fontSize = longMessageFontSize
        }
    }
}

struct RotatedText: View {
    let text: String
    let angle: Double
    
    var body: some View {
        Text(text)
            .rotationEffect(.degrees(angle))
            .fixedSize()
            .frame(width: 20)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}

