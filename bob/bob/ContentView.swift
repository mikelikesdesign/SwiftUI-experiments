//
//  ContentView.swift
//  bob
//
//  Created by Michael Lee on 5/11/24.
//

import SwiftUI

private enum BobCoordinateSpace {
    static let root = "BobCoordinateSpace"
}

struct ContentView: View {
    private let articleParagraphGroups = [
        [
            "Prototyping is a crucial step in the design process that offers numerous benefits. It allows designers and developers to quickly visualize and test their ideas, gather valuable feedback from users, and iterate on their designs before investing significant time and resources into development.",
            "One of the key advantages of prototyping is that it enables early validation of design concepts. By creating interactive prototypes, designers can simulate the user experience and identify potential usability issues, design flaws, or areas for improvement."
        ],
        [
            "Prototyping also facilitates effective communication and collaboration among team members. It provides a tangible artifact that can be shared, discussed, and iterated upon.",
            "Moreover, prototyping saves time and resources in the long run. By identifying and addressing issues early in the design process, teams can avoid costly mistakes and rework later in the development phase."
        ]
    ]

    private let summaryText = "Prototyping is a crucial step in the design process that offers numerous benefits. It allows designers and developers to quickly visualize and test their ideas, gather valuable feedback from users, and iterate on their designs before investing significant time and resources into development. One of the key advantages of prototyping is that it enables early validation of design concepts. By creating interactive prototypes, designers can simulate the user experience and identify potential usability issues, design flaws, or areas for improvement."
    private let bobCircleDiameter: CGFloat = 20
    private let bobHorizontalInset: CGFloat = 28
    private let bobTopInset: CGFloat = 20
    private let bobBottomInset: CGFloat = 32
    private let menuExpansionDuration: TimeInterval = 0.35
    private let contentFadeDuration: TimeInterval = 0.2
    private let summaryUpperRightDuration: TimeInterval = 2.0
    private let summaryBottomDockDuration: TimeInterval = 1.4
    private let summaryRevealSettleDuration: TimeInterval = 0.1

    @State private var isExpanded = false
    @State private var showContent = false
    @State private var fadeInContent = false
    @State private var fadeInSummary = false
    @State private var position = CGPoint(x: 40, y: 40)
    @State private var viewportMetrics = ViewportMetrics.zero
    @State private var bobBadgeSize = CGSize.zero
    @State private var bobCircleFrame = CGRect.zero
    @State private var overlayAnchorCenter: CGPoint?
    @State private var overlayTransitionWorkItem: DispatchWorkItem?
    @State private var overlayResetWorkItem: DispatchWorkItem?
    @State private var summaryDockWorkItem: DispatchWorkItem?
    @State private var summaryPresentationWorkItem: DispatchWorkItem?
    @State private var showSummary = false

    private var showsArticleText: Bool {
        !showContent && !showSummary
    }

    private var showsBobLabel: Bool {
        overlayAnchorCenter == nil && !showContent && !showSummary
    }

    private var canActivateBob: Bool {
        hasLayoutMeasurements && overlayAnchorCenter == nil && !showContent && !showSummary && !isSummarySequenceInFlight
    }

    private var isSummarySequenceInFlight: Bool {
        summaryDockWorkItem != nil || summaryPresentationWorkItem != nil
    }

    private var hasLayoutMeasurements: Bool {
        viewportMetrics != .zero && bobBadgeSize != .zero && bobCircleFrame != .zero
    }

    private var bobCircleCenter: CGPoint {
        guard bobCircleFrame != .zero else {
            return position
        }

        return CGPoint(x: bobCircleFrame.midX, y: bobCircleFrame.midY)
    }

    private var overlayCircleCenter: CGPoint {
        overlayAnchorCenter ?? bobCircleCenter
    }

