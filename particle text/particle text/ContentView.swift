//
//  ContentView.swift
//  particle text
//
//  Created by Michael Lee on 11/28/24.
//

import SwiftUI
import SpriteKit
import UIKit

class LetterScene: SKScene {
    private var particles: [SKShapeNode] = []
    private var targetPositions: [CGPoint] = []
    private let text = "Welcome"
    private let fontSize: CGFloat = 80
    private let particleSize: CGFloat = 2
    private let particleSpacing: CGFloat = 3
    
    private let colors: [UIColor] = [
        UIColor.white
    ].map { $0.withAlphaComponent(0.9) }
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        // Wait 2 seconds before showing anything
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.setupParticles()
        }
    }
    
    private func setupParticles() {
        // Create text path
        let path = CGMutablePath()
        let font = UIFont.systemFont(ofSize: fontSize, weight: .heavy)
        let textString = NSAttributedString(string: text, attributes: [.font: font])
        let line = CTLineCreateWithAttributedString(textString)
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]
        
        // Get text bounds for centering
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        let xOffset = (size.width - bounds.width) / 2
        let yOffset = (size.height - bounds.height) / 2
        
        // Create path from glyphs
        for run in runs {
            let count = CTRunGetGlyphCount(run)
            let glyphs = UnsafeMutablePointer<CGGlyph>.allocate(capacity: count)
            let positions = UnsafeMutablePointer<CGPoint>.allocate(capacity: count)
            CTRunGetGlyphs(run, CFRange(), glyphs)
            CTRunGetPositions(run, CFRange(), positions)
            
            for i in 0..<count {
                if let letter = CTFontCreatePathForGlyph(font, glyphs[i], nil) {
                    let transform = CGAffineTransform(
                        translationX: positions[i].x + xOffset,
                        y: yOffset
                    )
                    path.addPath(letter, transform: transform)
                }
            }
            
            glyphs.deallocate()
            positions.deallocate()
        }
        
        // Sample points along the path
        let pathBounds = path.boundingBox
        for x in stride(from: pathBounds.minX, through: pathBounds.maxX, by: particleSpacing) {
            for y in stride(from: pathBounds.minY, through: pathBounds.maxY, by: particleSpacing) {
                let point = CGPoint(x: x, y: y)
                if path.contains(point) {
                    targetPositions.append(point)
                    
                    // Create particle at random position
                    let particle = SKShapeNode(circleOfRadius: particleSize)
                    particle.fillColor = colors.randomElement()!
                    particle.strokeColor = .clear
                    particle.position = CGPoint(
                        x: CGFloat.random(in: 0...size.width),
                        y: CGFloat.random(in: 0...size.height)
                    )
                    particle.alpha = 0.8
                    particles.append(particle)
                    addChild(particle)
                }
            }
        }
        
        // Start assembly immediately after particles appear
        assembleText()
    }
    
    func handleTouch(at point: CGPoint) {
        let scenePoint = convertPoint(fromView: point)
        
        // Check if touch is near any particles
        var touchedText = false
        for particle in particles {
            let distance = hypot(particle.position.x - scenePoint.x, 
                               particle.position.y - scenePoint.y)
            if distance < 30 {
                touchedText = true
                break
            }
        }
        
        guard touchedText else { return }
        
        // Explode particles away from touch
        for particle in particles {
            let dx = particle.position.x - scenePoint.x
            let dy = particle.position.y - scenePoint.y
            let distance = hypot(dx, dy)
            let angle = atan2(dy, dx)
            
            let force = max(0, 1000 - distance) / distance
            let moveBy = CGVector(
                dx: cos(angle) * force,
                dy: sin(angle) * force
            )
            
            particle.run(SKAction.move(by: moveBy, duration: 0.3))
        }
        
        // Wait 0.3 seconds to see explosion before starting reassembly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.assembleText(isInitial: false)
        }
    }
    
    private func assembleText(isInitial: Bool = true) {
        for (index, particle) in particles.enumerated() {
            let targetPosition = targetPositions[index]
            // Initial load: 1.5-3.0 seconds
            // Reassembly: 1.5-2.0 seconds
            let duration = isInitial ? 
                Double.random(in: 1.5...3.0) : 
                Double.random(in: 1.5...2.0)
            
            let move = SKAction.move(to: targetPosition, duration: duration)
            move.timingMode = .easeOut
            
            let scale = SKAction.scale(to: 1.0, duration: duration)
            particle.setScale(0.5)
            
            particle.run(SKAction.group([move, scale]))
        }
    }
}

struct ContentView: View {
    @State private var buttonOffset: CGFloat = 200
    @State private var gradientRotation: Double = 0
    let scene: LetterScene = {
        let scene = LetterScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.clear)
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onChanged { gesture in
                                    scene.handleTouch(at: gesture.location)
                                }
                        )
                        .onAppear {
                            // Start gradient animation
                            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                                gradientRotation = 360
                            }
                            
                            // Wait for initial delay (2s) + assembly time (3s) before showing button
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                withAnimation(.spring(duration: 0.6)) {
                                    buttonOffset = 0
                                }
                            }
                        }
                    
                    Button(action: {
                        // Action here
                    }) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 240, height: 60)
                            .background(Color(hex: 0x262626))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(
                                        AngularGradient(
                                            gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]),
                                            center: .center,
                                            startAngle: .degrees(gradientRotation),
                                            endAngle: .degrees(gradientRotation + 360)
                                        ),
                                        lineWidth: 5
                                    )
                            )
                            .cornerRadius(30)
                    }
                    .offset(y: buttonOffset)
                    .padding(.bottom, 50)
                }
            }
            .ignoresSafeArea()
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

#Preview {
    ContentView()
}
