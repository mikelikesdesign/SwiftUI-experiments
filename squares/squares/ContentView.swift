//
//  ContentView.swift
//  squares
//
//  Created by Michael Lee on 2/16/25.
//

import SwiftUI
import UIKit

struct SquaresView: UIViewRepresentable {
    var selectedShape: AnimationShape
    
    func makeUIView(context: Context) -> UIView {
        let view = SquaresUIView(frame: UIScreen.main.bounds)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let squaresView = uiView as? SquaresUIView else { return }
        squaresView.updateAnimationSettings(shape: selectedShape)
    }
}

class SquaresUIView: UIView {
    private var layers: [[CALayer]] = []
    private var timer: Timer?
    private var baseColumns: Int = 20
    private var dimension: CGFloat = 0
    private var coloredSquares: [(row: Int, col: Int, timestamp: TimeInterval)] = []
    private var fadeTimer: CADisplayLink?
    private var ripples: [(center: (row: Int, col: Int), currentRadius: Int, maxRadius: Int, timestamp: TimeInterval, shape: AnimationShape)] = []
    private var rippleTimer: CADisplayLink?
    private var currentShape: AnimationShape = .circle
    private var isNextRippleCircle: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    deinit {
        timer?.invalidate()
        fadeTimer?.invalidate()
        rippleTimer?.invalidate()
    }
    
    private func setup() {
        backgroundColor = .white
        
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        
        isUserInteractionEnabled = true
        
        setupFadeTimer()
        setupRippleTimer()
        
        if bounds.width > 0 && bounds.height > 0 {
            createLayers()
            startTimer()
        }
    }
    
    private func setupFadeTimer() {
        fadeTimer = CADisplayLink(target: self, selector: #selector(handleFadeTimer))
        fadeTimer?.add(to: .main, forMode: .common)
    }
    
    private func setupRippleTimer() {
        rippleTimer = CADisplayLink(target: self, selector: #selector(handleRippleTimer))
        rippleTimer?.add(to: .main, forMode: .common)
    }
    
    @objc private func handleFadeTimer() {
        let currentTime = CACurrentMediaTime()
        var indicesToRemove: [Int] = []
        
        for (index, square) in coloredSquares.enumerated() {
            if currentTime - square.timestamp >= 0.1 {
                fadeSquareToGrey(at: square.row, col: square.col)
                indicesToRemove.append(index)
            }
        }
       
        for index in indicesToRemove.sorted(by: >) {
            coloredSquares.remove(at: index)
        }
    }
    
    @objc private func handleRippleTimer() {
        let currentTime = CACurrentMediaTime()
        var ripplestoRemove: [Int] = []
        
        for (index, ripple) in ripples.enumerated() {
            if currentTime - ripple.timestamp >= 0.03 {
                let currentRadius = ripple.currentRadius
                if currentRadius < ripple.maxRadius {
                    createShapeRing(center: ripple.center, radius: currentRadius, shape: ripple.shape)
                    ripples[index].currentRadius += 1
                    ripples[index].timestamp = currentTime
                } else {
                    ripplestoRemove.append(index)
                }
            }
        }
        
        for index in ripplestoRemove.sorted(by: >) {
            ripples.remove(at: index)
        }
    }
    
    private func fadeSquareToGrey(at row: Int, col: Int) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.5)
        layers[row][col].backgroundColor = UIColor.white.cgColor
        CATransaction.commit()
    }
    
    private func createLayers() {
        layers.forEach { row in
            row.forEach { $0.removeFromSuperlayer() }
        }
        layers.removeAll()
        
        dimension = bounds.width / CGFloat(baseColumns)
        let rows = Int(ceil(bounds.height / dimension))
        
        backgroundColor = .white
        
        for row in 0..<rows {
            var rowLayers: [CALayer] = []
            for col in 0..<baseColumns {
                let layer = CALayer()
                layer.frame = CGRect(x: CGFloat(col) * dimension,
                                   y: CGFloat(row) * dimension,
                                   width: dimension,
                                   height: dimension)
                layer.backgroundColor = UIColor.white.cgColor
                
                layer.borderWidth = 0.5
                layer.borderColor = UIColor(white: 0.9, alpha: 1.0).cgColor
                
                self.layer.addSublayer(layer)
                rowLayers.append(layer)
            }
            layers.append(rowLayers)
        }
    }
    