    private var expansionDiameter: CGFloat {
        guard viewportMetrics != .zero else {
            return 0
        }

        let center = overlayCircleCenter
        let minX = -viewportMetrics.safeAreaInsets.leading
        let minY = -viewportMetrics.safeAreaInsets.top
        let maxX = viewportMetrics.size.width + viewportMetrics.safeAreaInsets.trailing
        let maxY = viewportMetrics.size.height + viewportMetrics.safeAreaInsets.bottom

        let corners = [
            CGPoint(x: minX, y: minY),
            CGPoint(x: maxX, y: minY),
            CGPoint(x: minX, y: maxY),
            CGPoint(x: maxX, y: maxY)
        ]

        let farthestRadius = corners
            .map { hypot(center.x - $0.x, center.y - $0.y) }
            .max() ?? 0

        return farthestRadius * 2 + bobCircleDiameter
    }

    var body: some View {
        GeometryReader { geometry in
            let currentViewportMetrics = ViewportMetrics(
                size: geometry.size,
                safeAreaInsets: .init(geometry.safeAreaInsets)
            )

            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)

                if showsArticleText {
                    ArticleContentView(paragraphGroups: articleParagraphGroups)
                }

                if let overlayAnchorCenter {
                    FullscreenCircleOverlay(
                        center: overlayAnchorCenter,
                        diameter: expansionDiameter,
                        isExpanded: isExpanded
                    )
                }

                BobBadgeView(
                    showsLabel: showsBobLabel,
                    position: position,
                    onActivate: canActivateBob ? openMenu : nil
                )

                if showContent {
                    ExpandedView(
                        onSummarize: summarizeContent,
                        onClose: closeMenu
                    )
                    .opacity(fadeInContent ? 1 : 0)
                }

                if showSummary {
                    SummaryView(
                        summaryText: summaryText,
                        onClose: beginSummaryDismiss
                    )
                    .opacity(fadeInSummary ? 1 : 0)
                }
            }
            .coordinateSpace(name: BobCoordinateSpace.root)
            .onAppear {
                updateViewportMetrics(currentViewportMetrics)
            }
            .onChange(of: currentViewportMetrics) { _, newMetrics in
                updateViewportMetrics(newMetrics)
            }
            .onPreferenceChange(BobBadgeSizePreferenceKey.self) { newSize in
                updateBobBadgeSize(newSize)
            }
            .onPreferenceChange(BobCircleFramePreferenceKey.self) { newFrame in
                updateBobCircleFrame(newFrame)
            }
        }
        .onDisappear {
            cancelPendingTransitions()
            stopBobMotion()
        }
    }

    private func openMenu() {
        cancelPendingTransitions()
        stopBobMotion()
        captureOverlayAnchor()

        withAnimation(.easeInOut(duration: menuExpansionDuration)) {
            isExpanded = true
        }

        scheduleOverlayTransition(after: menuExpansionDuration) {
            showContent = true
            withAnimation(.easeIn(duration: contentFadeDuration)) {
                fadeInContent = true
            }
        }
    }

    private func closeMenu() {
        dismissExpandedView()
    }

    private func summarizeContent() {
        dismissExpandedView(after: startSummaryFlow)
    }

    private func dismissExpandedView(after completion: @escaping () -> Void = {}) {
        cancelPendingTransitions()

        withAnimation(.easeOut(duration: contentFadeDuration)) {
            fadeInContent = false
        }

        scheduleOverlayTransition(after: contentFadeDuration) {
            showContent = false

            withAnimation(.easeInOut(duration: menuExpansionDuration)) {
                isExpanded = false
            }

            scheduleOverlayAnchorReset(after: menuExpansionDuration, completion: completion)
        }
    }

    private func startSummaryFlow() {
        cancelPendingSummarySequence()
        startSummaryMotion()
    }

    private func startSummaryMotion() {
        stopBobMotion()

        withAnimation(.easeInOut(duration: summaryUpperRightDuration)) {
            position = summaryUpperRightPosition()
        }

        let dockWorkItem = DispatchWorkItem {
            summaryDockWorkItem = nil
            withAnimation(.easeInOut(duration: summaryBottomDockDuration)) {
                position = summaryBottomPosition()
            }
        }
        summaryDockWorkItem = dockWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + summaryUpperRightDuration, execute: dockWorkItem)

        let revealDelay = summaryUpperRightDuration + summaryBottomDockDuration + summaryRevealSettleDuration
        let presentationWorkItem = DispatchWorkItem {
            summaryPresentationWorkItem = nil
            beginSummaryReveal()
        }
        summaryPresentationWorkItem = presentationWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + revealDelay, execute: presentationWorkItem)
    }

    private func beginSummaryReveal() {
        cancelPendingOverlayTransitions()
        captureOverlayAnchor()

        withAnimation(.easeInOut(duration: menuExpansionDuration)) {
            isExpanded = true
        }

        scheduleOverlayTransition(after: menuExpansionDuration) {
            showSummary = true
            withAnimation(.easeIn(duration: contentFadeDuration)) {
                fadeInSummary = true
            }
        }
    }

    private func cancelPendingSummarySequence() {
        summaryDockWorkItem?.cancel()
        summaryDockWorkItem = nil
        summaryPresentationWorkItem?.cancel()
        summaryPresentationWorkItem = nil
    }

    private func stopBobMotion() {
        summaryDockWorkItem?.cancel()
        summaryDockWorkItem = nil
    }

    private func beginSummaryDismiss() {
        cancelPendingTransitions()
        stopBobMotion()

        withAnimation(.easeOut(duration: contentFadeDuration)) {
            fadeInSummary = false
        }

        scheduleOverlayTransition(after: contentFadeDuration) {
            showSummary = false

            withAnimation(.easeInOut(duration: menuExpansionDuration)) {
                isExpanded = false
            }

            scheduleOverlayAnchorReset(after: menuExpansionDuration)
        }
    }

    private func cancelPendingTransitions() {
        cancelPendingSummarySequence()
        cancelPendingOverlayTransitions()
    }

    private func updateViewportMetrics(_ newMetrics: ViewportMetrics) {
        viewportMetrics = newMetrics

        guard hasLayoutMeasurements, showSummary || isSummarySequenceInFlight else {
            return
        }

        position = clampedBobPosition(x: position.x, y: position.y)
    }

    private func updateBobBadgeSize(_ newSize: CGSize) {
        guard newSize != .zero else {
            return
        }

        bobBadgeSize = newSize

        guard showSummary || isSummarySequenceInFlight else {
            return
        }

        position = clampedBobPosition(x: position.x, y: position.y)
    }

    private func updateBobCircleFrame(_ newFrame: CGRect) {
        guard newFrame != .zero else {
            return
        }

        bobCircleFrame = newFrame
    }

    private func scheduleOverlayTransition(after delay: TimeInterval, perform action: @escaping () -> Void) {
        overlayTransitionWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            overlayTransitionWorkItem = nil
            action()
        }

        overlayTransitionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func scheduleOverlayAnchorReset(after delay: TimeInterval, completion: @escaping () -> Void = {}) {
        overlayResetWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            overlayResetWorkItem = nil
            if !isExpanded && !showContent && !showSummary {
                overlayAnchorCenter = nil
            }
            completion()
        }

        overlayResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func cancelPendingOverlayTransitions() {
        overlayTransitionWorkItem?.cancel()
        overlayTransitionWorkItem = nil
        overlayResetWorkItem?.cancel()
        overlayResetWorkItem = nil
    }

    private func captureOverlayAnchor() {
        overlayAnchorCenter = bobCircleCenter
    }

    private func summaryUpperRightPosition() -> CGPoint {
        guard hasLayoutMeasurements else {
            return position
        }

        let x = viewportMetrics.size.width
            - viewportMetrics.safeAreaInsets.trailing
            - bobHorizontalInset
            - bobBadgeSize.width / 2
        let y = viewportMetrics.safeAreaInsets.top
            + bobTopInset
            + bobBadgeSize.height / 2

        return clampedBobPosition(x: x, y: y)
    }

    private func summaryBottomPosition() -> CGPoint {
        guard hasLayoutMeasurements else {
            return position
        }

        let x = viewportMetrics.size.width
            - viewportMetrics.safeAreaInsets.trailing
            - bobHorizontalInset
            - bobBadgeSize.width / 2
        let y = viewportMetrics.size.height
            - viewportMetrics.safeAreaInsets.bottom
            - bobBottomInset
            - bobBadgeSize.height / 2

        return clampedBobPosition(x: x, y: y)
    }

    private func clampedBobPosition(x desiredX: CGFloat, y desiredY: CGFloat) -> CGPoint {
        guard hasLayoutMeasurements else {
            return position
        }

        let minX = viewportMetrics.safeAreaInsets.leading + bobBadgeSize.width / 2
        let maxX = viewportMetrics.size.width - viewportMetrics.safeAreaInsets.trailing - bobBadgeSize.width / 2
        let minY = viewportMetrics.safeAreaInsets.top + bobBadgeSize.height / 2
        let maxY = viewportMetrics.size.height - viewportMetrics.safeAreaInsets.bottom - bobBadgeSize.height / 2

        return CGPoint(
            x: min(max(desiredX, minX), maxX),
            y: min(max(desiredY, minY), maxY)
        )
    }
}

