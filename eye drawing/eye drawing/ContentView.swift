//
//  ContentView.swift
//  eye drawing
//
//  Created by @mikelikesdesign on 8/27/25.
//

import SwiftUI
import ARKit
import AVFoundation

struct DrawingPath {
    var points: [CGPoint] = []
    var color: Color = .white
}

class EyeTrackingViewModel: NSObject, ObservableObject, ARSessionDelegate {
    @Published var eyePosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
    @Published var isTracking = false
    @Published var drawingPaths: [DrawingPath] = []
    @Published var isDrawing = true
    @Published var currentPath = DrawingPath()
    @Published var debugInfo = "Starting..."
    
    private var blinkThreshold: Float = 0.4
    private var lastBlinkTime: TimeInterval = 0
    private var blinkDebounceTime: TimeInterval = 0.5
    private var wasBlinking = false
    
    private var arSession = ARSession()
    
    override init() {
        super.init()
        setupARSession()
    }
    
    func setupARSession() {
        debugInfo = "Requesting camera permission..."
        
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.debugInfo = "Camera permission granted, checking face tracking..."
                    self.startFaceTracking()
                } else {
                    self.debugInfo = "Camera permission DENIED - go to Settings to enable"
                }
            }
        }
    }
    
    private func startFaceTracking() {
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        
        guard ARFaceTrackingConfiguration.isSupported else {
            debugInfo = "Face tracking NOT supported on \(deviceModel) iOS \(systemVersion)"
            return
        }
        
        guard ARFaceTrackingConfiguration.supportedVideoFormats.count > 0 else {
            debugInfo = "No TrueDepth camera found on this device"
            return
        }
        
        debugInfo = "Starting face tracking on \(deviceModel)..."
        arSession.delegate = self
        let configuration = ARFaceTrackingConfiguration()
        
        if let videoFormat = ARFaceTrackingConfiguration.supportedVideoFormats.first {
            configuration.videoFormat = videoFormat
            debugInfo = "Using video format: \(videoFormat.imageResolution.width)x\(videoFormat.imageResolution.height)"
        }
        
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        debugInfo = "AR session running - point front camera at your face"
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        DispatchQueue.main.async {
            self.debugInfo = "Added \(anchors.count) anchors"
        }
        
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { 
            DispatchQueue.main.async {
                self.debugInfo = "No face anchor in didAdd"
            }
            return 
        }
        
        DispatchQueue.main.async {
            self.isTracking = true
            self.debugInfo = "Face anchor added, tracking started"
            self.updateEyePosition(from: faceAnchor)
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
        
        DispatchQueue.main.async {
            self.isTracking = true
            self.updateEyePosition(from: faceAnchor)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.debugInfo = "AR Session failed: \(error.localizedDescription)"
        }
    }
    
    private func updateEyePosition(from faceAnchor: ARFaceAnchor) {
        let currentTime = CACurrentMediaTime()
        
        let leftEyeBlink = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0
        let rightEyeBlink = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0
        
        let isCurrentlyBlinking = leftEyeBlink > blinkThreshold && rightEyeBlink > blinkThreshold
        
        if isCurrentlyBlinking && !wasBlinking && (currentTime - lastBlinkTime) > blinkDebounceTime {
            toggleDrawing()
            lastBlinkTime = currentTime
        }
        
        wasBlinking = isCurrentlyBlinking
        
        let lookAtPoint = faceAnchor.lookAtPoint
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let sensitivityX: Float = 0.8
        let sensitivityY: Float = 0.8
        
        let normalizedX = 0.5 + (lookAtPoint.x * sensitivityX)
        let normalizedY = 0.5 - (lookAtPoint.y * sensitivityY)
        
        let screenX = CGFloat(normalizedX) * screenWidth
        let screenY = CGFloat(normalizedY) * screenHeight
        
        let clampedX = max(0, min(screenWidth, screenX))
        let clampedY = max(0, min(screenHeight, screenY))
        
        eyePosition = CGPoint(x: clampedX, y: clampedY)
        
        debugInfo = "Eye tracking active"
        
        if isDrawing {
            addPointToCurrentPath(eyePosition)
        }
    }
    
    func addPointToCurrentPath(_ point: CGPoint) {
        currentPath.points.append(point)
        
        if currentPath.points.count == 1 {
            drawingPaths.append(currentPath)
        } else {
            if !drawingPaths.isEmpty {
                drawingPaths[drawingPaths.count - 1] = currentPath
            }
        }
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        return sqrt(pow(point2.x - point1.x, 2) + pow(point2.y - point1.y, 2))
    }
    
    func startNewPath() {
        currentPath = DrawingPath()
    }
    
    func clearDrawing() {
        drawingPaths.removeAll()
        currentPath = DrawingPath()
    }
    
    func toggleDrawing() {
        isDrawing.toggle()
        if isDrawing {
            startNewPath()
        }
    }
}

struct DrawingCanvas: View {
    let paths: [DrawingPath]
    let eyePosition: CGPoint
    let showCursor: Bool
    let isDrawingMode: Bool
    
    var body: some View {
        Canvas { context, size in
            for path in paths {
                if path.points.count > 1 {
                    var pathBuilder = Path()
                    pathBuilder.move(to: path.points[0])
                    
                    for point in path.points.dropFirst() {
                        pathBuilder.addLine(to: point)
                    }
                    
                    context.stroke(pathBuilder, with: .color(path.color), lineWidth: 3)
                }
            }
            
            if showCursor {
                context.fill(
                    Path(ellipseIn: CGRect(x: eyePosition.x - 5, y: eyePosition.y - 5, width: 10, height: 10)),
                    with: .color(.blue.opacity(0.7))
                )
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var eyeTracker = EyeTrackingViewModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            DrawingCanvas(
                paths: eyeTracker.drawingPaths,
                eyePosition: eyeTracker.eyePosition,
                showCursor: true,
                isDrawingMode: eyeTracker.isDrawing
            )
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button("↻") {
                        eyeTracker.clearDrawing()
                    }
                    .foregroundColor(.white)
                    .font(.title2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.7))
                    .cornerRadius(8)
                }
                .padding()
                
                // Debug information
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status: \(eyeTracker.debugInfo)")
                        .foregroundColor(.yellow)
                        .font(.system(.caption, design: .monospaced))
                    Text("Eye Position: (\(Int(eyeTracker.eyePosition.x)), \(Int(eyeTracker.eyePosition.y)))")
                        .foregroundColor(.yellow)
                        .font(.system(.caption, design: .monospaced))
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .onAppear {
            eyeTracker.setupARSession()
        }
    }
}

#Preview {
    ContentView()
}
