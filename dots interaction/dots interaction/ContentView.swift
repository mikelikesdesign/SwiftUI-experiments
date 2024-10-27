//
//  ContentView.swift
//  dots interaction
//
//  Created by Michael Lee on 10/26/24.
//

import SwiftUI

struct DotView: View {
    let position: CGPoint
    let size: CGFloat
    let touchLocation: CGPoint?
    let maxEffectRadius: CGFloat
    @State private var opacity: Double
    
    init(position: CGPoint, size: CGFloat, touchLocation: CGPoint?, maxEffectRadius: CGFloat) {
        self.position = position
        self.size = size
        self.touchLocation = touchLocation
        self.maxEffectRadius = maxEffectRadius
        self._opacity = State(initialValue: Double.random(in: 0.3...1.0))
    }
    
    var body: some View {
        let scale = computeScale()
        
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .position(x: position.x, y: position.y)
            .scaleEffect(scale, anchor: .center)
            .opacity(opacity)
            .animation(
                .interpolatingSpring(
                    stiffness: 200,
                    damping: 8
                ),
                value: scale
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 0.8...1.2))
                    .repeatForever(autoreverses: true)
                ) {
                    opacity = Double.random(in: 0.3...0.8)
                }
            }
    }
    
    private func computeScale() -> CGFloat {
        guard let touch = touchLocation else { return 1.0 }
        
        let distance = sqrt(
            pow(position.x - touch.x, 2) +
            pow(position.y - touch.y, 2)
        )
        
        if distance < maxEffectRadius {
            
            let normalizedDistance = distance / maxEffectRadius
            return 0.3 + (normalizedDistance * 0.7)
        }
        
        return 1.0
    }
}

struct ContentView: View {
    @State private var touchLocation: CGPoint?
    @State private var lastFeedbackTime: Date = .now
    let columns = 15
    let rows = 30
    let dotSize: CGFloat = 6
    let maxEffectRadius: CGFloat = 100
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
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
                            maxEffectRadius: maxEffectRadius
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    touchLocation = value.location
                    if Date().timeIntervalSince(lastFeedbackTime) > 0.05 {
                        feedbackGenerator.impactOccurred(intensity: 0.8)
                        lastFeedbackTime = .now
                    }
                }
                .onEnded { _ in
                    touchLocation = nil
                }
        )
        .onAppear {
            feedbackGenerator.prepare()
        }
    }
}

#Preview {
    ContentView()
}
