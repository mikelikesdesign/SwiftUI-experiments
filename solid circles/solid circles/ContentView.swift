//
//  ContentView.swift
//  solid circles
//
//  Created by Michael Lee on 11/10/24.
//

import SwiftUI

struct ContentView: View {
    @State private var shapes: [ShapeData] = []
    @State private var isDragging = false
    @State private var timer: Timer?
    @State private var touchLocation: CGPoint = .zero
    let animationDuration: Double = 2.0
    let spawnInterval: Double = 0.05
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ForEach(shapes) { shape in
                    Circle()
                        .stroke(shape.color.opacity(shape.scale / 20), lineWidth: 3)
                        .frame(width: shape.size * shape.scale, height: shape.size * shape.scale)
                        .position(
                            x: center.x + (touchLocation.x - center.x) * (1 - shape.scale / 20),
                            y: center.y + (touchLocation.y - center.y) * (1 - shape.scale / 20)
                        )
                        .opacity(shape.opacity)
                        .blur(radius: (1 - shape.scale / 20) * 2)
                        .animation(.easeOut(duration: animationDuration), value: shape.scale)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let relativeX = value.location.x - center.x
                        let relativeY = value.location.y - center.y
                        touchLocation = CGPoint(
                            x: center.x + relativeX * 2,
                            y: center.y + relativeY * 2
                        )
                        if !isDragging {
                            isDragging = true
                            startSpawningShapes()
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        timer?.invalidate()
                        timer = nil
                    }
            )
        }
    }
    
    private func startSpawningShapes() {
        timer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { _ in
            addShape()
        }
        addShape()
    }
    
    func addShape() {
        let newShape = ShapeData()
        shapes.append(newShape)
        
        withAnimation(.easeOut(duration: animationDuration)) {
            if let index = shapes.firstIndex(where: { $0.id == newShape.id }) {
                shapes[index].scale = 20
                shapes[index].opacity = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            shapes.removeAll { $0.id == newShape.id }
        }
    }
}

struct ShapeData: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var opacity: Double = 1
    var scale: CGFloat = 0.1
    
    init() {
        self.color = Color(
            hue: Double.random(in: 0...1),
            saturation: 1,
            brightness: 1
        )
        self.size = 30
    }
}

#Preview {
    ContentView()
}


