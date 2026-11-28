//
//  ContentView.swift
//  dots interaction
//
//  Created by Michael Lee on 10/26/24.
//

import SwiftUI

/// Shrinks a dot and pulls it toward the touch point. Only `strength` animates,
/// so the warp tracks the finger exactly while the press/release still springs.
struct WarpEffect: ViewModifier, Animatable {
    var strength: CGFloat
    let position: CGPoint
    let touch: CGPoint
    let maxEffectRadius: CGFloat

    var animatableData: CGFloat {
        get { strength }
        set { strength = newValue }
    }

    func body(content: Content) -> some View {
        let distance = hypot(position.x - touch.x, position.y - touch.y)
        let falloff: CGFloat = distance < maxEffectRadius
            ? 0.3 + (distance / maxEffectRadius) * 0.7
            : 1.0
        let scale = 1 - strength * (1 - falloff)

        content
            .scaleEffect(scale, anchor: .center)
            .position(
                x: touch.x + (position.x - touch.x) * scale,
                y: touch.y + (position.y - touch.y) * scale
            )
    }
}

struct DotView: View {
    let position: CGPoint
    let size: CGFloat
    let touchLocation: CGPoint
    let strength: CGFloat
    let maxEffectRadius: CGFloat
    @State private var opacity: Double

    init(position: CGPoint, size: CGFloat, touchLocation: CGPoint, strength: CGFloat, maxEffectRadius: CGFloat) {
        self.position = position
        self.size = size
        self.touchLocation = touchLocation
        self.strength = strength
        self.maxEffectRadius = maxEffectRadius
        self._opacity = State(initialValue: Double.random(in: 0.3...1.0))
    }

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .modifier(WarpEffect(
                strength: strength,
                position: position,
                touch: touchLocation,
                maxEffectRadius: maxEffectRadius
            ))
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 0.8...1.2))
                    .repeatForever(autoreverses: true)
                ) {
                    opacity = Double.random(in: 0.3...0.8)
                }
            }
    }
}

struct ContentView: View {
    @State private var touchLocation: CGPoint = .zero
    @State private var isTouching = false
    @State private var lastFeedbackTime: Date = .now
    let columns = 15
    let rows = 30
    let dotSize: CGFloat = 6
    let maxEffectRadius: CGFloat = 100
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
    let pressSpring = Animation.interpolatingSpring(stiffness: 200, damping: 8)
    // Lower damping so the dots overshoot and wobble a bit more as they resurface.
    let releaseSpring = Animation.interpolatingSpring(stiffness: 200, damping: 5)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                let width = geometry.size.width
                let height = geometry.size.height
                
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<columns, id: \.self) { column in
                        let position = CGPoint(
                            x: CGFloat(column) * width / CGFloat(columns - 1),
                            y: CGFloat(row) * height / CGFloat(rows - 1)
                        )
                        
                        DotView(
                            position: position,
                            size: dotSize,
                            touchLocation: touchLocation,
                            strength: isTouching ? 1 : 0,
                            maxEffectRadius: maxEffectRadius
                        )
                    }
                }
            }
            // Attach the gesture to the full-screen grid so touch coordinates share
            // the dots' coordinate space (not the safe-area-inset outer frame).
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        touchLocation = value.location
                        if !isTouching {
                            withAnimation(pressSpring) { isTouching = true }
                        }
                        if Date().timeIntervalSince(lastFeedbackTime) > 0.05 {
                            feedbackGenerator.impactOccurred(intensity: 0.8)
                            lastFeedbackTime = .now
                        }
                    }
                    .onEnded { _ in
                        withAnimation(releaseSpring) { isTouching = false }
                    }
            )
        }
        .ignoresSafeArea()
        .onAppear {
            feedbackGenerator.prepare()
        }
    }
}

#Preview {
    ContentView()
}
