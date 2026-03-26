//
//  ContentView.swift
//  reading tracker
//
//  Created by Michael Lee on 5/8/24.
//

import SwiftUI

struct ContentView: View {
    private static let articleParagraphs: [String] = [
        "Prototyping is an essential part of the design process that offers numerous benefits. It allows designers to quickly and efficiently test their ideas, gather feedback, and make improvements before investing significant time and resources into the final product. By creating a tangible representation of the concept, prototyping enables designers to communicate their vision more effectively to stakeholders and collaborators.",
        "One of the key advantages of prototyping is that it facilitates iterative design. Through prototyping, designers can experiment with different layouts, interactions, and user flows, and identify potential usability issues early on. This iterative approach helps refine the design, ensuring that the final product meets user needs and expectations. Prototyping also allows for user testing and validation, providing valuable insights into how users interact with the product and highlighting areas for improvement.",
        "Prototyping is a powerful tool for collaboration and communication. It serves as a common language between designers, developers, and other team members, making it easier to align everyone's understanding of the product. By sharing prototypes with stakeholders, designers can gather valuable feedback, address concerns, and ensure that the product aligns with business goals and user requirements. Prototyping also facilitates effective communication with clients, enabling them to visualize the product and provide input throughout the design process.",
        "In addition to its collaborative benefits, prototyping can save time and resources in the long run. By identifying and addressing design issues early in the process, prototyping reduces the risk of costly mistakes and delays later on. It allows designers to validate their ideas and make informed decisions before committing to full-scale development. Prototyping also helps in prioritizing features and functionality, ensuring that the most critical aspects of the product are developed first.",
        "Prototyping is a versatile tool that can be applied across various industries and project types. Whether designing a mobile app, website, or physical product, prototyping enables designers to explore different possibilities and find the most effective solutions. It fosters creativity and innovation by allowing designers to experiment with new ideas and push the boundaries of what's possible. Ultimately, prototyping leads to better-designed products that meet user needs, enhance user satisfaction, and drive business success.",
        "Moreover, prototyping plays a crucial role in user-centered design. By creating interactive prototypes, designers can gather valuable user feedback early in the design process. This feedback helps identify usability issues, validate design assumptions, and iterate on the design based on user insights. Prototyping allows designers to test different scenarios and user flows, ensuring that the final product provides a seamless and intuitive user experience.",
        "Prototyping also enables designers to communicate their ideas more effectively to development teams. By providing a tangible representation of the design, prototypes help bridge the gap between design and development. Developers can use prototypes as a reference to understand the desired functionality, interactions, and visual elements of the product. This collaboration between designers and developers streamlines the development process and reduces the chances of misinterpretation or miscommunication.",
        "In summary, prototyping is a valuable tool that offers numerous benefits throughout the design process. It facilitates iterative design, enables collaboration and communication, saves time and resources, fosters creativity, and ensures user-centered design. By embracing prototyping, designers can create better products that meet user needs and drive business success. As the field of design continues to evolve, prototyping remains an essential skill for designers to master and leverage in their work."
    ]

    private enum Layout {
        static let paragraphSpacing: CGFloat = 20
        static let horizontalPadding: CGFloat = 16
        static let bottomSpacerHeight: CGFloat = 80
        static let progressBarHeight: CGFloat = 3
        static let statusVerticalPadding: CGFloat = 16
        static let statusBottomPadding: CGFloat = 12
        static let progressGradient: [Color] = [
            Color(red: 0.4, green: 0.6, blue: 1),
            Color(red: 0.2, green: 0.8, blue: 1)
        ]
    }

    private enum Celebration {
        static let completionThreshold = 100.0
        static let emissionDuration = 2.2
        static let fadeDuration = 1.2
    }

