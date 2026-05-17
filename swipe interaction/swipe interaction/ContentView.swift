//
//  ContentView.swift
//  swipe interaction
//
//  Created by Michael Lee on 12/9/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        CubeStoriesViewRepresentable()
            .ignoresSafeArea()
    }
}

// MARK: - UIKit Bridge

private struct CubeStoriesViewRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CubeStoriesViewController {
        CubeStoriesViewController()
    }

    func updateUIViewController(_ uiViewController: CubeStoriesViewController, context: Context) {}
}

// MARK: - Simple model

private struct Story {
    let imageName: String
}

// MARK: - Custom Story View

private final class StoryCardView: UIView {

    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        layer.masksToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(with story: Story) {
        imageView.image = UIImage(named: story.imageName)
    }
}

// MARK: - Cube Scroll View

private final class CubeScrollView: UIScrollView, UIScrollViewDelegate {

    private let maxAngle: CGFloat = 60.0
    private let perspectiveDepth: CGFloat = 500.0
    private var childViews: [UIView] = []
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = .black
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        isPagingEnabled = true
        bounces = true
        delegate = self

        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: frameLayoutGuide.heightAnchor)
        ])
    }

    func addChildViews(_ views: [UIView]) {
        for view in views {
            view.layer.masksToBounds = true
            stackView.addArrangedSubview(view)

            view.translatesAutoresizingMaskIntoConstraints = false
            view.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor).isActive = true

            childViews.append(view)
        }
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        transformViews()
    }

    // MARK: - Cube Transform Logic

    private func transformViews() {
        let xOffset = contentOffset.x
        let svWidth = frame.width

        guard svWidth > 0 else { return }

        for (index, view) in childViews.enumerated() {
            // Calculate angle based on scroll position
            var deg = maxAngle / svWidth * xOffset
            deg = index == 0 ? deg : deg - (CGFloat(index) * maxAngle)

            let rad = deg * .pi / 180

            // Apply 3D transform
            var transform = CATransform3DIdentity
            transform.m34 = 1.0 / perspectiveDepth
            transform = CATransform3DRotate(transform, rad, 0, 1, 0)
            view.layer.transform = transform

            // Dynamic anchor point - key to the cube effect!
            // When we've scrolled past a view, anchor on right edge (1.0)
            // Otherwise anchor on left edge (0.0)
            let anchorX: CGFloat = (xOffset / svWidth) > CGFloat(index) ? 1.0 : 0.0
            setAnchorPoint(CGPoint(x: anchorX, y: 0.5), for: view)

            applyVisibilityFade(for: view, at: index)
        }
    }

    private func setAnchorPoint(_ anchorPoint: CGPoint, for view: UIView) {
        let oldAnchor = view.layer.anchorPoint
        guard oldAnchor != anchorPoint else { return }

        var newPoint = CGPoint(
            x: view.bounds.width * anchorPoint.x,
            y: view.bounds.height * anchorPoint.y
        )
        var oldPoint = CGPoint(
            x: view.bounds.width * oldAnchor.x,
            y: view.bounds.height * oldAnchor.y
        )

        newPoint = newPoint.applying(view.transform)
        oldPoint = oldPoint.applying(view.transform)

        var position = view.layer.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        position.y -= oldPoint.y
        position.y += newPoint.y

        view.layer.position = position
        view.layer.anchorPoint = anchorPoint
    }

    private func applyVisibilityFade(for view: UIView, at index: Int) {
        let w = frame.width
        let h = frame.height

        let r1 = CGRect(origin: contentOffset, size: frame.size)
        let r2 = CGRect(x: CGFloat(index) * w, y: 0, width: w, height: h)

        // Only fade the right-hand side view.
        if r1.origin.x <= r2.origin.x {
            let intersection = r1.intersection(r2)
            let intArea = intersection.width * intersection.height
            let unionArea = r1.union(r2).width * r1.union(r2).height

            if unionArea > 0 {
                view.layer.opacity = Float(intArea / unionArea)
            }
        } else {
            view.layer.opacity = 1.0
        }
    }
}

// MARK: - View Controller

private final class CubeStoriesViewController: UIViewController {

    private let stories: [Story] = [
        Story(imageName: "ramen"),
        Story(imageName: "steak"),
        Story(imageName: "Tokyo")
    ]

    private let cubeView = CubeScrollView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCubeView()
    }

    private func setupCubeView() {
        cubeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cubeView)

        NSLayoutConstraint.activate([
            cubeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cubeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cubeView.topAnchor.constraint(equalTo: view.topAnchor),
            cubeView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Create story views
        let storyViews = stories.map { story -> StoryCardView in
            let cardView = StoryCardView()
            cardView.configure(with: story)
            return cardView
        }

        cubeView.addChildViews(storyViews)
    }
}

#Preview {
    ContentView()
}
