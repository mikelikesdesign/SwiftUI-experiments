//
//  ContentView.swift
//  bouncy grid
//
//  Created by Michael Lee on 5/18/25.
//

import SwiftUI
struct LineView: View {
    let initialStartPoint: CGPoint
    let initialEndPoint: CGPoint
    let touchLocation: CGPoint?
    let area: CGPoint?
    let duration: Date?
    let maxEffectRadius: CGFloat
    let baseLineWidth: CGFloat = 2.0
    
    @State private var isReturning: Bool = false
    @State private var opacity: Double

    init(startPoint: CGPoint, endPoint: CGPoint, touchLocation: CGPoint?, area: CGPoint?, duration: Date?, maxEffectRadius: CGFloat) {
        self.initialStartPoint = startPoint
        self.initialEndPoint = endPoint
        self.touchLocation = touchLocation
        self.area = area
        self.duration = duration
        self.maxEffectRadius = maxEffectRadius
        self._opacity = State(initialValue: Double.random(in: 0.3...1.0))
    }

    private func distanceBetween(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
    }

    private func closestPointOnLineSegment(from point: CGPoint, toLineSegmentStart start: CGPoint, end: CGPoint) -> CGPoint {
        let dx = end.x - start.x
        let dy = end.y - start.y
        
        if dx == 0 && dy == 0 { return start }

        let lineLengthSquared = dx * dx + dy * dy
        
        var t = ((point.x - start.x) * dx + (point.y - start.y) * dy) / lineLengthSquared
        t = max(0, min(1, t))
        
        return CGPoint(x: start.x + t * dx, y: start.y + t * dy)
    }

    private struct DentEffect {
        var thicknessScale: CGFloat = 1.0
        var displacement: CGFloat = 0.0
    }

    private func computeEffect() -> DentEffect {
        
        if let touch = touchLocation {
            let closestPointToTouch = closestPointOnLineSegment(from: touch, toLineSegmentStart: initialStartPoint, end: initialEndPoint)
            let distanceToLine = distanceBetween(touch, closestPointToTouch)

            let minThicknessScale: CGFloat = 0.4
            let maxDisplacement: CGFloat = 70.0
            
            if distanceToLine < maxEffectRadius {
                let normalizedDistance = distanceToLine / maxEffectRadius
                let currentThicknessScale = minThicknessScale + normalizedDistance * (1.0 - minThicknessScale)
                let currentDisplacement = maxDisplacement * (1.0 - normalizedDistance)
                
                return DentEffect(thicknessScale: currentThicknessScale, displacement: -currentDisplacement)
            }
        }
        
        if let releasePoint = area, let releaseTimeValue = duration {
            let closestPointToRelease = closestPointOnLineSegment(from: releasePoint,
                                                                toLineSegmentStart: initialStartPoint,
                                                                end: initialEndPoint)
            let distanceToLine = distanceBetween(releasePoint, closestPointToRelease)
            
            if distanceToLine < maxEffectRadius {
                let timeSinceRelease = Date().timeIntervalSince(releaseTimeValue)
                let initialDisplacement: CGFloat = 70.0 * (1.0 - min(1.0, distanceToLine / maxEffectRadius))
                let distanceFactor = 1.0 - (distanceToLine / maxEffectRadius)
                
                let returnDuration: Double = 0.15
                if timeSinceRelease <= returnDuration {
                    let returnProgress = timeSinceRelease / returnDuration
                    
                    let easedProgress = sin(returnProgress * Double.pi / 2)
                    let displacement = -initialDisplacement * (1.0 - easedProgress)
                    
                    return DentEffect(
                        thicknessScale: 0.4 + 0.6 * easedProgress,
                        displacement: displacement * distanceFactor
                    )
                }
                
                let oscillationDuration: Double = 0.8
                let oscillationStartTime = returnDuration
                let oscillationEndTime = oscillationStartTime + oscillationDuration
                
                if timeSinceRelease > oscillationStartTime && timeSinceRelease <= oscillationEndTime {
                    let oscillationTime = (timeSinceRelease - oscillationStartTime) / oscillationDuration
                    
                    let amplitude = 0.6 * initialDisplacement
                    let frequency = 22.0
                    let decay = 3.5
                    
                    let initialSnapFactor = max(0, 0.7 - oscillationTime * 3)
                    
                    let oscillation = sin(oscillationTime * frequency) * exp(-oscillationTime * decay)
                    
                    let combinedEffect = oscillation + initialSnapFactor
                    let displacement = amplitude * combinedEffect
                    
                    return DentEffect(
                        thicknessScale: 1.0 + abs(combinedEffect) * 0.2,
                        displacement: displacement * distanceFactor
                    )
                }
            }
        }
        
        return DentEffect()
    }