    private func randomGreyColor() -> CGColor {
        return UIColor(white: 0.95, alpha: 1.0).cgColor
    }
    
    private func randomBrightColor() -> CGColor {
        return UIColor(
            hue: CGFloat.random(in: 0...1),
            saturation: 0.7,
            brightness: 1.0,
            alpha: 1.0
        ).cgColor
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateGreyColors() {
    }
    
    private func clearPattern() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.5)
        
        for row in 0..<layers.count {
            for col in 0..<baseColumns {
                layers[row][col].backgroundColor = UIColor.white.cgColor
            }
        }
        
        CATransaction.commit()
    }
    
    private func createShapeRing(center: (row: Int, col: Int), radius: Int, shape: AnimationShape) {
        let positions = getShapePositions(center: center, radius: radius, shape: shape)
        
        for pos in positions {
            guard pos.row >= 0 && pos.row < layers.count && pos.col >= 0 && pos.col < baseColumns else { continue }
            
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.2)

            let hue = CGFloat(radius) / 10.0
            let color = UIColor(
                hue: hue.truncatingRemainder(dividingBy: 1.0),
                saturation: 0.7,
                brightness: 1.0,
                alpha: 1.0
            ).cgColor
            
            layers[pos.row][pos.col].backgroundColor = color
            
            CATransaction.commit()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.3)
                self?.layers[pos.row][pos.col].backgroundColor = UIColor.white.cgColor
                CATransaction.commit()
            }
        }
    }
    
    private func getShapePositions(center: (row: Int, col: Int), radius: Int, shape: AnimationShape) -> [(row: Int, col: Int)] {
        var positions: [(row: Int, col: Int)] = []
        
        for i in -radius...radius {
            for j in -radius...radius {
                switch shape {
                case .circle:
                    let distance = sqrt(Double(i * i + j * j))
                    if distance >= Double(radius) - 0.5 && distance < Double(radius) + 0.5 {
                        positions.append((row: center.row + i, col: center.col + j))
                    }
                case .square:
                    if abs(i) == radius || abs(j) == radius {
                        positions.append((row: center.row + i, col: center.col + j))
                    }
                case .diamond:
                    if abs(i) + abs(j) == radius {
                        positions.append((row: center.row + i, col: center.col + j))
                    }
                }
            }
        }
        
        return positions
    }
    
    private func startRipple(at point: CGPoint) {
        let col = Int(point.x / dimension)
        let row = Int(point.y / dimension)
        
        guard row >= 0 && row < layers.count && col >= 0 && col < baseColumns else { return }
        
        let maxRadius = max(baseColumns, layers.count) / 2
        ripples.append((
            center: (row: row, col: col),
            currentRadius: 0,
            maxRadius: maxRadius,
            timestamp: 0,
            shape: currentShape
        ))
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        layers[row][col].backgroundColor = randomBrightColor()
        CATransaction.commit()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        startRipple(at: point)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        startRipple(at: point)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width > 0 && bounds.height > 0 {
            createLayers()
            if timer == nil {
                startTimer()
            }
        }
    }
    
    func updateAnimationSettings(shape: AnimationShape) {
        currentShape = shape
    }
}

struct ContentView: View {
    @State private var selectedShape: AnimationShape = .circle
    
    var body: some View {
        ZStack {
            SquaresView(selectedShape: selectedShape)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                HStack(spacing: 24) {
                    Button(action: { selectedShape = .circle }) {
                        Image(systemName: "circle")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(selectedShape == .circle ? Color.blue : Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Button(action: { selectedShape = .square }) {
                        Image(systemName: "square")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(selectedShape == .square ? Color.blue : Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Button(action: { selectedShape = .diamond }) {
                        Image(systemName: "diamond")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(selectedShape == .diamond ? Color.blue : Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 2)
                )
                .padding(.bottom, 16)
            }
        }
    }
}

enum AnimationShape {
    case circle, square, diamond
}

#Preview {
    ContentView()
}

