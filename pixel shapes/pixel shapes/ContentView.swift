//
//  ContentView.swift
//  pixel shapes
//
//  Created by Michael Lee on 5/8/25.
//

import SwiftUI
import UIKit

struct SquaresView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = SquaresUIView(frame: UIScreen.main.bounds)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let squaresView = uiView as? SquaresUIView else { return }
        squaresView.updateAnimationSettings()
    }
}

class SquaresUIView: UIView {
    private var layers: [[CALayer]] = []
    private var displayLink: CADisplayLink?
    private var baseColumns: Int = 35
    private var dimension: CGFloat = 0
    private var gridContainerLayer = CALayer()

    private var rotationAngleX: Double = 0.0
    private var rotationAngleY: Double = 0.0
    private var autoRotationSpeedY: Double = 0.01
    private var isAutoRotating: Bool = true
    
    private let referenceBaseColumns: Int
    private let referenceModelRadius: Double
    private var currentGlobeScale: CGFloat = 1.0
    private var initialGlobeScaleForPinchGesture: CGFloat = 1.0

    private var lastTouchPoint: CGPoint?
    private let rotationSensitivity: CGFloat = 0.005

    private var globeTextureColors: [[UIColor]] = []
    private let textureWidth: Int = 60
    private let textureHeight: Int = 30

    private let lightDirection: (x: Double, y: Double, z: Double) = normalize((x: 0.7, y: 0.5, z: 1.0))
    private let ambientLightFactor: CGFloat = 0.3
    private let diffuseLightFactor: CGFloat = 0.7

    private static func normalize(_ v: (x: Double, y: Double, z: Double)) -> (x: Double, y: Double, z: Double) {
        let length = sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
        guard length > 0 else { return (0,0,0) }
        return (v.x / length, v.y / length, v.z / length)
    }

    override init(frame: CGRect) {
        self.referenceBaseColumns = 35
        self.referenceModelRadius = Double(self.referenceBaseColumns) / 2.5
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        self.referenceBaseColumns = 35
        self.referenceModelRadius = Double(self.referenceBaseColumns) / 2.5
        super.init(coder: coder)
        setup()
    }
    
    deinit {
        displayLink?.invalidate()
    }
    
    private func setup() {
        backgroundColor = UIColor.black
        
        layer.addSublayer(gridContainerLayer)
        gridContainerLayer.frame = bounds
        
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        isUserInteractionEnabled = true
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)
        
