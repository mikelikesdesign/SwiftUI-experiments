//
//  ContentView.swift
//  shapes
//
//  Created by Michael Lee on 9/11/24.
//

import SwiftUI

struct ContentView: View {
    @State private var shapes: [ShapeData] = []
    @State private var lastShapePosition: CGPoint?
    @State private var shapeTimer: Timer?
    @State private var isDragging = false
    let animationDuration: Double = 0.7
    let minDistanceBetweenShapes: CGFloat = 15
    let maxShapes: Int = 50
    let holdGenerationInterval: Double = 0.1
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ForEach(shapes) { shape in
                shape.view
                    .stroke(shape.color, lineWidth: 2)
                    .frame(width: shape.size * shape.scale, height: shape.size * shape.scale)
                    .position(shape.position)
                    .opacity(shape.opacity)
                    .animation(.easeOut(duration: animationDuration), value: shape.scale)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        startShapeGeneration(at: value.location)
                    }
                    
                    if shouldAddShape(at: value.location) {
                        addShape(at: value.location)
                    }
                }
                .onEnded { _ in
                    stopShapeGeneration()
                    isDragging = false
                }
        )
    }
    
    func shouldAddShape(at location: CGPoint) -> Bool {
        guard let lastPosition = lastShapePosition else { return true }
        return distance(from: lastPosition, to: location) >= minDistanceBetweenShapes
    }
    
    func addShape(at location: CGPoint) {
        let newShape = ShapeData(position: location)
        shapes.append(newShape)
        lastShapePosition = location
        
        if shapes.count > maxShapes {
            shapes.removeFirst()
        }
        
        withAnimation(.easeOut(duration: animationDuration)) {
            if let index = shapes.firstIndex(where: { $0.id == newShape.id }) {
                shapes[index].scale = 1
                shapes[index].opacity = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            shapes.removeAll { $0.id == newShape.id }
        }
    }
    
    func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
    }
    
    func startShapeGeneration(at initialLocation: CGPoint) {
        addShape(at: initialLocation)
        
        shapeTimer = Timer.scheduledTimer(withTimeInterval: holdGenerationInterval, repeats: true) { _ in
            if let lastPosition = lastShapePosition {
                addShape(at: lastPosition)
            }
        }
    }
    
    func stopShapeGeneration() {
        shapeTimer?.invalidate()
        shapeTimer = nil
    }
}

struct ShapeData: Identifiable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let size: CGFloat
    let view: AnyShape
    var opacity: Double = 1
    var scale: CGFloat = 0
    
    init(position: CGPoint) {
        self.position = position
        self.color = Color.random
        self.size = CGFloat.random(in: 50...500)
        self.view = AnyShape(Self.randomShape())
    }
    
    static func randomShape() -> some Shape {
        let shapes: [AnyShape] = [
            AnyShape(Circle()),
            AnyShape(Rectangle()),
            AnyShape(RoundedRectangle(cornerRadius: 25)),
            AnyShape(Capsule()),
            AnyShape(Ellipse()),
            AnyShape(Triangle())
        ]
        return shapes.randomElement()!
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

extension Color {
    static var random: Color {
        Color(red: .random(in: 0...1),
              green: .random(in: 0...1),
              blue: .random(in: 0...1))
    }
}

#Preview {
    ContentView()
}
