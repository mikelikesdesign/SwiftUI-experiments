//
//  ContentView.swift
//  waves
//
//  Created by @mikelikesdesign
//

import SwiftUI
import SceneKit

struct SceneKitView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = SCNScene()
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        
        let sphere = SCNSphere(radius: 8)
        sphere.segmentCount = 40
        
        let material = SCNMaterial()
        material.fillMode = .lines
        material.diffuse.contents = UIColor(Color.cyan)
        material.emission.contents = UIColor(Color.cyan.opacity(0.5))
        sphere.materials = [material]
        
        let sphereNode = SCNNode(geometry: sphere)
        let sphere2 = SCNSphere(radius: 8)
        sphere2.segmentCount = 40
        let material2 = SCNMaterial()
        material2.fillMode = .lines
        material2.diffuse.contents = UIColor(Color.cyan.opacity(0.6))
        material2.emission.contents = UIColor(Color.cyan.opacity(0.3))
        sphere2.materials = [material2]
        
        let sphere2Node = SCNNode(geometry: sphere2)
        sphere2Node.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        sphereNode.addChildNode(sphere2Node)
        
        sceneView.scene?.rootNode.addChildNode(sphereNode)
        let rotation = CABasicAnimation(keyPath: "rotation")
        rotation.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, Float.pi * 2))
        rotation.duration = 12
        rotation.repeatCount = .infinity
        sphereNode.addAnimation(rotation, forKey: "rotate")
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 25)
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}