        if bounds.width > 0 && bounds.height > 0 {
            generateGlobeTexture()
            createLayers()
            startAnimationTimer()
        }
    }
    
    private func generateGlobeTexture() {
        globeTextureColors = []
        for _ in 0..<textureHeight {
            var rowColors: [UIColor] = []
            for _ in 0..<textureWidth {
                let randomHue = CGFloat.random(in: 0...1)
                let randomSaturation = CGFloat.random(in: 0.7...1.0)
                let randomBrightness = CGFloat.random(in: 0.8...1.0)
                rowColors.append(UIColor(hue: randomHue, 
                                         saturation: randomSaturation, 
                                         brightness: randomBrightness, 
                                         alpha: 1.0))
            }
            globeTextureColors.append(rowColors)
        }
    }

    private func createLayers() {
        layers.forEach { row in row.forEach { $0.removeFromSuperlayer() } }
        layers.removeAll()
        
        gridContainerLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        dimension = bounds.width / CGFloat(referenceBaseColumns)
        let effectiveSquareSize = dimension
        
        let rows = baseColumns
        
        let effectiveGridSize = dimension * CGFloat(baseColumns)
        gridContainerLayer.bounds = CGRect(x: 0, y: 0, width: effectiveGridSize, height: effectiveGridSize)
        gridContainerLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        
        gridContainerLayer.transform = CATransform3DMakeScale(currentGlobeScale, currentGlobeScale, 1.0)
        
        self.backgroundColor = UIColor.black

        for row in 0..<rows {
            var rowLayers: [CALayer] = []
            for col in 0..<baseColumns {
                let layer = CALayer()
                
                let offsetX = (effectiveGridSize - (CGFloat(baseColumns) * effectiveSquareSize)) / 2
                let offsetY = (effectiveGridSize - (CGFloat(rows) * effectiveSquareSize)) / 2
                
                layer.frame = CGRect(
                    x: offsetX + CGFloat(col) * effectiveSquareSize,
                    y: offsetY + CGFloat(row) * effectiveSquareSize,
                    width: effectiveSquareSize,
                    height: effectiveSquareSize
                )
                layer.backgroundColor = UIColor.black.cgColor
                layer.borderWidth = 0.25
                layer.borderColor = UIColor(white: 0.05, alpha: 1.0).cgColor
                gridContainerLayer.addSublayer(layer)
                rowLayers.append(layer)
            }
            layers.append(rowLayers)
        }
    }
    
    private func startAnimationTimer() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updateGlobeAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateGlobeAnimation() {
        if isAutoRotating {
            rotationAngleY += autoRotationSpeedY
        }

        let numRows = layers.count
        guard numRows > 0 else { return }
        let numCols = baseColumns
        let modelRadius = self.referenceModelRadius

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let cosAy = cos(-rotationAngleY)
        let sinAy = sin(-rotationAngleY)
        let cosAx = cos(-rotationAngleX)
        let sinAx = sin(-rotationAngleX)

        for r in 0..<numRows {
            for c in 0..<numCols {
                let x_grid = (Double(c) - Double(numCols - 1) / 2.0)
                let y_grid = (Double(r) - Double(numRows - 1) / 2.0)

                var finalColorUIColor = UIColor.black
                var isGlobePixel = false

                if x_grid * x_grid + y_grid * y_grid <= modelRadius * modelRadius {
                    isGlobePixel = true
                    let z_proj_squared = modelRadius * modelRadius - x_grid * x_grid - y_grid * y_grid
                    guard z_proj_squared >= 0 else {
                        layers[r][c].backgroundColor = UIColor.black.cgColor
                        layers[r][c].borderColor = UIColor(white: 0.05, alpha: 1.0).cgColor
                        continue
                    }
                    let z_proj = sqrt(z_proj_squared)
                    
                    let x_rotY = x_grid * cosAy + z_proj * sinAy
                    let y_rotY = y_grid
                    let z_rotY = -x_grid * sinAy + z_proj * cosAy
                    
                    let x_model_unrotated = x_rotY
                    let y_model_unrotated = y_rotY * cosAx - z_rotY * sinAx
                    let z_model_unrotated = y_rotY * sinAx + z_rotY * cosAx

                    let R_model = sqrt(x_model_unrotated*x_model_unrotated + y_model_unrotated*y_model_unrotated + z_model_unrotated*z_model_unrotated)
                    
                    var baseUIColor = UIColor.darkGray 

                    if R_model > 0 && !globeTextureColors.isEmpty {
                        let lat = asin(y_model_unrotated / R_model)
                        let lon = atan2(x_model_unrotated, z_model_unrotated)

                        let latNormalized = (lat / .pi) + 0.5
                        var latIndex = Int(latNormalized * Double(textureHeight))
                        latIndex = max(0, min(textureHeight - 1, latIndex))

                        let lonNormalized = (lon / (2 * .pi)) + 0.5 
                        var lonIndex = Int(lonNormalized * Double(textureWidth))
                        lonIndex = max(0, min(textureWidth - 1, lonIndex))
                        
                        if latIndex < globeTextureColors.count && lonIndex < globeTextureColors[latIndex].count {
                           baseUIColor = globeTextureColors[latIndex][lonIndex]
                        }
                    } else if !globeTextureColors.isEmpty {
                         baseUIColor = globeTextureColors[0][0]
                    }

                    let normal_view_length = sqrt(x_grid*x_grid + y_grid*y_grid + z_proj*z_proj)
                    var lightIntensity: CGFloat = ambientLightFactor
                    if normal_view_length > 0 {
                        let nx = x_grid / normal_view_length
                        let ny = y_grid / normal_view_length
                        let nz = z_proj / normal_view_length
                        let dotProduct = nx * lightDirection.x + ny * lightDirection.y + nz * lightDirection.z
                        lightIntensity = ambientLightFactor + diffuseLightFactor * max(0, CGFloat(dotProduct))
                    }
                    
                    var rComp: CGFloat = 0, gComp: CGFloat = 0, bComp: CGFloat = 0, aComp: CGFloat = 0
                    baseUIColor.getRed(&rComp, green: &gComp, blue: &bComp, alpha: &aComp)
                    finalColorUIColor = UIColor(red: rComp * lightIntensity, green: gComp * lightIntensity, blue: bComp * lightIntensity, alpha: aComp)

                    let distSqFromCenter = x_grid * x_grid + y_grid * y_grid
                    let edgeProximity = sqrt(distSqFromCenter) / modelRadius
                    
                    let edgeDarkeningMultiplier = cos(edgeProximity * .pi / 2.0)
                    
                    var finalR: CGFloat = 0, finalG: CGFloat = 0, finalB: CGFloat = 0, finalA: CGFloat = 0
                    finalColorUIColor.getRed(&finalR, green: &finalG, blue: &finalB, alpha: &finalA)
                    
                    finalColorUIColor = UIColor(red: finalR * edgeDarkeningMultiplier,
                                                green: finalG * edgeDarkeningMultiplier,
                                                blue: finalB * edgeDarkeningMultiplier,
                                                alpha: finalA)
                }
                
                layers[r][c].backgroundColor = finalColorUIColor.cgColor
                layers[r][c].borderColor = isGlobePixel ? UIColor(white: 0.02, alpha: 1.0).cgColor : UIColor.clear.cgColor
            }
        }
        CATransaction.commit()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        isAutoRotating = false
        lastTouchPoint = touch.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let lastPoint = lastTouchPoint else { return }
        let currentPoint = touch.location(in: self)
        
        let deltaX = currentPoint.x - lastPoint.x
        let deltaY = currentPoint.y - lastPoint.y
        
        rotationAngleY += Double(deltaX * rotationSensitivity)
        rotationAngleX += Double(deltaY * rotationSensitivity)
        
        lastTouchPoint = currentPoint
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPoint = nil
        isAutoRotating = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPoint = nil
        isAutoRotating = true 
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            initialGlobeScaleForPinchGesture = currentGlobeScale
            isAutoRotating = false
        case .changed:
            guard initialGlobeScaleForPinchGesture > 0 else { return }

            currentGlobeScale = initialGlobeScaleForPinchGesture * gesture.scale
            currentGlobeScale = max(0.25, min(4.0, currentGlobeScale))

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            let effectiveGridSize = dimension * CGFloat(baseColumns)
            gridContainerLayer.bounds = CGRect(x: 0, y: 0, width: effectiveGridSize, height: effectiveGridSize)
            
            gridContainerLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
            
            gridContainerLayer.transform = CATransform3DMakeScale(currentGlobeScale, currentGlobeScale, 1.0)
            
            CATransaction.commit()
        case .ended, .cancelled:
            isAutoRotating = true
        default:
            break
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width > 0 && bounds.height > 0 {
            gridContainerLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
            
            if layers.isEmpty {
                createLayers()
            }
            
            if displayLink == nil {
                startAnimationTimer()
            }
        }
    }
    
    func updateAnimationSettings() {
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            SquaresView()
                .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}





