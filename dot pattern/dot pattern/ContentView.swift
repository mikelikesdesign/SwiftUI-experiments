//
//  ContentView.swift
//  dot pattern
//
//  Created by @mikelikesdesign


import SwiftUI
import Combine

struct MeshPoint {
    var position: CGPoint
    var restPosition: CGPoint
    var velocity: CGVector = .zero
    var pinned: Bool = false
    var rippleIntensity: CGFloat = 0
}

struct ContentView: View {
    @State private var points: [MeshPoint] = []
    @State private var time: Double = 0
    @State private var dragLocation: CGPoint? = nil
    @State private var gridCols: Int = 0
    @State private var gridRows: Int = 0
    @State private var rippleCenter: CGPoint? = nil
    @State private var rippleTime: Double = 0

    let spacing: CGFloat = 35
    let stiffness: CGFloat = 0.08
    let damping: CGFloat = 0.92
    let influenceRadius: CGFloat = 120

    let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                guard gridCols > 1 && gridRows > 1 && !points.isEmpty else { return }

                for point in points {
                    let ripple = point.rippleIntensity
                    let radius: CGFloat = ripple > 0.01 ? 4 : 3

                    let color: Color = ripple > 0.01
                        ? Color(hue: 0.55 - ripple * 0.6, saturation: 0.95, brightness: 1.0)
                        : .white.opacity(0.75)

                    context.fill(
                        Circle().path(in: CGRect(
                            x: point.position.x - radius,
                            y: point.position.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )),
                        with: .color(color)
                    )
                }
            }
            .background(Color(red: 0.02, green: 0.03, blue: 0.08))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragLocation = value.location
                    }
                    .onEnded { value in
                        let distance = hypot(value.location.x - value.startLocation.x,
                                           value.location.y - value.startLocation.y)
                        if distance < 10 {
                            rippleCenter = value.location
                            rippleTime = time
                        }
                        dragLocation = nil
                    }
            )
            .task {
                createMesh(size: geo.size)
            }
            .onReceive(timer) { _ in
                updateSimulation()
            }
        }
        .ignoresSafeArea()
    }

    private func createMesh(size: CGSize) {
        guard size.width > 0 && size.height > 0 else { return }

        var newPoints: [MeshPoint] = []

        let cols = Int(size.width / spacing) + 3
        let rows = Int(size.height / spacing) + 3

        let totalWidth = CGFloat(cols - 1) * spacing
        let totalHeight = CGFloat(rows - 1) * spacing
        let startX = (size.width - totalWidth) / 2
        let startY = (size.height - totalHeight) / 2

        for row in 0..<rows {
            for col in 0..<cols {
                let x = startX + CGFloat(col) * spacing
                let y = startY + CGFloat(row) * spacing
                let position = CGPoint(x: x, y: y)

                let isPinned = row == 0 || row == rows - 1 ||
                              col == 0 || col == cols - 1

                newPoints.append(MeshPoint(
                    position: position,
                    restPosition: position,
                    pinned: isPinned
                ))
            }
        }

        gridCols = cols
        gridRows = rows
        points = newPoints
    }

    private func updateSimulation() {
        guard !points.isEmpty else { return }

        time += 1/60

        if let touch = dragLocation {
            for i in points.indices where !points[i].pinned {
                let dx = points[i].position.x - touch.x
                let dy = points[i].position.y - touch.y
                let distance = hypot(dx, dy)

                if distance < influenceRadius && distance > 1 {
                    let influence = 1 - (distance / influenceRadius)
                    let pushStrength: CGFloat = 25 * influence * influence
                    points[i].velocity.dx += (dx / distance) * pushStrength * 0.1
                    points[i].velocity.dy += (dy / distance) * pushStrength * 0.1
                }
            }
        }

        if let center = rippleCenter {
            let rippleAge = time - rippleTime
            let rippleRadius = rippleAge * 350
            let rippleWidth: CGFloat = 100

            if rippleAge < 2.0 {
                for i in points.indices where !points[i].pinned {
                    let dx = points[i].restPosition.x - center.x
                    let dy = points[i].restPosition.y - center.y
                    let distance = hypot(dx, dy)

                    let distFromRing = abs(distance - rippleRadius)
                    if distFromRing < rippleWidth {
                        let rippleStrength = (1 - distFromRing / rippleWidth) * (1 - rippleAge / 2.0)
                        points[i].rippleIntensity = max(points[i].rippleIntensity, rippleStrength * 0.8)
                        if distance > 1 {
                            points[i].velocity.dx += (dx / distance) * rippleStrength * 6
                            points[i].velocity.dy += (dy / distance) * rippleStrength * 6
                        }
                    }
                }
            } else {
                rippleCenter = nil
            }
        }

        for i in points.indices {
            points[i].rippleIntensity *= 0.92
        }

        for i in points.indices where !points[i].pinned {
            let dx = points[i].restPosition.x - points[i].position.x
            let dy = points[i].restPosition.y - points[i].position.y

            points[i].velocity.dx += dx * stiffness
            points[i].velocity.dy += dy * stiffness
            points[i].velocity.dx *= damping
            points[i].velocity.dy *= damping
            points[i].position.x += points[i].velocity.dx
            points[i].position.y += points[i].velocity.dy
        }
    }
}

#Preview {
    ContentView()
}
