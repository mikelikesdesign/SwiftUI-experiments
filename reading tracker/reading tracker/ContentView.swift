//
//  ContentView.swift
//  reading tracker
//
//  Created by Michael Lee on 5/8/24.
//

import SwiftUI

struct ContentView: View {
    let paragraphs: [String] = [
        "Prototyping is an essential part of the design process that offers numerous benefits. It allows designers to quickly and efficiently test their ideas, gather feedback, and make improvements before investing significant time and resources into the final product. By creating a tangible representation of the concept, prototyping enables designers to communicate their vision more effectively to stakeholders and collaborators.",
        "One of the key advantages of prototyping is that it facilitates iterative design. Through prototyping, designers can experiment with different layouts, interactions, and user flows, and identify potential usability issues early on. This iterative approach helps refine the design, ensuring that the final product meets user needs and expectations. Prototyping also allows for user testing and validation, providing valuable insights into how users interact with the product and highlighting areas for improvement.",
        "Prototyping is a powerful tool for collaboration and communication. It serves as a common language between designers, developers, and other team members, making it easier to align everyone's understanding of the product. By sharing prototypes with stakeholders, designers can gather valuable feedback, address concerns, and ensure that the product aligns with business goals and user requirements. Prototyping also facilitates effective communication with clients, enabling them to visualize the product and provide input throughout the design process.",
        "In addition to its collaborative benefits, prototyping can save time and resources in the long run. By identifying and addressing design issues early in the process, prototyping reduces the risk of costly mistakes and delays later on. It allows designers to validate their ideas and make informed decisions before committing to full-scale development. Prototyping also helps in prioritizing features and functionality, ensuring that the most critical aspects of the product are developed first.",
        "Prototyping is a versatile tool that can be applied across various industries and project types. Whether designing a mobile app, website, or physical product, prototyping enables designers to explore different possibilities and find the most effective solutions. It fosters creativity and innovation by allowing designers to experiment with new ideas and push the boundaries of what's possible. Ultimately, prototyping leads to better-designed products that meet user needs, enhance user satisfaction, and drive business success.",
        "Moreover, prototyping plays a crucial role in user-centered design. By creating interactive prototypes, designers can gather valuable user feedback early in the design process. This feedback helps identify usability issues, validate design assumptions, and iterate on the design based on user insights. Prototyping allows designers to test different scenarios and user flows, ensuring that the final product provides a seamless and intuitive user experience.",
        "Prototyping also enables designers to communicate their ideas more effectively to development teams. By providing a tangible representation of the design, prototypes help bridge the gap between design and development. Developers can use prototypes as a reference to understand the desired functionality, interactions, and visual elements of the product. This collaboration between designers and developers streamlines the development process and reduces the chances of misinterpretation or miscommunication.",
        "In summary, prototyping is a valuable tool that offers numerous benefits throughout the design process. It facilitates iterative design, enables collaboration and communication, saves time and resources, fosters creativity, and ensures user-centered design. By embracing prototyping, designers can create better products that meet user needs and drive business success. As the field of design continues to evolve, prototyping remains an essential skill for designers to master and leverage in their work."
    ]
    
    @State private var scrollPercentage: Double = 0.0
    @State private var showParticles: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewWrapper(scrollPercentage: $scrollPercentage) {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(paragraphs, id: \.self) { paragraph in
                        Text(paragraph)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 16)
                    }
                    
                    Spacer(minLength: 80)
                }
                .background(Color.white)
                .foregroundColor(.black)
            }
            
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    LinearGradient(gradient: Gradient(colors: [Color(red: 0.4, green: 0.6, blue: 1), Color(red: 0.2, green: 0.8, blue: 1)]), startPoint: .leading, endPoint: .trailing)
                        .frame(height: 3)
                        .frame(width: scrollPercentage / 100 * geometry.size.width)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 3)
                
                HStack {
                    Text(scrollStatusText())
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(max(0, Int(scrollPercentage)))%")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                .padding(.bottom, 12)
            }
            .background(Color.black)
            
            if showParticles {
                ParticleView()
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .onChange(of: scrollPercentage) { value in
            if value >= 100 && !showParticles {
                showParticles = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showParticles = false
                    }
                }
            }
        }
    }
    
    private func scrollStatusText() -> String {
        switch scrollPercentage {
        case ...0:
            return "Enjoy the post"
        case 1..<25:
            return "You know the basics of prototyping"
        case 25..<50:
            return "You are intermediate with prototyping"
        case 50..<75:
            return "You are an expert at prototyping"
        case 75..<100:
            return "Almost finished the post"
        default:
            return "Congratulations on finishing the post"
        }
    }
}

struct ParticleView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        emitter.emitterShape = .circle
        emitter.emitterSize = CGSize(width: 100, height: 100)
        
        let cell = CAEmitterCell()
        cell.birthRate = 30
        cell.lifetime = 3
        cell.velocity = 200
        cell.velocityRange = 50
        cell.emissionRange = .pi * 2
        cell.scale = 0.1
        cell.scaleRange = 0.2
        cell.contents = getEmojiImage(emoji: "👏")
        
        emitter.emitterCells = [cell]
        
        view.layer.addSublayer(emitter)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    private func getEmojiImage(emoji: String) -> CGImage? {
        let size = CGSize(width: 50, height: 50) // Increase the size by 25%
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        let rect = CGRect(origin: .zero, size: size)
        (emoji as NSString).draw(in: rect, withAttributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 50) // Increase the font size by 25%
        ])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image?.cgImage
    }
}

struct ScrollViewWrapper<Content: View>: UIViewRepresentable {
    @Binding var scrollPercentage: Double
    var content: () -> Content
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        
        let hostingController = UIHostingController(rootView: content())
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // No-op
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ScrollViewWrapper
        
        init(_ parent: ScrollViewWrapper) {
            self.parent = parent
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let contentHeight = scrollView.contentSize.height
            let scrollOffset = scrollView.contentOffset.y
            let visibleHeight = scrollView.frame.height
            
            guard contentHeight > visibleHeight else {
                parent.scrollPercentage = 0
                return
            }
            
            let scrollableHeight = contentHeight - visibleHeight
            let scrollProgress = scrollOffset / scrollableHeight
            parent.scrollPercentage = min(scrollProgress * 100, 100)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
