//
//  ContentView.swift
//  adaptive text
//
//  Created by @mikelikesdesign on 2/10/26.
//

import SwiftUI
import ARKit

extension AnyTransition {
    static var vaporize: AnyTransition {
        .modifier(
            active: VaporizeModifier(progress: 1),
            identity: VaporizeModifier(progress: 0)
        )
    }
}

struct VaporizeModifier: ViewModifier {
    let progress: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(1 + (progress * 0.5))
            .opacity(1 - progress)
    }
}

enum SizeLevel: CaseIterable {
    case small, mediumSmall, medium, mediumLarge, large

    var fontSize: CGFloat {
        switch self {
        case .small: return 17
        case .mediumSmall: return 24
        case .medium: return 32
        case .mediumLarge: return 42
        case .large: return 54
        }
    }

    static func from(distance: Float) -> SizeLevel {
        switch distance {
        case ..<0.30: return .small
        case 0.30..<0.38: return .mediumSmall
        case 0.38..<0.46: return .medium
        case 0.46..<0.54: return .mediumLarge
        default: return .large
        }
    }
}

@Observable
final class FaceDistanceTracker: NSObject, ARSessionDelegate {
    var distance: Float = 0.5
    var isTracking = false
    var isSupported = ARFaceTrackingConfiguration.isSupported

    private let session = ARSession()
    private let smoothing: Float = 0.15

    override init() {
        super.init()
        session.delegate = self
    }

    func start() {
        guard isSupported else { return }
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = false
        session.run(config)
    }

    func stop() {
        session.pause()
    }

    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
        let faceDistance = -faceAnchor.transform.columns.3.z
        Task { @MainActor in
            self.distance = self.distance + self.smoothing * (faceDistance - self.distance)
            self.isTracking = true
        }
    }

    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor in
            self.isTracking = false
        }
    }
}

struct ContentView: View {
    @State private var tracker = FaceDistanceTracker()
    @State private var currentLevel: SizeLevel = .medium

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                ForEach(SizeLevel.allCases, id: \.self) { level in
                    if level == currentLevel {
                        Text("This text adapts its size based on how far away your face is.")
                            .font(.system(size: level.fontSize, weight: .medium))
                            .multilineTextAlignment(.center)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .offset(y: 20)),
                                removal: .offset(y: -60)
                                    .combined(with: .vaporize)
                                    .combined(with: .opacity)
                            ))
                            .zIndex(level == currentLevel ? 1 : 0)
                    }
                }
            }
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: currentLevel)
            .clipped()
            .frame(maxWidth: .infinity, minHeight: 200)
        }
        .padding()
        .onAppear {
            tracker.start()
        }
        .onDisappear {
            tracker.stop()
        }
        .onChange(of: tracker.distance) { _, newDistance in
            let newLevel = SizeLevel.from(distance: newDistance)
            if newLevel != currentLevel {
                withAnimation(.interactiveSpring) {
                    currentLevel = newLevel
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
