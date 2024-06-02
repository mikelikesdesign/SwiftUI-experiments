//
//  ContentView.swift
//  shiny text
//
//  Created by Michael Lee on 6/2/24.
//

import SwiftUI
import SceneKit
import Shimmer

struct ContentView: View {
    var body: some View {
        ZStack {
            GlobeView()
                .background(Color.white)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                // Shimmer button
                Button(action: {
                    // Action for the button
                    print("Button tapped")
                }) {
                    ZStack {
                        Text("Generating Your Ideas")
                            .modifier(Shimmer())
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                    }
                    .frame(width: 308, height: 67)
                    .background(
                        LinearGradient(
                            stops: [
                                Gradient.Stop(color: .white, location: 0.00),
                                Gradient.Stop(color: Color(red: 0.99, green: 0.99, blue: 0.99), location: 1.00)
                            ],
                            startPoint: UnitPoint(x: 0, y: 0.5),
                            endPoint: UnitPoint(x: 1, y: 0.5)
                        )
                    )
                    .cornerRadius(100)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 100)
                            .inset(by: 0.5)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.5), Color.clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 100))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 10)
                    )
                }
                .padding(.bottom, 32)
            }
        }
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
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = createGlobeScene()
        scnView.backgroundColor = UIColor.white
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = true
        scnView.frame = UIScreen.main.bounds

        // Update the texture more frequently for smoother animation
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            scnView.scene?.rootNode.childNodes.first?.geometry?.firstMaterial?.diffuse.contents = self.createTextTexture()
        }

        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        // Update the view if needed.
    }

    private func createGlobeScene() -> SCNScene {
        let scene = SCNScene()
        let globeNode = SCNNode(geometry: SCNSphere(radius: 150)) // Set radius to 150 (diameter 300px)
        globeNode.position = SCNVector3(x: 0, y: 0, z: 0)

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.lightGray // Changed to very light grey
        globeNode.geometry?.materials = [material]
        
        scene.rootNode.addChildNode(globeNode)
        return scene
    }

    private func createTextTexture() -> UIImage {
        let size = CGSize(width: 1024, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let rectangle = CGRect(origin: .zero, size: size)
            ctx.cgContext.setFillColor(UIColor.black.cgColor)
            ctx.cgContext.addRect(rectangle)
            ctx.cgContext.drawPath(using: .fill)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left

            for _ in 0..<1000 {
                let randomString = String((0..<1).map{ _ in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
                let randomX = CGFloat.random(in: 0..<size.width)
                let randomY = CGFloat.random(in: 0..<size.height)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16),
                    .paragraphStyle: paragraphStyle,
                    .foregroundColor: UIColor.white.withAlphaComponent(Bool.random() ? 0.1 : 1.0)
                ]
                randomString.draw(with: CGRect(x: randomX, y: randomY, width: 20, height: 20), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