private struct ArticleContentView: View {
    let paragraphGroups: [[String]]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(paragraphGroups.enumerated()), id: \.offset) { index, group in
                Group {
                    ForEach(group, id: \.self) { paragraph in
                        Text(paragraph)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineSpacing(8)
                .padding(.bottom, index == 0 ? 10 : 0)
            }
        }
        .padding()
    }
}

private struct BobBadgeView: View {
    let showsLabel: Bool
    let position: CGPoint
    var onActivate: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: "FCFF7B"))
                .frame(width: 20, height: 20)
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: BobCircleFramePreferenceKey.self,
                            value: geometry.frame(in: .named(BobCoordinateSpace.root))
                        )
                    }
                }
                .onTapGesture {
                    onActivate?()
                }

            Text("Bob")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .opacity(showsLabel ? 1 : 0)
                .onTapGesture {
                    onActivate?()
                }
                .allowsHitTesting(showsLabel && onActivate != nil)
        }
        .background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: BobBadgeSizePreferenceKey.self,
                    value: geometry.size
                )
            }
        }
        .position(position)
        .allowsHitTesting(onActivate != nil)
    }
}

private struct FullscreenCircleOverlay: View {
    let center: CGPoint
    let diameter: CGFloat
    let isExpanded: Bool

    var body: some View {
        Color(hex: "FCFF7B")
            .edgesIgnoringSafeArea(.all)
            .mask {
                Circle()
                    .frame(
                        width: isExpanded ? diameter : 20,
                        height: isExpanded ? diameter : 20
                    )
                    .position(center)
            }
            .compositingGroup()
            .allowsHitTesting(false)
    }
}

