//
//  ContentView.swift
//  particle slider
//
//  Created by Michael Lee on 9/3/24.
//

import SwiftUI

struct ContentView: View {
    @State private var sliderPosition: CGPoint = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.2)
    @State private var dragOffset: CGSize = .zero
    @State private var particles: [Particle] = []
    @State private var isKnobEnlarged: Bool = false
    @State private var trackpadRotation: (x: CGFloat, y: CGFloat) = (0, 0)
    
    let screenHeight = UIScreen.main.bounds.height
    let trackpadHeight: CGFloat = UIScreen.main.bounds.height * 0.4
    let knobSize: CGFloat = 40
    let knobEnlargementFactor: CGFloat = 1.5

    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack {
                    ForEach(particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .position(particle.position)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height - trackpadHeight - 60)
                .onReceive(timer) { _ in
                    updateParticles(size: CGSize(width: geometry.size.width, height: geometry.size.height - trackpadHeight - 60))
                }
                
                Spacer(minLength: 20)
                
                ZStack {
                    trackpadSurface
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: isKnobEnlarged ? knobSize * knobEnlargementFactor : knobSize, 
                               height: isKnobEnlarged ? knobSize * knobEnlargementFactor : knobSize)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        .position(limitPositionToTrackpad(sliderPosition, in: geometry.size))
                        .offset(dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        updateSliderPosition(value, in: geometry.size)
                                        isKnobEnlarged = true
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        dragOffset = .zero
                                        isKnobEnlarged = false
                                    }
                                }
                        )
                }
                .frame(height: trackpadHeight)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                
                Spacer(minLength: 0)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.white)
        .onAppear {
            let size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - trackpadHeight - 60)
            particles = (0..<200).map { _ in Particle(bounds: size) }
        }
    }
    
    private func updateParticles(size: CGSize) {
        let normalizedPosition = normalizedPosition(for: UIScreen.main.bounds.size)
        let speed = (1 - normalizedPosition.y) * 5
        let dispersion = normalizedPosition.x * 2
        
        for i in particles.indices {
            particles[i].update(speed: speed, dispersion: dispersion, bounds: size)
        }
    }
    
    private func updateSliderPosition(_ value: DragGesture.Value, in size: CGSize) {
        let newPosition = value.location
        sliderPosition = limitPositionToTrackpad(newPosition, in: size)
        
        let limitedPosition = limitPositionToTrackpad(newPosition, in: size)
        dragOffset = CGSize(
            width: newPosition.x - limitedPosition.x,
            height: newPosition.y - limitedPosition.y
        )
        
        let maxRotation: CGFloat = 5
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

    private var trackpadSurface: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "121212"))
                .overlay {
                    TrackpadGrid()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "F1F1F1"), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 0)

            VStack {
                Text("Faster")
                    .padding(.top, 8)
                    .foregroundColor(.gray.opacity(0.8))
                Spacer()
                Text("Slower")
                    .padding(.bottom, 8)
                    .foregroundColor(.gray.opacity(0.8))
            }

            HStack {
                RotatedText(text: "Gather", angle: -90)
                    .padding(.leading, 8)
                    .foregroundColor(.gray.opacity(0.8))
                Spacer()
                RotatedText(text: "Disperse", angle: 90)
                    .padding(.trailing, 8)
                    .foregroundColor(.gray.opacity(0.8))
            }
        }
        .rotation3DEffect(
            .degrees(trackpadRotation.x),
            axis: (x: 1, y: 0, z: 0)
        )
        .rotation3DEffect(
            .degrees(trackpadRotation.y),
            axis: (x: 0, y: 1, z: 0)
        )
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var color: Color
    var size: CGFloat
    
    init(bounds: CGSize) {
        position = CGPoint(x: CGFloat.random(in: 0...bounds.width), y: CGFloat.random(in: 0...bounds.height))
        velocity = CGVector(dx: CGFloat.random(in: -1...1), dy: CGFloat.random(in: -1...1))
        color = Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
        size = CGFloat.random(in: 3...7)
    }
    
    mutating func update(speed: CGFloat, dispersion: CGFloat, bounds: CGSize) {
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let directionFromCenter = CGVector(dx: position.x - center.x, dy: position.y - center.y)
        let distanceFromCenter = sqrt(directionFromCenter.dx * directionFromCenter.dx + directionFromCenter.dy * directionFromCenter.dy)
        
        let factor = dispersion - 1
        velocity.dx += directionFromCenter.dx / distanceFromCenter * factor
        velocity.dy += directionFromCenter.dy / distanceFromCenter * factor
        
        position.x += velocity.dx * speed
        position.y += velocity.dy * speed
        
        position.x = (position.x + bounds.width).truncatingRemainder(dividingBy: bounds.width)
        position.y = (position.y + bounds.height).truncatingRemainder(dividingBy: bounds.height)
        
        velocity.dx += CGFloat.random(in: -0.1...0.1)
        velocity.dy += CGFloat.random(in: -0.1...0.1)
        
        let maxVelocity: CGFloat = 5
        let currentVelocity = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        if currentVelocity > maxVelocity {
            velocity.dx = velocity.dx / currentVelocity * maxVelocity
            velocity.dy = velocity.dy / currentVelocity * maxVelocity
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

struct TrackpadGrid: View {
    private let spacing: CGFloat = 28
    private let majorLineEvery = 4
    private let lineColor = Color.white.opacity(0.06)

    var body: some View {
        Canvas { context, size in
            var minorLines = Path()
            var majorLines = Path()

            for (index, x) in stride(from: spacing, to: size.width, by: spacing).enumerated() {
                if index.isMultiple(of: majorLineEvery) {
                    majorLines.move(to: CGPoint(x: x, y: 0))
                    majorLines.addLine(to: CGPoint(x: x, y: size.height))
                } else {
                    minorLines.move(to: CGPoint(x: x, y: 0))
                    minorLines.addLine(to: CGPoint(x: x, y: size.height))
                }
            }

            for (index, y) in stride(from: spacing, to: size.height, by: spacing).enumerated() {
                if index.isMultiple(of: majorLineEvery) {
                    majorLines.move(to: CGPoint(x: 0, y: y))
                    majorLines.addLine(to: CGPoint(x: size.width, y: y))
                } else {
                    minorLines.move(to: CGPoint(x: 0, y: y))
                    minorLines.addLine(to: CGPoint(x: size.width, y: y))
                }
            }

            context.stroke(
                minorLines,
                with: .color(lineColor),
                lineWidth: 0.5
            )
            context.stroke(
                majorLines,
                with: .color(lineColor),
                lineWidth: 0.75
            )
        }
        .overlay {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.02),
                            .clear,
                            .black.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .allowsHitTesting(false)
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
