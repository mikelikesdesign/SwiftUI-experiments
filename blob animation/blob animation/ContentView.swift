//
//  ContentView.swift
//  blob animation
//
//  Created by Michael Lee on 11/13/24.
//

import SwiftUI
import QuartzCore

struct ContentView: View {
    var body: some View {
        LiquidMetalView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .ignoresSafeArea()
    }
}

struct LiquidMetalView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return MetalView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class MetalView: UIView {
    private var points: [CGPoint] = []
    private var velocities: [CGPoint] = []
    private var displayLink: CADisplayLink?
    private var metalLayer: CAShapeLayer!
    private var ripplePoints: [(point: CGPoint, age: CGFloat)] = []
    private let numPoints = 200
    private let radius: CGFloat = 140
    private var time: Double = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMetal()
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(pan)
        
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .current, forMode: .default)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMetal() {
        metalLayer = CAShapeLayer()
        metalLayer.fillColor = UIColor(white: 0.8, alpha: 1.0).cgColor
        metalLayer.shadowColor = UIColor.white.cgColor
        metalLayer.shadowOffset = .zero
        metalLayer.shadowRadius = 10
        metalLayer.shadowOpacity = 0.5
        layer.addSublayer(metalLayer)
        
        for i in 0..<numPoints {
            let angle = (2.0 * .pi * Double(i)) / Double(numPoints)
            points.append(CGPoint(
                x: cos(angle) * radius,
                y: sin(angle) * radius
            ))
            velocities.append(.zero)
        }
        
        for i in 0..<numPoints {
            velocities[i] = CGPoint(
                x: CGFloat.random(in: -0.5...0.5),
                y: CGFloat.random(in: -0.5...0.5)
            )
        }
    }
    
    @objc private func update() {
        let centerX = bounds.midX
        let centerY = bounds.midY
        let springStrength: CGFloat = 0.08
        let damping: CGFloat = 0.95
        let rippleStrength: CGFloat = 30
        
        time += 0.016
        let autonomousStrength: CGFloat = 0.3
        
        ripplePoints = ripplePoints.compactMap { point, age in
            let newAge = age + 0.016
            return newAge < 1 ? (point, newAge) : nil
        }
        
        for i in 0..<points.count {
            var velocity = velocities[i]
            var point = points[i]
            
            let noiseX = sin(CGFloat(-time * 2 + Double(i) * 0.1)) * autonomousStrength
            let noiseY = cos(CGFloat(-time * 2 + Double(i) * 0.1)) * autonomousStrength
            
            let angle = (2.0 * .pi * Double(i)) / Double(numPoints)
            let restX = cos(angle) * radius
            let restY = sin(angle) * radius
            
            var fx = (restX - point.x) * springStrength + noiseX
            var fy = (restY - point.y) * springStrength + noiseY
            
            for (ripplePoint, age) in ripplePoints {
                let dx = (ripplePoint.x - centerX) - point.x
                let dy = (ripplePoint.y - centerY) - point.y
                let distance = sqrt(dx * dx + dy * dy)
                let rippleFactor = sin(age * .pi * 2) * (1 - age)
                let force = rippleStrength * rippleFactor / (distance + 1)
                
                fx += dx * force * 0.01
                fy += dy * force * 0.01
            }
            
            velocity.x = velocity.x * damping + fx
            velocity.y = velocity.y * damping + fy
            point.x += velocity.x
            point.y += velocity.y
            
            points[i] = point
            velocities[i] = velocity
        }

        let path = UIBezierPath()
        let firstPoint = CGPoint(x: points[0].x + centerX, y: points[0].y + centerY)
        path.move(to: firstPoint)
        
        for i in 0..<points.count {
            let j = (i + 1) % points.count
            let k = (i + 2) % points.count
            
            let p1 = CGPoint(x: points[i].x + centerX, y: points[i].y + centerY)
            let p2 = CGPoint(x: points[j].x + centerX, y: points[j].y + centerY)
            let p3 = CGPoint(x: points[k].x + centerX, y: points[k].y + centerY)
            
            let cp1 = CGPoint(
                x: (p1.x + p2.x) / 2,
                y: (p1.y + p2.y) / 2
            )
            let cp2 = CGPoint(
                x: (p2.x + p3.x) / 2,
                y: (p2.y + p3.y) / 2
            )
            
            path.addQuadCurve(to: cp2, controlPoint: p2)
        }
        
        path.close()
        metalLayer.path = path.cgPath
        
        let animation = CABasicAnimation(keyPath: "fillColor")
        animation.fromValue = metalLayer.fillColor
        animation.toValue = UIColor(
            white: 0.7 + CGFloat.random(in: 0...0.2),
            alpha: 1.0
        ).cgColor
        animation.duration = 0.1
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        metalLayer.add(animation, forKey: "colorAnimation")
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began, .changed:
            ripplePoints.append((location, 0))
        default:
            break
        }
    }
    
    deinit {
        displayLink?.invalidate()
    }
}

#Preview {
    ContentView()
}


