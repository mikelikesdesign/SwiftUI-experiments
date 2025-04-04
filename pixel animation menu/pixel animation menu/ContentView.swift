//
//  ContentView.swift
//  pixel animation menu
//
//  Created by Michael Lee on 3/12/25.
//

import SwiftUI
import UIKit

struct SquaresView: UIViewRepresentable {
    var selectedShape: AnimationShape
    var rippleSpeed: Double = 0.03
    var maxRadius: Int = 15
    var gridSize: Int = 20
    var colorPalette: ColorPalette = .rainbow
    
    func makeUIView(context: Context) -> UIView {
        let view = SquaresUIView(frame: UIScreen.main.bounds)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let squaresView = uiView as? SquaresUIView else { return }
        squaresView.updateAnimationSettings(
            shape: selectedShape,
            rippleSpeed: rippleSpeed,
            maxRadius: maxRadius,
            gridSize: gridSize,
            colorPalette: colorPalette
        )
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
    private var rippleSpeed: Double = 0.03
    private var customMaxRadius: Int = 15
    private var isNextRippleCircle: Bool = true
    private var currentColorPalette: ColorPalette = .rainbow
    
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
            if currentTime - ripple.timestamp >= rippleSpeed {
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
                layer.borderColor = UIColor(white: 0.95, alpha: 1.0).cgColor
                
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
        return currentColorPalette.color(for: Int.random(in: 0...10))
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

            let color = currentColorPalette.color(for: radius)
            
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
        
        ripples.append((
            center: (row: row, col: col),
            currentRadius: 0,
            maxRadius: customMaxRadius,
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
    
    func updateAnimationSettings(shape: AnimationShape, rippleSpeed: Double = 0.03, maxRadius: Int = 15, gridSize: Int = 20, colorPalette: ColorPalette = .rainbow) {
        currentShape = shape
        self.rippleSpeed = rippleSpeed
        self.customMaxRadius = maxRadius
        self.currentColorPalette = colorPalette
        
        if self.baseColumns != gridSize {
            self.baseColumns = gridSize
            createLayers()
        }
    }
}

struct ContentView: View {
    @State private var selectedShape: AnimationShape = .circle
    @State private var showSettings: Bool = false
    @State private var rippleSpeed: Double = 0.03
    @State private var maxRadius: Double = 15
    @State private var gridSize: Double = 20
    @State private var selectedPalette: ColorPalette = .rainbow
    
    var body: some View {
        ZStack {
            SquaresView(selectedShape: selectedShape,
                       rippleSpeed: rippleSpeed,
                       maxRadius: Int(maxRadius),
                       gridSize: Int(gridSize),
                       colorPalette: selectedPalette)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                if showSettings {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Animation Settings")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showSettings = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color.gray.opacity(0.6))
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Shape:")
                                .frame(width: 90, alignment: .leading)
                            
                            Picker("Shape", selection: $selectedShape) {
                                Image(systemName: "circle").tag(AnimationShape.circle)
                                Image(systemName: "square").tag(AnimationShape.square)
                                Image(systemName: "diamond").tag(AnimationShape.diamond)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        HStack {
                            Text("Grid Size:")
                                .frame(width: 90, alignment: .leading)
                            
                            Slider(value: $gridSize, in: 10...40, step: 1.0)
                            
                            Text("\(Int(gridSize))")
                                .frame(width: 40)
                        }
                        
                        HStack {
                            Text("Speed:")
                                .frame(width: 90, alignment: .leading)
                            
                            Slider(value: Binding(
                                get: { 11 - (rippleSpeed * 100) },
                                set: { rippleSpeed = (11 - $0) / 100 }
                            ), in: 1...10, step: 1)
                            
                            Text("\(Int(11 - (rippleSpeed * 100)))")
                                .frame(width: 40)
                        }
                        
                        HStack {
                            Text("Max Radius:")
                                .frame(width: 90, alignment: .leading)
                            
                            Slider(value: $maxRadius, in: 5...30, step: 1.0)
                            
                            Text("\(Int(maxRadius))")
                                .frame(width: 40)
                        }
                        
                        HStack {
                            Text("Colors:")
                                .frame(width: 90, alignment: .leading)
                            
                            Picker("", selection: $selectedPalette) {
                                Text("Rainbow").tag(ColorPalette.rainbow)
                                Text("Blue").tag(ColorPalette.blue)
                                Text("Monochrome").tag(ColorPalette.monochrome)
                            }
                            .pickerStyle(MenuPickerStyle())
                            .accentColor(.blue)
                            .labelsHidden()
                            .padding(.leading, -10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("")
                                .frame(width: 40)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showSettings = true
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title)
                                .foregroundColor(Color.gray.opacity(0.6))
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
    }
}

enum AnimationShape {
    case circle, square, diamond
}

enum ColorPalette: String, CaseIterable, Identifiable {
    case rainbow = "Rainbow"
    case blue = "Blue"
    case monochrome = "Monochrome"
    
    var id: String { self.rawValue }
    
    func color(for radius: Int) -> CGColor {
        let normalizedValue = CGFloat(radius) / 10.0
        let hue = normalizedValue.truncatingRemainder(dividingBy: 1.0)
        
        switch self {
        case .rainbow:
            return UIColor(
                hue: hue,
                saturation: 0.7,
                brightness: 1.0,
                alpha: 1.0
            ).cgColor
            
        case .blue:
            return UIColor(
                hue: 0.5 + hue * 0.2,
                saturation: 0.6 + hue * 0.4,
                brightness: 0.8 + hue * 0.2,
                alpha: 1.0
            ).cgColor
            
        case .monochrome:
        
            let brightness = 0.2 + normalizedValue * 0.6
            return UIColor(
                white: brightness,
                alpha: 1.0
            ).cgColor
        }
    }
}

#Preview {
    ContentView()
}




