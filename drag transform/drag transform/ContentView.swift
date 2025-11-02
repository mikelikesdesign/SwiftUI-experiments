//
//  ContentView.swift
//  drag transform
//
//  Created by https://github.com/mikelikesdesign
//

import SwiftUI

struct DraggableShape: View {
    @State private var position = CGPoint(x: 150, y: 150)
    @State private var isDragging = false
    @State private var dockedEdge: Edge? = .bottom
    @State private var containerSize = CGSize(width: 345, height: 82)
    @State private var containerCornerRadius: CGFloat = 28
    @Namespace private var iconNamespace

    let iconNames = ["icon_1", "icon_2", "icon_3", "icon_4"]
    private let draggingSize = CGSize(width: 96, height: 96)
    private let draggingCornerRadius: CGFloat = 40
    private let dragIconSize: CGFloat = 60

    var body: some View {
        GeometryReader { geometry in
            Image("bg")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)

            ZStack {
                if isDragging {
                    dropIndicators(for: geometry.size)
                        .transition(.opacity)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: containerCornerRadius)
                        .frame(width: containerSize.width, height: containerSize.height)
                        .foregroundColor(.clear)
                        .background(
                            BlurBackground(
                                darken: true,
                                additionalOpacity: 0.20,
                                cornerRadius: containerCornerRadius
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: containerCornerRadius)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .shadow(color: isDragging ? .gray : .clear, radius: isDragging ? 10 : 0)

                    // App icons layout
                    iconLayout()
                }
                .position(isDragging ? position : dockedPosition(for: geometry.size, offset: 8))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if !self.isDragging {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    self.isDragging = true
                                    self.containerSize = draggingSize
                                    self.containerCornerRadius = draggingCornerRadius
                                }
                            }
                            self.position = gesture.location
                        }
                        .onEnded { gesture in
                            let targetEdge = self.closestEdge(for: gesture.location, in: geometry.size)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                self.isDragging = false
                                self.dockedEdge = targetEdge
                                self.containerSize = self.dockedSize(for: targetEdge)
                                self.containerCornerRadius = 28
                            }
                        }
                )
            }
        }
        .edgesIgnoringSafeArea(dockedEdge != nil ? .all : [])
        .onAppear {
            containerSize = dockedSize(for: dockedEdge)
        }
    }

    @ViewBuilder
    private func iconLayout() -> some View {
        if isDragging {
            stackedIconLayout()
        } else {
            layoutForDockedState()
        }
    }

    private func stackedIconLayout() -> some View {
        ZStack {
            ForEach(Array(iconNames.enumerated()), id: \.element) { index, iconName in
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: dragIconSize, height: dragIconSize)
                    .matchedGeometryEffect(id: iconName, in: iconNamespace)
                    .offset(stackOffset(for: index))
                    .scaleEffect(1.0 - CGFloat(index) * 0.05)
                    .opacity(1.0 - Double(index) * 0.1)
                    .zIndex(Double(iconNames.count - index))
            }
        }
    }

    private func layoutForDockedState() -> some View {
        let edge = dockedEdge ?? .bottom
        let config = dockedLayoutConfig(for: edge)
        let iconSize = dockedIconSize(for: edge, config: config)
        return Group {
            if edge == .bottom {
                HStack(spacing: config.spacing) {
                    iconViews(iconSize: iconSize)
                }
                .padding(.horizontal, config.primaryPadding)
                .padding(.vertical, config.secondaryPadding)
            } else {
                VStack(spacing: config.spacing) {
                    iconViews(iconSize: iconSize)
                }
                .padding(.vertical, config.primaryPadding)
                .padding(.horizontal, config.secondaryPadding)
            }
        }
    }

    private func iconViews(iconSize: CGFloat) -> some View {
        ForEach(iconNames, id: \.self) { iconName in
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .matchedGeometryEffect(id: iconName, in: iconNamespace)
        }
    }

    private func stackOffset(for index: Int) -> CGSize {
        let verticalSpacing: CGFloat = -6
        let horizontalSpacing: CGFloat = 4
        let horizontalCentering = CGFloat(iconNames.count - 1) * horizontalSpacing / 2
        return CGSize(
            width: CGFloat(index) * horizontalSpacing - horizontalCentering,
            height: CGFloat(index) * verticalSpacing
        )
    }

    private func dockedIconSize(for edge: Edge, config: DockedLayoutConfig) -> CGFloat {
        let primaryLength = (edge == .bottom ? containerSize.width : containerSize.height) - (config.primaryPadding * 2)
        let secondaryLength = (edge == .bottom ? containerSize.height : containerSize.width) - (config.secondaryPadding * 2)
        let spacingTotal = config.spacing * CGFloat(max(iconNames.count - 1, 0))
        let perIconPrimary = (primaryLength - spacingTotal) / CGFloat(iconNames.count)
        let constrainedPrimary = max(perIconPrimary, 0)
        let constrainedSecondary = max(secondaryLength, 0)
        return max(min(constrainedPrimary, constrainedSecondary), 0)
    }

    private func closestEdge(for location: CGPoint, in size: CGSize) -> Edge? {
        let distances = [
            Edge.bottom: size.height - location.y,
            Edge.leading: location.x,
            Edge.trailing: size.width - location.x
        ]

        let closest = distances.min { $0.value < $1.value }
        return closest?.key
    }

    private func dockedSize(for edge: Edge?) -> CGSize {
        switch edge {
        case .bottom:
            return CGSize(width: 345, height: 82)
        case .leading, .trailing:
            return CGSize(width: 82, height: 345)
        case .none:
            return draggingSize
        }
    }

    private func dockedPosition(for size: CGSize, offset: CGFloat, edge: Edge? = nil) -> CGPoint {
        switch edge ?? dockedEdge {
        case .bottom:
            // Adjusted for 16px offset from the bottom
            return CGPoint(x: size.width / 2, y: size.height - offset - 41 - 16)
        case .leading:
            return CGPoint(x: offset + 41, y: size.height / 2)
        case .trailing:
            return CGPoint(x: size.width - offset - 41, y: size.height / 2)
        default:
            return position
        }
    }

    private func dropIndicators(for size: CGSize) -> some View {
        ZStack {
            ForEach([Edge.bottom, .leading, .trailing], id: \.self) { edge in
                let style = indicatorStyle(for: edge, in: size)
                let baseSize = dockedSize(for: edge)

                RoundedRectangle(cornerRadius: 40)
                    .stroke(Color.white.opacity(style.strokeOpacity), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(Color.white.opacity(style.fillOpacity))
                    )
                    .frame(
                        width: baseSize.width * style.scale,
                        height: baseSize.height * style.scale
                    )
                    .position(dockedPosition(for: size, offset: 8, edge: edge))
            }
        }
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.15), value: position)
    }

    private func indicatorStyle(for edge: Edge, in size: CGSize) -> (scale: CGFloat, fillOpacity: Double, strokeOpacity: Double) {
        let targetPoint = dockedPosition(for: size, offset: 8, edge: edge)
        let distance = hypot(position.x - targetPoint.x, position.y - targetPoint.y)
        let maxDistance = max(min(size.width, size.height) * 0.6, 1)
        let proximity = max(0, min(1, 1 - distance / maxDistance))

        let scale = 0.66 + 0.34 * proximity
        let fillOpacity = 0.06 + 0.10 * Double(proximity)
        let strokeOpacity = 0.10 + 0.12 * Double(proximity)

        return (scale, fillOpacity, strokeOpacity)
    }
}

struct BlurBackground: UIViewRepresentable {
    var darken: Bool
    var additionalOpacity: CGFloat
    var cornerRadius: CGFloat

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.backgroundColor = UIColor(white: darken ? 0.0 : 1.0, alpha: additionalOpacity)
        blurView.layer.cornerRadius = cornerRadius
        blurView.layer.masksToBounds = true
        return blurView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.backgroundColor = UIColor(white: darken ? 0.0 : 1.0, alpha: additionalOpacity)
        uiView.layer.cornerRadius = cornerRadius
    }
}

private struct DockedLayoutConfig {
    let primaryPadding: CGFloat
    let secondaryPadding: CGFloat
    let spacing: CGFloat
}

extension DraggableShape {
    private func dockedLayoutConfig(for edge: Edge) -> DockedLayoutConfig {
        switch edge {
        case .bottom:
            return DockedLayoutConfig(primaryPadding: 16, secondaryPadding: 10, spacing: 14)
        case .leading, .trailing:
            return DockedLayoutConfig(primaryPadding: 16, secondaryPadding: 10, spacing: 14)
        }
    }
}

enum Edge: CaseIterable {
    case bottom, leading, trailing
}

struct ContentView: View {
    var body: some View {
        DraggableShape()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
