//
//  ContentView.swift
//  AI globe
//
//  Created by @mikelikesdesign on 11/1/25.
//


import SwiftUI
import UIKit
import SceneKit
import QuartzCore
import simd

struct ContentView: View {
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool

            var body: some View {
                GeometryReader { geometry in
                    ZStack {
                        GlobeView {
                    dismissKeyboard()
                        }
                        .ignoresSafeArea()

                ZStack(alignment: .leading) {
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                        .frame(width: geometry.size.width * 0.8, height: 54)
                        .cornerRadius(100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 100)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )

                    if searchText.isEmpty {
                        Text("Search...")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.leading, 24)
                            .frame(width: geometry.size.width * 0.8, height: 54, alignment: .leading)
                    }

                    TextField("", text: $searchText)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .tint(Color.white.opacity(0.9))
                        .padding(.leading, 15)
                        .focused($isSearchFieldFocused)
                        .frame(width: geometry.size.width * 0.8, height: 54)
                        .accessibilityLabel("Search")
                }
                .padding()
                .colorScheme(.dark)
            }
            .background(Color.black.ignoresSafeArea())
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
            }
        }
    }

    @MainActor
    private func dismissKeyboard() {
        isSearchFieldFocused = false
#if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }
}

    struct VisualEffectBlur: UIViewRepresentable {
        var blurStyle: UIBlurEffect.Style

        func makeUIView(context: Context) -> UIVisualEffectView {
            return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        }

        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
            uiView.effect = UIBlurEffect(style: blurStyle)
        }
    }