struct WaveShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat
    var pressLocation: CGPoint?
    var pressDepth: CGFloat
    let lineCount = 25
    
    var animatableData: CGFloat {
        get { pressDepth }
        set { pressDepth = newValue }
    }
    
    func deform(_ point: CGPoint) -> CGPoint {
        guard let pLoc = pressLocation, pressDepth != 0 else { return point }
        let maxRadius: CGFloat = 200.0
        let distance = hypot(point.x - pLoc.x, point.y - pLoc.y)
        
        if distance < maxRadius {
            let normalizedDistance = distance / maxRadius
            let deformFactor = (cos(normalizedDistance * .pi) + 1) / 2.0
            
            let dx = point.x - pLoc.x
            let dy = point.y - pLoc.y
            let horizontalDeform = (dx / distance) * pressDepth * deformFactor * 0.2
            let verticalDeform = pressDepth * deformFactor * (1.0 + abs(dy / distance) * 0.3)
            
            return CGPoint(
                x: point.x + horizontalDeform, 
                y: point.y + verticalDeform
            )
        }
        return point
    }
    
    func path(in rect: CGRect) -> Path {
        let path = Path { p in
            let height = rect.height
            let width = rect.width
            let midHeight = height / 2
            let spacing = amplitude / CGFloat(lineCount)
            
            for line in 0..<lineCount {
                let yOffset = spacing * CGFloat(line)
                let lineVariation = CGFloat(line) / CGFloat(lineCount)
                let variationFactor = lineVariation * 0.5
                let lineFreq = frequency + variationFactor
                let ampVariation = lineVariation * 0.4
                let lineAmp = amplitude * (0.8 + ampVariation)
                
                let phaseWithVariation = phase + lineVariation
                let startX: CGFloat = -10
                let startRelativeX = startX / width
                let startBaseAngle = 2 * .pi * lineFreq * startRelativeX
                let startPrimaryAngle = startBaseAngle + phaseWithVariation
                let startSecondaryAngle = startBaseAngle * 2.3 + phaseWithVariation * 1.5
                let startTertiaryAngle = startBaseAngle * 0.7 + phaseWithVariation * 0.8
                let startComplexWave = sin(startPrimaryAngle) + sin(startSecondaryAngle) * 0.3 + sin(startTertiaryAngle) * 0.2
                let startPoint = CGPoint(x: startX, y: midHeight + yOffset + lineAmp * startComplexWave)
                p.move(to: deform(startPoint))
                
                for x in stride(from: -8, through: width, by: 2) {
                    let relativeX = x / width
                    let baseAngle = 2 * .pi * lineFreq * relativeX
                    let primaryAngle = baseAngle + phaseWithVariation
                    let secondaryAngle = baseAngle * 2.3 + phaseWithVariation * 1.5
                    let tertiaryAngle = baseAngle * 0.7 + phaseWithVariation * 0.8
                    
                    let primaryWave = sin(primaryAngle)
                    let secondaryWave = sin(secondaryAngle) * 0.3
                    let tertiaryWave = sin(tertiaryAngle) * 0.2
                    
                    let complexWave = primaryWave + secondaryWave + tertiaryWave
                    let point = CGPoint(x: x, y: midHeight + yOffset + lineAmp * complexWave)
                    p.addLine(to: deform(point))
                }
                
                let startPointBottom = CGPoint(x: startX, y: midHeight - yOffset + lineAmp * startComplexWave)
                p.move(to: deform(startPointBottom))
                
                for x in stride(from: -8, through: width, by: 2) {
                    let relativeX = x / width
                    
                    let baseAngle = 2 * .pi * lineFreq * relativeX
                    let primaryAngle = baseAngle + phaseWithVariation
                    let secondaryAngle = baseAngle * 2.3 + phaseWithVariation * 1.5
                    let tertiaryAngle = baseAngle * 0.7 + phaseWithVariation * 0.8
                    
                    let primaryWave = sin(primaryAngle)
                    let secondaryWave = sin(secondaryAngle) * 0.3
                    let tertiaryWave = sin(tertiaryAngle) * 0.2
                    
                    let complexWave = primaryWave + secondaryWave + tertiaryWave
                    let point = CGPoint(x: x, y: midHeight - yOffset + lineAmp * complexWave)
                    p.addLine(to: deform(point))
                }
            }
            
            let verticalSpacing = width / 15
            for x in stride(from: verticalSpacing, through: width, by: verticalSpacing) {
                for line in 0..<(lineCount - 1) {
                    let yOffset = spacing * CGFloat(line)
                    let relativeX = x / width
                    let lineVariation = CGFloat(line) / CGFloat(lineCount)
                    
                    let variationFactor = lineVariation * 0.5
                    let lineFreq = frequency + variationFactor
                    let ampVariation = lineVariation * 0.4
                    let lineAmp = amplitude * (0.8 + ampVariation)
                    let phaseWithVariation = phase + lineVariation
                    let baseAngle = 2 * .pi * lineFreq * relativeX
                    let primaryAngle = baseAngle + phaseWithVariation
                    let secondaryAngle = baseAngle * 2.3 + phaseWithVariation * 1.5
                    let tertiaryAngle = baseAngle * 0.7 + phaseWithVariation * 0.8
                    
                    let primaryWave = sin(primaryAngle)
                    let secondaryWave = sin(secondaryAngle) * 0.3
                    let tertiaryWave = sin(tertiaryAngle) * 0.2
                    let complexWave = primaryWave + secondaryWave + tertiaryWave
                    
                    let waveOffset = lineAmp * complexWave
                    let point1 = CGPoint(x: x, y: midHeight + yOffset + waveOffset)
                    let point2 = CGPoint(x: x, y: midHeight + (yOffset + spacing) + waveOffset)
                    p.move(to: deform(point1))
                    p.addLine(to: deform(point2))
                    let point3 = CGPoint(x: x, y: midHeight - yOffset + waveOffset)
                    let point4 = CGPoint(x: x, y: midHeight - (yOffset + spacing) + waveOffset)
                    p.move(to: deform(point3))
                    p.addLine(to: deform(point4))
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
            Color.black.edgesIgnoringSafeArea(.all)
            
            WaveShape(amplitude: 120, frequency: 1.2, phase: phase, pressLocation: pressLocation, pressDepth: pressDepth)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                .blur(radius: 0.2)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    pressLocation = value.location
                    if !isPressed {
                        isPressed = true
                        withAnimation(.easeOut(duration: 0.1)) {
                            pressDepth = 100
                        }
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    withAnimation(.interpolatingSpring(mass: 0.6, stiffness: 120, damping: 10, initialVelocity: 0)) {
                        pressDepth = 0
                    }
                }
        )
        .onReceive(timer) { _ in
            phase += 0.015
        }
    }
}

#Preview {
    ContentView()
}
