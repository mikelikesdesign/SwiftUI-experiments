import SwiftUI
import SceneKit

struct ContentView: View {
    @State private var searchText = ""

    var body: some View {
            ZStack {
                GlobeView()
                    .background(Color.black)
                    .edgesIgnoringSafeArea(.all)

                // Custom styled TextField with blurred background
                ZStack(alignment: .leading) {
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark) // Blurred background
                        .frame(width: UIScreen.main.bounds.width * 0.8, height: 54)
                        .cornerRadius(100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 100)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )

                    TextField("Search...", text: $searchText)
                        .font(.system(size: 16))
                        .padding(.leading, 15)
                        .frame(width: UIScreen.main.bounds.width * 0.8, height: 54)
                }
                .padding()
            }
        }
    }

    // VisualEffectBlur
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
        scnView.backgroundColor = UIColor.black
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
        let globeNode = SCNNode(geometry: SCNSphere(radius: 1.0))
        globeNode.position = SCNVector3(x: 0, y: 0, z: 0)

        let material = SCNMaterial()
        material.diffuse.contents = createTextTexture()
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

// BlurView for the glassy effect
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
