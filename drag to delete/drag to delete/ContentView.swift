//
//  ContentView.swift
//  drag to delete
//
//  Created by Michael Lee on 5/26/24.
//

import SwiftUI

/// Drag the image onto the trash target at the bottom of the screen to delete it.
struct ContentView: View {
    private enum Phase: Equatable {
        case idle
        case dragging(CGPoint)
        case deleting
    }

    private enum Metrics {
        static let restingImageSize: CGFloat = 320
        static let restingImageTop: CGFloat = 144
        static let maxDraggingImageSize: CGFloat = 160
        static let minDraggingImageSize: CGFloat = 32
        static let minTrashDiameter: CGFloat = 64
        static let maxTrashDiameter: CGFloat = 92
        /// Fraction of the distance to the trash past which releasing deletes the image.
        static let deleteThreshold: CGFloat = 0.7
    }

    @State private var phase: Phase = .idle

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let progress = progress(in: size)

            ZStack(alignment: .bottom) {
                if case .dragging = phase {
                    TrashTarget(diameter: trashDiameter(progress: progress))
                        // Fixed slot so the circle grows outward from a stable center.
                        .frame(width: Metrics.maxTrashDiameter, height: Metrics.maxTrashDiameter)
                        .transition(
                            .asymmetric(
                                insertion: .scale.animation(.snappy(duration: 0.2)),
                                removal: .scale.animation(.easeInOut(duration: 0.5))
                            )
                        )
                }

                if phase != .deleting {
                    let imageSize = imageSize(progress: progress)
                    Image("colors")
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageSize, height: imageSize)
                        .animation(.spring(dampingFraction: 0.7), value: imageSize)
                        .position(imagePosition(in: size))
                        .gesture(dragGesture(in: size))
                        .accessibilityLabel("Colorful brick wall")
                        .accessibilityAction(named: "Delete") { delete() }
                        .transition(.identity)
                }
            }
            .frame(width: size.width, height: size.height, alignment: .bottom)
        }
        .background(.white)
        .task(id: phase == .deleting) {
            guard phase == .deleting else { return }
            try? await Task.sleep(for: .seconds(1))
            phase = .idle
        }
    }

    // MARK: - Gesture

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                phase = .dragging(value.location)
            }
            .onEnded { _ in
                if progress(in: size) >= Metrics.deleteThreshold {
                    delete()
                } else {
                    withAnimation(.spring(dampingFraction: 0.7)) {
                        phase = .idle
                    }
                }
            }
    }

    private func delete() {
        phase = .deleting
    }

    // MARK: - Derived layout

    /// How far the dragged image has travelled toward the trash, from 0 (top) to 1 (trash).
    private func progress(in size: CGSize) -> CGFloat {
        guard case .dragging(let location) = phase else { return 0 }
        let trashCenterY = size.height - Metrics.maxTrashDiameter / 2
        guard trashCenterY > 0 else { return 0 }
        return min(1, max(0, location.y / trashCenterY))
    }

    private func imagePosition(in size: CGSize) -> CGPoint {
        if case .dragging(let location) = phase {
            return location
        }
        return CGPoint(x: size.width / 2, y: Metrics.restingImageTop + Metrics.restingImageSize / 2)
    }

    private func imageSize(progress: CGFloat) -> CGFloat {
        guard case .dragging = phase else { return Metrics.restingImageSize }
        let range = Metrics.maxDraggingImageSize - Metrics.minDraggingImageSize
        return Metrics.maxDraggingImageSize - range * progress
    }

    private func trashDiameter(progress: CGFloat) -> CGFloat {
        let range = Metrics.maxTrashDiameter - Metrics.minTrashDiameter
        return Metrics.minTrashDiameter + range * progress
    }
}

/// The black circular drop target with a trash icon.
private struct TrashTarget: View {
    let diameter: CGFloat

    var body: some View {
        Circle()
            .fill(.black)
            .frame(width: diameter, height: diameter)
            .overlay {
                Image("trash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    ContentView()
}