    @State private var scrollPercentage = 0.0
    @State private var particleOverlay = ParticleOverlayState.hidden
    @State private var celebrationTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottom) {
            articleView
            progressFooter

            if particleOverlay.isVisible {
                ParticleView(isEmitting: particleOverlay.isEmitting)
                    .opacity(particleOverlay.opacity)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: scrollPercentage) { _, newValue in
            guard newValue >= Celebration.completionThreshold, !particleOverlay.isVisible else {
                return
            }

            startCelebration()
        }
        .onDisappear {
            celebrationTask?.cancel()
            celebrationTask = nil
            particleOverlay = .hidden
        }
    }

    private var articleView: some View {
        ScrollViewWrapper(scrollPercentage: $scrollPercentage) {
            VStack(alignment: .leading, spacing: Layout.paragraphSpacing) {
                ForEach(Array(Self.articleParagraphs.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, Layout.horizontalPadding)
                }

                Spacer(minLength: Layout.bottomSpacerHeight)
            }
            .background(Color.white)
            .foregroundColor(.black)
        }
    }

    private var progressFooter: some View {
        VStack(spacing: 0) {
            progressBar
            progressStatus
        }
        .background(Color.black)
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: Layout.progressGradient,
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: Layout.progressBarHeight)
            .frame(width: clampedScrollPercentage / 100 * geometry.size.width)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: Layout.progressBarHeight)
    }

    private var progressStatus: some View {
        HStack {
            Text(scrollStatusText(for: clampedScrollPercentage))
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            Text("\(Int(clampedScrollPercentage))%")
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding(.horizontal)
        .padding(.vertical, Layout.statusVerticalPadding)
        .padding(.bottom, Layout.statusBottomPadding)
    }

    private var clampedScrollPercentage: Double {
        scrollPercentage.clamped(to: 0...100)
    }

    private func startCelebration() {
        celebrationTask?.cancel()
        particleOverlay = .active

        celebrationTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(Celebration.emissionDuration))
            guard !Task.isCancelled else {
                return
            }

            particleOverlay.isEmitting = false

            withAnimation(.easeOut(duration: Celebration.fadeDuration)) {
                particleOverlay.opacity = 0
            }

            try? await Task.sleep(for: .seconds(Celebration.fadeDuration))
            guard !Task.isCancelled else {
                return
            }

            particleOverlay = .hidden
            celebrationTask = nil
        }
    }

    private func scrollStatusText(for progress: Double) -> String {
        switch progress {
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

private struct ParticleOverlayState {
    var isVisible = false
    var isEmitting = false
    var opacity = 1.0

    static let hidden = Self()
    static let active = Self(isVisible: true, isEmitting: true, opacity: 1.0)
}

struct ParticleView: UIViewRepresentable {
    private enum Configuration {
        static let emitterSize = CGSize(width: 100, height: 100)
        static let particleImageSize = CGSize(width: 50, height: 50)
        static let particleFontSize: CGFloat = 50
        static let birthRate: Float = 30
        static let lifetime: Float = 3
        static let velocity: CGFloat = 200
        static let velocityRange: CGFloat = 50
        static let scale: CGFloat = 0.1
        static let scaleRange: CGFloat = 0.2
        static let emoji = "👏"
    }

    var isEmitting: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false

        let emitter = context.coordinator.emitter
        emitter.emitterCells = [makeEmitterCell()]
        updateEmitterLayout(emitter, in: view.bounds)
        emitter.birthRate = isEmitting ? 1 : 0

        view.layer.addSublayer(emitter)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let emitter = context.coordinator.emitter
        updateEmitterLayout(emitter, in: uiView.bounds)
        emitter.birthRate = isEmitting ? 1 : 0
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func updateEmitterLayout(_ emitter: CAEmitterLayer, in bounds: CGRect) {
        let referenceBounds = bounds.isEmpty ? UIScreen.main.bounds : bounds
        emitter.emitterPosition = CGPoint(x: referenceBounds.midX, y: referenceBounds.midY)
        emitter.emitterShape = .circle
        emitter.emitterSize = Configuration.emitterSize
    }

    private func makeEmitterCell() -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = Configuration.birthRate
        cell.lifetime = Configuration.lifetime
        cell.velocity = Configuration.velocity
        cell.velocityRange = Configuration.velocityRange
        cell.emissionRange = .pi * 2
        cell.scale = Configuration.scale
        cell.scaleRange = Configuration.scaleRange
        cell.contents = makeEmojiImage(emoji: Configuration.emoji)
        return cell
    }

    private func makeEmojiImage(emoji: String) -> CGImage? {
        UIGraphicsBeginImageContextWithOptions(Configuration.particleImageSize, false, 0)
        defer { UIGraphicsEndImageContext() }

        let rect = CGRect(origin: .zero, size: Configuration.particleImageSize)
        (emoji as NSString).draw(
            in: rect,
            withAttributes: [
                .font: UIFont.systemFont(ofSize: Configuration.particleFontSize)
            ]
        )

        return UIGraphicsGetImageFromCurrentImageContext()?.cgImage
    }

    final class Coordinator {
        let emitter = CAEmitterLayer()
    }
}

struct ScrollViewWrapper<Content: View>: UIViewRepresentable {
    @Binding var scrollPercentage: Double
    private let content: Content

    init(scrollPercentage: Binding<Double>, @ViewBuilder content: () -> Content) {
        _scrollPercentage = scrollPercentage
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator

        let hostedView = context.coordinator.hostingController.view
        hostedView?.translatesAutoresizingMaskIntoConstraints = false
        hostedView?.backgroundColor = .clear

        if let hostedView {
            scrollView.addSubview(hostedView)

            NSLayoutConstraint.activate([
                hostedView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                hostedView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                hostedView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                hostedView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                hostedView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
            ])
        }

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.scrollPercentage = $scrollPercentage
        context.coordinator.hostingController.rootView = content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scrollPercentage: $scrollPercentage, content: content)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var scrollPercentage: Binding<Double>
        let hostingController: UIHostingController<Content>

        init(scrollPercentage: Binding<Double>, content: Content) {
            self.scrollPercentage = scrollPercentage
            self.hostingController = UIHostingController(rootView: content)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            scrollPercentage.wrappedValue = scrollProgress(for: scrollView)
        }

        private func scrollProgress(for scrollView: UIScrollView) -> Double {
            let contentHeight = scrollView.contentSize.height
            let visibleHeight = scrollView.bounds.height

            guard contentHeight > visibleHeight else {
                return 0
            }

            let scrollableHeight = contentHeight - visibleHeight
            let scrollProgress = (scrollView.contentOffset.y / scrollableHeight).clamped(to: 0...1)
            return scrollProgress * 100
        }
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