    var body: some View {
        TimelineView(.animation) { _ in
            let effect = computeEffect()
            
            Path { path in
                path.move(to: initialStartPoint)
                
                if effect.displacement != 0 {
                    let midX = (initialStartPoint.x + initialEndPoint.x) / 2
                    let midY = (initialStartPoint.y + initialEndPoint.y) / 2

                    let dX = initialEndPoint.x - initialStartPoint.x
                    let dY = initialEndPoint.y - initialStartPoint.y
                    let length = sqrt(dX*dX + dY*dY)

                    if length > 0 {
                        let normPerpX = -dY / length
                        let normPerpY = dX / length
                        
                        let controlPoint = CGPoint(x: midX + effect.displacement * normPerpX,
                                                  y: midY + effect.displacement * normPerpY)
                        path.addQuadCurve(to: initialEndPoint, control: controlPoint)
                    } else {
                        path.addLine(to: initialEndPoint)
                    }
                } else {
                    path.addLine(to: initialEndPoint)
                }
            }
            .stroke(Color.white, lineWidth: baseLineWidth * effect.thicknessScale)
            .opacity(opacity)
        }
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
    @State private var touchLocation: CGPoint?
    @State private var area: CGPoint? = nil
    @State private var duration: Date? = nil
    
    let numHorizontalLines = 30
    let numVerticalLines = 15
    
    let maxEffectRadius: CGFloat = 120
    let resetAfterRelease: Double = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                let width = geometry.size.width
                let height = geometry.size.height
                
                let verticalSpacing = numHorizontalLines > 1 ? height / CGFloat(numHorizontalLines - 1) : height
                let horizontalSpacing = numVerticalLines > 1 ? width / CGFloat(numVerticalLines - 1) : width

                ForEach(0..<numHorizontalLines, id: \.self) { rowIndex in
                    let yPos = numHorizontalLines > 1 ? CGFloat(rowIndex) * verticalSpacing : height / 2
                    let startPoint = CGPoint(x: 0, y: yPos)
                    let endPoint = CGPoint(x: width, y: yPos)
                    
                    LineView(
                        startPoint: startPoint,
                        endPoint: endPoint,
                        touchLocation: touchLocation,
                        area: area,
                        duration: duration,
                        maxEffectRadius: maxEffectRadius
                    )
                }
                
                ForEach(0..<numVerticalLines, id: \.self) { colIndex in
                    let xPos = numVerticalLines > 1 ? CGFloat(colIndex) * horizontalSpacing : width / 2
                    let startPoint = CGPoint(x: xPos, y: 0)
                    let endPoint = CGPoint(x: xPos, y: height)

                    LineView(
                        startPoint: startPoint,
                        endPoint: endPoint,
                        touchLocation: touchLocation,
                        area: area,
                        duration: duration,
                        maxEffectRadius: maxEffectRadius
                    )
                }
            }
        }
        .ignoresSafeArea()
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    touchLocation = value.location
                    area = nil
                    duration = nil
                }
                .onEnded { value in
                    area = value.location
                    duration = Date()
                    touchLocation = nil
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + resetAfterRelease) {
                        if let currentReleaseTime = duration, currentReleaseTime <= Date().addingTimeInterval(-resetAfterRelease) {
                            area = nil
                            duration = nil
                        }
                    }
                }
        )
    }
}

#Preview {
    ContentView()
}