private struct ExpandedView: View {
    let onSummarize: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()

            MenuOptionText(title: "Summarize content", action: onSummarize)
            MenuOptionText(title: "Provide related content")
            MenuOptionText(title: "Share content")

            Spacer()

            Image("close component")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .onTapGesture(perform: onClose)
        }
        .padding()
    }
}

private struct MenuOptionText: View {
    let title: String
    var action: (() -> Void)? = nil

    var body: some View {
        Text(title)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .onTapGesture {
                action?()
            }
    }
}

private struct SummaryView: View {
    let summaryText: String
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()

            Text("Summary of Content")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 20)

            Text(summaryText)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 20)
                .lineSpacing(8)

            Spacer()

            HStack {
                Spacer()
                Image("close component")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .onTapGesture(perform: onClose)
                Spacer()
            }
            .padding(.bottom, 20)
        }
        .padding()
    }
}

private struct BobBadgeSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let nextValue = nextValue()
        if nextValue != .zero {
            value = nextValue
        }
    }
}

private struct BobCircleFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let nextValue = nextValue()
        if nextValue != .zero {
            value = nextValue
        }
    }
}

private struct ViewportMetrics: Equatable {
    struct Insets: Equatable {
        let top: CGFloat
        let leading: CGFloat
        let bottom: CGFloat
        let trailing: CGFloat

        init(_ edgeInsets: EdgeInsets = EdgeInsets()) {
            top = edgeInsets.top
            leading = edgeInsets.leading
            bottom = edgeInsets.bottom
            trailing = edgeInsets.trailing
        }

        static let zero = Insets()
    }

    let size: CGSize
    let safeAreaInsets: Insets

    static let zero = ViewportMetrics(size: .zero, safeAreaInsets: .zero)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
