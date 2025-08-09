//
//  ContentView.swift
//  wave pattern
//
//  Created by @mikelikesdesign on 7/28/25.
//

import SwiftUI

struct HexagonalGrid: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat
    var pressLocation: CGPoint?
    var pressDepth: CGFloat
    let hexSize: CGFloat = 30
    
    var animatableData: CGFloat {
        get { pressDepth }
        set { pressDepth = newValue }
    }
    
    func hexagonPath(center: CGPoint, size: CGFloat) -> Path {
        var path = Path()
        for i in 0...6 {
            let angle = CGFloat(i) * .pi / 3
            let x = center.x + size * cos(angle)
            let y = center.y + size * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
    
    func deform(_ point: CGPoint) -> CGPoint {
        guard let pLoc = pressLocation, pressDepth != 0 else { return point }
        let maxRadius: CGFloat = 200.0
        let distance = hypot(point.x - pLoc.x, point.y - pLoc.y)
        
        if distance < maxRadius {
            let normalizedDistance = distance / maxRadius
            let pulseFactor = sin(normalizedDistance * .pi * 2 - phase * 4) * 0.5 + 0.5
            let deformFactor = (cos(normalizedDistance * .pi) + 1) / 2.0 * pulseFactor
            
            let angle = atan2(point.y - pLoc.y, point.x - pLoc.x)
            let spiralOffset = angle + phase * 2
            
            let dx = cos(spiralOffset) * pressDepth * deformFactor * 0.3
            let dy = sin(spiralOffset) * pressDepth * deformFactor * 0.3
            
            return CGPoint(
                x: point.x + dx,
                y: point.y + dy
            )
        }
        return point
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let hexHeight = hexSize * sqrt(3)
        let hexWidth = hexSize * 2
        let verticalSpacing = hexHeight
        let horizontalSpacing = hexWidth * 0.75
        
        let cols = Int(rect.width / horizontalSpacing) + 2
        let rows = Int(rect.height / verticalSpacing) + 2
        
        for row in -1...rows {
            for col in -1...cols {
                let x = CGFloat(col) * horizontalSpacing
                let y = CGFloat(row) * verticalSpacing + (col % 2 == 1 ? verticalSpacing / 2 : 0)
                
                let center = CGPoint(x: x, y: y)
                
                let distanceFromCenter = hypot(x - rect.width/2, y - rect.height/2)
                let waveOffset = sin(distanceFromCenter * 0.02 + phase) * amplitude
                let pulseSize = hexSize + waveOffset + sin(phase * 2) * 3
                
                let deformedCenter = deform(center)
                
                for i in 0...6 {
                    let angle = CGFloat(i) * .pi / 3
                    let vertexX = deformedCenter.x + pulseSize * cos(angle)
                    let vertexY = deformedCenter.y + pulseSize * sin(angle)
                    let vertex = deform(CGPoint(x: vertexX, y: vertexY))
                    
                    if i == 0 {
                        path.move(to: vertex)
                    } else {
                        path.addLine(to: vertex)
                    }
                }
            }
        }
        
        return path
    }
}

struct ContentView: View {
    @State private var phase: CGFloat = 0
    @State private var pressLocation: CGPoint? = nil
    @State private var pressDepth: CGFloat = 0.0
    @State private var isPressed: Bool = false
    
    let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            HexagonalGrid(
                amplitude: 8,
                frequency: 2,
                phase: phase,
                pressLocation: pressLocation,
                pressDepth: pressDepth
            )
            .stroke(Color.white, lineWidth: 1.5)
            .blur(radius: 0.3)
            
            HexagonalGrid(
                amplitude: 8,
                frequency: 2,
                phase: phase,
                pressLocation: pressLocation,
                pressDepth: pressDepth
            )
            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            .blur(radius: 3)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    pressLocation = value.location
                    if !isPressed {
                        isPressed = true
                        withAnimation(.easeOut(duration: 0.2)) {
                            pressDepth = 120
                        }
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    withAnimation(.interpolatingSpring(mass: 0.4, stiffness: 80, damping: 10, initialVelocity: 0)) {
                        pressDepth = 0
                    }
                }
        )
        .onReceive(timer) { _ in
            phase += 0.025
        }
    }
}

#Preview {
    ContentView()
}