struct GlobeView: UIViewRepresentable {
    var onSceneTapped: () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSceneTapped: onSceneTapped)
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = createGlobeScene()
        scnView.scene = scene
        scnView.backgroundColor = UIColor.black
        scnView.allowsCameraControl = true
        scnView.antialiasingMode = .multisampling4X
        if let globeNode = scene.rootNode.childNode(withName: "LetterGlobe", recursively: false) {
            scnView.defaultCameraController.target = globeNode.position
        }

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSceneTap(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = context.coordinator
        scnView.addGestureRecognizer(tapGesture)

        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
    }

    private func createGlobeScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.black

        let globeNode = SCNNode()
        globeNode.name = "LetterGlobe"
        scene.rootNode.addChildNode(globeNode)

        populateLetterGlobe(globeNode, radius: 1.08, latitudeBands: 22, longitudeBands: 36)
        recenterGlobe(node: globeNode)
        addLighting(to: scene)
        addRotationAnimation(to: globeNode)

        return scene
    }

    private func populateLetterGlobe(_ globeNode: SCNNode, radius: Float, latitudeBands: Int, longitudeBands: Int) {
        guard latitudeBands > 1, longitudeBands > 0 else { return }

        let glyphs = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        let warmPalette: [UIColor] = [
            UIColor.systemPink,
            UIColor.systemOrange,
            UIColor.systemYellow,
            UIColor.systemRed
        ]

        let coolPalette: [UIColor] = [
            UIColor.systemTeal,
            UIColor.systemBlue,
            UIColor.systemMint,
            UIColor.systemPurple,
            UIColor.systemCyan,
            UIColor.systemIndigo
        ]

        for lat in 0..<latitudeBands {
            let v = Float(lat) / Float(latitudeBands - 1)
            let theta = v * Float.pi

            let bandOffset = (lat % 2 == 0) ? 0.0 : (Float.pi / Float(longitudeBands))

            for lon in 0..<longitudeBands {
                if lat % 3 == 1 && lon % 2 == 1 { continue }

                let u = Float(lon) / Float(longitudeBands)
                let phi = u * (Float.pi * 2) + bandOffset

                let sinTheta = sin(theta)
                let x = radius * sinTheta * cos(phi)
                let y = radius * cos(theta)
                let z = radius * sinTheta * sin(phi)
                guard let glyph = glyphs.randomElement() else { continue }

                let isWarm = ((lat + lon) % 2 == 0)
                let palette = isWarm ? warmPalette : coolPalette
                guard let color = palette.randomElement() else { continue }
                let letterNode = makeLetterNode(for: glyph, color: color, isWarm: isWarm)

                let radialScale = 1 + Float.random(in: 0.0...0.02)
                let position = SIMD3<Float>(x * radialScale, y * radialScale, z * radialScale)
                letterNode.simdPosition = position

                let outwardNormal = simd_normalize(position)
                orientLetterNode(letterNode, normal: outwardNormal)
                let billboardConstraint = SCNBillboardConstraint()
                billboardConstraint.freeAxes = .Y
                letterNode.constraints = (letterNode.constraints ?? []) + [billboardConstraint]

                let baseScale: Float = 0.004
                let variance: Float = Float.random(in: -0.0008...0.0008)
                let scale = baseScale + variance
                letterNode.scale = SCNVector3(scale, scale, scale)

                globeNode.addChildNode(letterNode)
                attachTwinkleAnimation(to: letterNode, glyphs: glyphs, palette: palette)
            }
        }
    }

    private func makeLetterNode(for glyph: Character, color: UIColor, isWarm: Bool) -> SCNNode {
        let textGeometry = SCNText(string: String(glyph), extrusionDepth: 0.32)
        textGeometry.font = font(for: glyph)
        textGeometry.flatness = 0.01
        textGeometry.chamferRadius = 0.0
        applyColor(color, to: textGeometry, emissionAlpha: 0.15)

        let node = SCNNode(geometry: textGeometry)
        centerPivot(of: node)

        node.geometry?.firstMaterial?.lightingModel = .constant
        node.setValue(isWarm, forKey: "isWarm")
        return node
    }

    private func centerPivot(of node: SCNNode) {
        let (min, max) = node.boundingBox
        let pivotX = (min.x + max.x) * 0.5
        let pivotY = (min.y + max.y) * 0.5
        let pivotZ = (min.z + max.z) * 0.5
        node.pivot = SCNMatrix4MakeTranslation(pivotX, pivotY, pivotZ)
    }

    private func font(for glyph: Character) -> UIFont {
        if glyph == "0" || glyph == "A" {
            return UIFont.systemFont(ofSize: 24, weight: .medium)
        }
        return UIFont.monospacedSystemFont(ofSize: 24, weight: .medium)
    }

    private func applyColor(_ color: UIColor, to geometry: SCNText, emissionAlpha: CGFloat) {
        let emissionColor = color.withAlphaComponent(emissionAlpha)
        if geometry.materials.isEmpty {
            let material = SCNMaterial()
            configure(material: material, diffuse: color, emission: emissionColor)
            geometry.materials = [material]
            return
        }

        for material in geometry.materials {
            configure(material: material, diffuse: color, emission: emissionColor)
        }
    }

    private func configure(material: SCNMaterial, diffuse: UIColor, emission: UIColor) {
        material.diffuse.contents = diffuse
        material.emission.contents = emission
        material.metalness.contents = 0.0
        material.roughness.contents = 1.0
        material.specular.contents = UIColor.black
        material.shininess = 0.0
        material.lightingModel = .constant
        material.isDoubleSided = true
    }

    private func attachTwinkleAnimation(to node: SCNNode, glyphs: [Character], palette: [UIColor]) {
        let baseScale = node.scale.x
        let initialDelay = SCNAction.wait(duration: Double.random(in: 0.0...1.8))

        let updateGlyphAndColor = SCNAction.run { node in
            guard let text = node.geometry as? SCNText else { return }
            if let randomGlyph = glyphs.randomElement() {
                text.string = String(randomGlyph)
                text.font = font(for: randomGlyph)
                centerPivot(of: node)
            }
            if let randomColor = palette.randomElement() {
                applyColor(randomColor, to: text, emissionAlpha: 0.22)
            }
        }

        let pulseUp = SCNAction.scale(to: CGFloat(baseScale * 1.35), duration: 0.32)
        pulseUp.timingMode = .easeInEaseOut

        let pulseDown = SCNAction.scale(to: CGFloat(baseScale), duration: 0.45)
        pulseDown.timingMode = .easeInEaseOut

        let dimEmission = SCNAction.run { node in
            guard let text = node.geometry as? SCNText,
                  let currentColor = text.firstMaterial?.diffuse.contents as? UIColor else { return }
            let dimmed = currentColor.withAlphaComponent(0.14)
            for material in text.materials {
                material.emission.contents = dimmed
            }
        }

        let rest = SCNAction.wait(duration: Double.random(in: 0.9...2.6))

        let twinkle = SCNAction.sequence([
            rest,
            updateGlyphAndColor,
            pulseUp,
            pulseDown,
            dimEmission
        ])

        let loop = SCNAction.repeatForever(twinkle)
        node.runAction(SCNAction.sequence([initialDelay, loop]), forKey: "twinkle")
    }

    private func addLighting(to scene: SCNScene) {
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(white: 0.15, alpha: 1.0)
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)

        let rimLight = SCNLight()
        rimLight.type = .omni
        rimLight.color = UIColor.white
        rimLight.intensity = 1200
        rimLight.castsShadow = true
        let rimLightNode = SCNNode()
        rimLightNode.light = rimLight
        rimLightNode.position = SCNVector3(-2.5, 2.0, 2.0)
        scene.rootNode.addChildNode(rimLightNode)

        let fillLight = SCNLight()
        fillLight.type = .spot
        fillLight.color = UIColor.systemTeal
        fillLight.intensity = 800
        fillLight.spotOuterAngle = 120
        fillLight.castsShadow = false
        let fillLightNode = SCNNode()
        fillLightNode.light = fillLight
        fillLightNode.position = SCNVector3(2.5, -1.5, -2.5)
        fillLightNode.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(fillLightNode)
    }

    private func addRotationAnimation(to globeNode: SCNNode) {
        let rotation = CABasicAnimation(keyPath: "rotation")
        rotation.fromValue = NSValue(scnVector4: SCNVector4(0, 1, 0, 0))
        rotation.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, Float.pi * 2))
        rotation.duration = 24
        rotation.repeatCount = .infinity
        globeNode.addAnimation(rotation, forKey: "spin")
    }

    private func recenterGlobe(node: SCNNode) {
        let children = node.childNodes
        guard !children.isEmpty else {
            node.simdPosition = .zero
            node.simdPivot = matrix_identity_float4x4
            return
        }

        var accumulated = SIMD3<Float>.zero
        for child in children {
            accumulated += child.simdPosition
        }

        let centroid = accumulated / Float(children.count)
        if simd_length(centroid) < 1e-5 {
            node.simdPosition = .zero
            node.simdPivot = matrix_identity_float4x4
            return
        }

        node.pivot = SCNMatrix4MakeTranslation(-centroid.x, -centroid.y, -centroid.z)
        node.position = SCNVector3(centroid.x, centroid.y, centroid.z)
    }

    private func orientLetterNode(_ node: SCNNode, normal: SIMD3<Float>) {
        let outward = simd_normalize(normal)
        var up = SIMD3<Float>(0, 1, 0)
        if abs(simd_dot(outward, up)) > 0.92 {
            up = SIMD3<Float>(1, 0, 0)
        }

        let right = simd_normalize(simd_cross(up, outward))
        let adjustedUp = simd_normalize(simd_cross(outward, right))
        let rotationMatrix = float3x3(columns: (right, adjustedUp, -outward))
        node.simdOrientation = simd_quatf(rotationMatrix)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private let onSceneTapped: () -> Void

        init(onSceneTapped: @escaping () -> Void) {
            self.onSceneTapped = onSceneTapped
            super.init()
        }

        @objc func handleSceneTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended else { return }
            onSceneTapped()
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}



#Preview {
    ContentView()
}
