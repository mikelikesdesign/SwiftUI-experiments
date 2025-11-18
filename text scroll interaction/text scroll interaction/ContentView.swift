//
//  ContentView.swift
//  text scroll interaction
//
//  Created by @mikelikesdesign
//

import SwiftUI

struct ContentView: View {
    private let cylinderNames = [
        "sushi", "steak", "ramen",
        "burger", "pasta", "pizza"
    ]

    private let loopScreens: CGFloat = 200

    var body: some View {
        GeometryReader { screenProxy in
            ScrollView(showsIndicators: false) {
                CylinderInteractionSection(
                    names: cylinderNames,
                    loopScreens: loopScreens,
                    screenHeight: screenProxy.size.height
                )
            }
            .background(Color(red: 0.04, green: 0.08, blue: 0.28))
            .ignoresSafeArea()
            .coordinateSpace(name: "scroll")
        }
    }
}

private struct CylinderInteractionSection: View {
    let names: [String]
    let loopScreens: CGFloat
    let screenHeight: CGFloat

    var body: some View {
        let viewportHeight = screenHeight
        let sectionHeight = viewportHeight * max(loopScreens + 1, 2)
        let cycleHeight = max(viewportHeight * 0.9, 1)

        return GeometryReader { proxy in
            let frame = proxy.frame(in: .named("scroll"))
            let pinOffset = cylinderPinOffset(
                frame: frame,
                viewportHeight: viewportHeight,
                sectionHeight: sectionHeight
            )
            let scrollOffset = max(-frame.minY, 0)
            let rotation = cylinderRotation(
                scrollOffset: scrollOffset,
                cycleHeight: cycleHeight
            )

            CylinderTextStage(
                names: names,
                rotation: rotation,
                size: CGSize(width: proxy.size.width, height: viewportHeight)
            )
            .frame(width: proxy.size.width, height: viewportHeight)
            .offset(y: pinOffset - viewportHeight * 0.08)
        }
        .frame(height: sectionHeight)
    }
}

private struct CylinderTextStage: View {
    let names: [String]
    let rotation: CGFloat
    let size: CGSize

    var body: some View {
        let radius = min(size.width, size.height) * 0.4

        return ZStack {
            stageBackground

            CylinderTextWrapper(
                names: names,
                rotation: rotation,
                radius: radius,
                stageSize: size
            )
            .frame(width: size.width * 0.92, height: size.height * 0.85)
        }
        .frame(width: size.width, height: size.height)
    }

    private var stageBackground: some View {
        return Color(red: 0.04, green: 0.08, blue: 0.28)
            .frame(width: size.width, height: size.height)
    }
}

private struct CylinderTextWrapper: View {
    let names: [String]
    let rotation: CGFloat
    let radius: CGFloat
    let stageSize: CGSize
    private let perspective: CGFloat = 2500

    var body: some View {
        ZStack {
            ForEach(Array(names.enumerated()), id: \.offset) { index, name in
                CylinderTextItem(
                    name: name,
                    index: index,
                    total: names.count,
                    radius: radius,
                    rotation: rotation,
                    perspective: perspective,
                    stageSize: stageSize
                )
            }
        }
    }
}

private struct CylinderTextItem: View {
    let name: String
    let index: Int
    let total: Int
    let radius: CGFloat
    let rotation: CGFloat
    let perspective: CGFloat
    let stageSize: CGSize

    var body: some View {
        let fontSize = min(max(radius * 0.45, 32), 82)

        return Text(name.uppercased())
            .font(.system(size: fontSize, weight: .black, design: .rounded))
            .kerning(2)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .allowsTightening(true)
            .modifier(
                CylinderProjection(
                    index: index,
                    total: total,
                    radius: radius,
                    rotation: rotation,
                    perspective: perspective,
                    stageSize: stageSize
                )
            )
    }
}

private struct CylinderProjection: ViewModifier {
    let index: Int
    let total: Int
    let radius: CGFloat
    let rotation: CGFloat
    let perspective: CGFloat
    let stageSize: CGSize

    func body(content: Content) -> some View {
        let safeTotal = max(total, 1)
        let spacing = .pi / CGFloat(safeTotal)
        let baseAngle = spacing * CGFloat(index % safeTotal)
        let angle = baseAngle + rotation
        let y = sin(angle) * radius
        let z = cos(angle) * radius
        let tilt: CGFloat = 0
        let textWidth = stageSize.width * 0.85
        let textHeight = max(stageSize.height * 0.09, 48)

        var transform = CATransform3DIdentity
        transform.m34 = -1 / perspective
        transform = CATransform3DTranslate(transform, 0, y, z)
        transform = CATransform3DRotate(transform, tilt, 1, 0, 0)

        let depthRatio = ((z / radius) + 1) / 2
        let clampedDepth = max(0, min(1, depthRatio))
        let opacity = 0.25 + 0.75 * clampedDepth
        let blurRadius = (1 - clampedDepth) * 1.5

        return content
            .frame(width: textWidth, height: textHeight, alignment: .center)
            .minimumScaleFactor(0.7)
            .projectionEffect(ProjectionTransform(transform))
            .position(x: stageSize.width / 2, y: stageSize.height / 2)
            .zIndex(Double(z))
            .opacity(opacity)
            .blur(radius: blurRadius)
    }
}

private func cylinderRotation(scrollOffset: CGFloat, cycleHeight: CGFloat) -> CGFloat {
    guard cycleHeight > 0 else { return 0 }
    return (scrollOffset / cycleHeight) * 2 * .pi
}

private func cylinderPinOffset(frame: CGRect, viewportHeight: CGFloat, sectionHeight: CGFloat) -> CGFloat {
    let pinDistance = max(sectionHeight - viewportHeight, 0)
    guard pinDistance > 0 else { return 0 }
    return min(max(-frame.minY, 0), pinDistance)
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    ContentView()
}
