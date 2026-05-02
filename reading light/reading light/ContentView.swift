//
//  ContentView.swift
//  reading light
//
//  Created by Michael Lee on 4/18/26.
//


import SwiftUI
import UIKit


enum CandlePhase: Equatable {
    case unlit
    case igniting
    case lit
    case snuffing
    case dormant
}


private let candlelitPassage: String = """
SwiftUI is fun to prototype with because the Xcode previews update as soon as you stop typing, making it easy to quickly explore different ideas, layouts, and interactions.

Because views are lightweight structs, iterating is fast. You can duplicate a few lines, tweak some values, and compare different directions without rebuilding large parts of the UI. Simple controls like sliders and toggles also make it easy to test animation timing, spacing, and state changes live.

That speed changes collaboration too. Designers can jump in, adjust details, and help shape the prototype directly. And because SwiftUI prototypes are built with real interface code so it can be utilized for production apps as well.
"""


struct CandlelitReaderView: View {
    @State private var phase: CandlePhase = .lit
    @State private var phaseStart: Date = .now
    @State private var storedFlamePosition: CGPoint? = nil
    @State private var flameScale: CGFloat = 1
    @State private var pinchStartFlameScale: CGFloat = 1
    @State private var flickerSeed: CGFloat = CGFloat.random(in: 0..<1000)
    @State private var snuffPosition: CGPoint = .zero
    @State private var smokeStart: Date? = nil
    @State private var transitionTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                Color.black.ignoresSafeArea()

                ReadingText()
                    .padding(.horizontal, 36)
                    .padding(.top, 96)
                    .padding(.bottom, 48)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .mask(lightMask(canvasSize: size))
                    .allowsHitTesting(false)

                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { ctx in
                    let now = ctx.date
                    flameCanvas(now: now, canvasSize: size)
                }
                .allowsHitTesting(false)

                CandleGestureOverlay(
                    onDragChanged: { p in handleDrag(p, size: size) },
                    onTap: { p in handleTap(p, size: size) },
                    onPinchStarted: { pinchStartFlameScale = flameScale },
                    onPinchChanged: { scale, center in handlePinch(scale: scale, center: center) },
                    onPinchEnded: { pinchStartFlameScale = flameScale }
                )
            }
            .animation(.easeInOut(duration: 0.5), value: phase)
            .sensoryFeedback(.impact(weight: .light), trigger: phase) { _, new in
                new == .igniting
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: phase) { _, new in
                new == .snuffing
            }
            .onDisappear { transitionTask?.cancel() }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }


    @ViewBuilder
    private func lightMask(canvasSize: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { ctx in
            Canvas(rendersAsynchronously: true) { gc, canvas in
                let intensity = flameIntensity(at: ctx.date)
                guard intensity > 0.001 else { return }

                let flame = resolvedFlame(in: canvas)
                let flicker = flickerOffset(at: ctx.date)
                let center = CGPoint(
                    x: flame.x + flicker.x,
                    y: flame.y + flicker.y - (8 * flameScale)
                )
                let radius = 190 * intensity * flameScale

                let stops: [Gradient.Stop] = [
                    .init(color: .white, location: 0.0),
                    .init(color: .white.opacity(0.85), location: 0.28),
                    .init(color: .white.opacity(0.35), location: 0.62),
                    .init(color: .clear, location: 1.0)
                ]
                let shading = GraphicsContext.Shading.radialGradient(
                    Gradient(stops: stops),
                    center: center,
                    startRadius: 0,
                    endRadius: radius
                )
                gc.fill(Path(CGRect(origin: .zero, size: canvas)), with: shading)
            }
        }
    }


    @ViewBuilder
    private func flameCanvas(now: Date, canvasSize: CGSize) -> some View {
        let time = now.timeIntervalSinceReferenceDate
        let intensity = flameIntensity(at: now)
        let flame = resolvedFlame(in: canvasSize)
        Canvas(rendersAsynchronously: true) { gc, _ in
            if phase == .lit || phase == .igniting {
                drawBackGlow(into: gc, center: flame, intensity: intensity, flameScale: flameScale, time: time)
                drawFlameBody(into: gc, center: flame, intensity: intensity, flameScale: flameScale, time: time)
                drawEmbers(into: gc, origin: flame, intensity: intensity, flameScale: flameScale, time: time)
            }

            if phase == .snuffing || phase == .dormant {
                let elapsed = smokeElapsed(at: now)
                drawSmoke(into: gc, origin: snuffPosition, elapsed: elapsed, time: time)
            }
        }
    }

    private func resolvedFlame(in size: CGSize) -> CGPoint {
        storedFlamePosition ?? CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private func screenCenter(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private func smokeElapsed(at date: Date) -> CGFloat {
        CGFloat(date.timeIntervalSince(smokeStart ?? phaseStart))
    }


    private func drawBackGlow(into gc: GraphicsContext, center: CGPoint, intensity: CGFloat, flameScale: CGFloat, time: Double) {
        guard intensity > 0.001 else { return }
        var gc = gc
        gc.blendMode = .plusLighter

        let flicker = flickerOffset(time: time)
        let c = CGPoint(x: center.x + flicker.x, y: center.y + flicker.y - (8 * flameScale))

        let radius = 210 * intensity * flameScale
        let stops: [Gradient.Stop] = [
            .init(color: Color(red: 1.0, green: 0.55, blue: 0.18).opacity(0.48 * Double(intensity)), location: 0),
            .init(color: Color(red: 1.0, green: 0.38, blue: 0.10).opacity(0.22 * Double(intensity)), location: 0.35),
            .init(color: .clear, location: 1.0)
        ]
        let shading = GraphicsContext.Shading.radialGradient(
            Gradient(stops: stops),
            center: c, startRadius: 0, endRadius: radius
        )
        let rect = CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2)
        gc.fill(Path(ellipseIn: rect), with: shading)
    }

    private func drawFlameBody(into gc: GraphicsContext, center: CGPoint, intensity: CGFloat, flameScale: CGFloat, time: Double) {
        guard intensity > 0.001 else { return }
        var base = gc
        base.blendMode = .plusLighter

        let flicker = flickerOffset(time: time)
        let c = CGPoint(x: center.x + flicker.x, y: center.y + flicker.y)
        let scaledIntensity = intensity * flameScale

        drawTeardrop(into: base, at: c,
                     width: 26 * scaledIntensity, height: 62 * scaledIntensity,
                     color: Color(red: 1.0, green: 0.40, blue: 0.12).opacity(0.82 * Double(intensity)),
                     blur: 7)

        drawTeardrop(into: base, at: c,
                     width: 17 * scaledIntensity, height: 46 * scaledIntensity,
                     color: Color(red: 1.0, green: 0.76, blue: 0.34).opacity(0.92 * Double(intensity)),
                     blur: 3)

        drawTeardrop(into: base, at: CGPoint(x: c.x, y: c.y + 4 * scaledIntensity),
                     width: 8 * scaledIntensity, height: 20 * scaledIntensity,
                     color: Color(red: 1.0, green: 0.98, blue: 0.86).opacity(Double(intensity)),
                     blur: 1)
    }

    private func drawTeardrop(into gc: GraphicsContext, at c: CGPoint,
                              width: CGFloat, height: CGFloat,
                              color: Color, blur: CGFloat) {
        var gc = gc
        if blur > 0 { gc.addFilter(.blur(radius: blur)) }
        gc.fill(teardropPath(center: c, width: width, height: height), with: .color(color))
    }

    private func teardropPath(center: CGPoint, width: CGFloat, height: CGFloat) -> Path {
        var p = Path()
        let top = CGPoint(x: center.x, y: center.y - height * 0.55)
        let bottom = CGPoint(x: center.x, y: center.y + height * 0.45)
        p.move(to: top)
        p.addCurve(
            to: bottom,
            control1: CGPoint(x: center.x + width * 0.50, y: center.y - height * 0.15),
            control2: CGPoint(x: center.x + width * 0.55, y: center.y + height * 0.35)
        )
        p.addCurve(
            to: top,
            control1: CGPoint(x: center.x - width * 0.55, y: center.y + height * 0.35),
            control2: CGPoint(x: center.x - width * 0.50, y: center.y - height * 0.15)
        )
        p.closeSubpath()
        return p
    }


    private func drawEmbers(into gc: GraphicsContext, origin: CGPoint, intensity: CGFloat, flameScale: CGFloat, time: Double) {
        guard intensity > 0.08 else { return }
        var base = gc
        base.blendMode = .plusLighter

        let emberScale = max(0.55, flameScale)
        let count = 84
        let period = 2.6
        let driftScale = emberScale
        let riseScale = emberScale
        let particleScale = 0.7 + (emberScale * 0.3)
        let density = min(1.0, max(0.0, (22 * emberScale) / CGFloat(count)))
        let densityFeather: CGFloat = 0.08
        let largeFlameBias = smoothStep(1.0, 2.4, emberScale)

        for i in 0..<count {
            let seed = Double(i) * 97.0 + 13.0
            let spawnOffset = Double(i) / Double(count) * period
            let raw = (time + spawnOffset).truncatingRemainder(dividingBy: period)
            let life = raw / period
            if life <= 0 { continue }

            let threshold = CGFloat(i) / CGFloat(max(count - 1, 1))
            let trailTaper = smoothStep(0.42, 1.0, CGFloat(life))
            let trailDensity = density * (1 - (trailTaper * (0.10 + (0.26 * largeFlameBias))))
            let activation = smoothStep(threshold - densityFeather, threshold + densityFeather, trailDensity)
            guard activation > 0.001 else { continue }

            let driftFreq = 1.4 + sinNoise(seed) * 2.2
            let driftAmp = (9 + sinNoise(seed + 17) * 18) * driftScale
            let horiz = sin(time * driftFreq + seed) * driftAmp

            let rise = CGFloat(life) * ((55 + 95 * CGFloat(sinNoise(seed + 31))) * riseScale)
            let pos = CGPoint(
                x: origin.x + CGFloat(horiz) * CGFloat(life),
                y: origin.y - (16 * emberScale) - rise
            )

            let bell = CGFloat(life * (1 - life) * 4)
            let tailFade = 1 - (trailTaper * (0.08 + (0.16 * largeFlameBias)))
            let alpha = min(1.0, Double(bell * intensity * activation * tailFade))
            let r: CGFloat = (1.8 + CGFloat(1 - life) * 1.6) * particleScale

            let warmth = CGFloat(1 - life * 0.65)
            let color = Color(
                red: 1.0,
                green: Double(0.45 + 0.30 * warmth),
                blue: Double(0.10 * warmth)
            ).opacity(alpha)

            var eCtx = base
            eCtx.addFilter(.blur(radius: 1.2 * particleScale))
            eCtx.fill(
                Path(ellipseIn: CGRect(x: pos.x - r, y: pos.y - r, width: r * 2, height: r * 2)),
                with: .color(color)
            )
        }
    }


    private func drawSmoke(into gc: GraphicsContext, origin: CGPoint, elapsed: CGFloat, time: Double) {
        let window: CGFloat = 5.0
        guard elapsed >= 0, elapsed < window else { return }

        let progress = min(1.0, max(0.0, elapsed / window))
        let fade = smoothStep(0.0, 0.07, progress) * (1.0 - smoothStep(0.76, 1.0, progress))
        guard fade > 0.001 else { return }

        let riseProgress = smoothStep(0.02, 0.86, progress)
        let sharedRise = 18 + riseProgress * 228
        let sharedSway = CGFloat(sin(time * 0.34) * 9.0) * (0.4 + fade * 0.6)
        let driftLean = CGFloat(sin(time * 0.15 + 0.7) * 9.0) * progress
        let basePuff = 1.0 - smoothStep(0.12, 0.42, progress)
        let cohesion = 1.0 - smoothStep(0.62, 1.0, progress)
        let cloudExpand = smoothStep(0.08, 0.68, progress)
        let centroid = CGPoint(
            x: origin.x + sharedSway + driftLean * 0.55,
            y: origin.y - 18 - sharedRise
        )
        var denseBlobs: [SmokeBlob] = []
        var mediumBlobs: [SmokeBlob] = []
        var softBlobs: [SmokeBlob] = []

        func appendSmokeBlob(center: CGPoint, size: CGSize, shade: Double, opacity: Double, bucket: SmokeBlurBucket) {
            guard opacity > 0.001 else { return }
            let blob = SmokeBlob(center: center, size: size, shade: shade, opacity: opacity)
            switch bucket {
            case .dense:
                denseBlobs.append(blob)
            case .medium:
                mediumBlobs.append(blob)
            case .soft:
                softBlobs.append(blob)
            }
        }

        if basePuff > 0.001 {
            for i in 0..<4 {
                let t = CGFloat(i) / 3.0
                let center = CGPoint(
                    x: origin.x + sharedSway * 0.38 + (t - 0.5) * 11 * basePuff,
                    y: origin.y - 12 - riseProgress * 20 - t * 5
                )
                let size = CGSize(
                    width: 38 + t * 20 + cloudExpand * 18,
                    height: 24 + t * 18 + cloudExpand * 14
                )
                let shade = 0.30 + Double(t) * 0.06
                let opacity = (0.23 - Double(t) * 0.05) * Double(basePuff * fade)
                appendSmokeBlob(center: center, size: size, shade: shade, opacity: opacity, bucket: t < 0.5 ? .dense : .medium)
            }
        }

        let trailSegments = 4
        for segment in 0..<trailSegments {
            let t = CGFloat(segment + 1) / CGFloat(trailSegments + 1)
            let bridgeCenter = CGPoint(
                x: origin.x + (centroid.x - origin.x) * (t * 0.82),
                y: origin.y - 14 - sharedRise * (t * 0.72)
            )
            let wobble = CGFloat(sin(time * 0.28 + Double(segment) * 0.9)) * (2.5 + t * 2.5) * cohesion
            let center = CGPoint(x: bridgeCenter.x + wobble, y: bridgeCenter.y)
            let size = CGSize(
                width: 28 + t * 20 + cloudExpand * 12,
                height: 18 + t * 18 + cloudExpand * 8
            )
            let shade = 0.31 + Double(t) * 0.05
            let opacity = (0.16 - Double(t) * 0.03) * Double(fade) * Double(0.65 + cohesion * 0.35)
            let bucket: SmokeBlurBucket = t < 0.45 ? .dense : .medium
            appendSmokeBlob(center: center, size: size, shade: shade, opacity: opacity, bucket: bucket)
        }

        let lobeCount = 6
        for i in 0..<lobeCount {
            let t = CGFloat(i) / CGFloat(lobeCount - 1)
            let angle = (-0.9 + t * 1.8) + CGFloat(sinNoise(Double(i) * 19.0 + 4.0)) * 0.08
            let radialX = (18 + t * 20 + cloudExpand * 24) * (0.30 + cohesion * 0.70)
            let radialY = (10 + t * 11 + cloudExpand * 14) * (0.42 + cohesion * 0.58)
            let wobble = CGFloat(sin(time * (0.24 + Double(i) * 0.03) + Double(i) * 0.8)) * (2.0 + t * 2.5) * (0.5 + cohesion * 0.5)
            let center = CGPoint(
                x: centroid.x + cos(angle) * radialX + wobble,
                y: centroid.y + sin(angle) * radialY + t * 10 - cloudExpand * 8
            )
            let size = CGSize(
                width: 48 + t * 18 + cloudExpand * 22,
                height: 30 + t * 18 + cloudExpand * 20
            )
            let shade = 0.29 + Double(t) * 0.07
            let opacity = (0.19 - Double(t) * 0.045) * Double(fade)
            let bucket: SmokeBlurBucket
            if t < 0.25 {
                bucket = .dense
            } else if t < 0.75 {
                bucket = .medium
            } else {
                bucket = .soft
            }
            appendSmokeBlob(center: center, size: size, shade: shade, opacity: opacity, bucket: bucket)
        }

        let capOffset = (10 + cloudExpand * 12) * (0.35 + cohesion * 0.65)
        let capOpacity = 0.10 * Double(fade) * Double(0.55 + cohesion * 0.45)
        appendSmokeBlob(
            center: CGPoint(x: centroid.x - capOffset * 0.55, y: centroid.y - 12),
            size: CGSize(width: 54 + cloudExpand * 18, height: 34 + cloudExpand * 16),
            shade: 0.38,
            opacity: capOpacity,
            bucket: .soft
        )
        appendSmokeBlob(
            center: CGPoint(x: centroid.x + capOffset * 0.55, y: centroid.y - 10),
            size: CGSize(width: 52 + cloudExpand * 16, height: 32 + cloudExpand * 14),
            shade: 0.40,
            opacity: capOpacity * 0.92,
            bucket: .soft
        )

        let coreOpacity = 0.13 * Double(fade) * Double(0.72 + cohesion * 0.28)
        appendSmokeBlob(
            center: CGPoint(x: centroid.x, y: centroid.y + 2),
            size: CGSize(width: 60 + cloudExpand * 20, height: 38 + cloudExpand * 18),
            shade: 0.33,
            opacity: coreOpacity,
            bucket: .medium
        )

        renderSmokeLayer(into: gc, blobs: denseBlobs, blur: 12)
        renderSmokeLayer(into: gc, blobs: mediumBlobs, blur: 20)
        renderSmokeLayer(into: gc, blobs: softBlobs, blur: 30)
    }

    private func renderSmokeLayer(into gc: GraphicsContext, blobs: [SmokeBlob], blur: Double) {
        guard !blobs.isEmpty else { return }
        var layer = gc
        layer.addFilter(.blur(radius: blur))
        for blob in blobs {
            let rect = CGRect(
                x: blob.center.x - blob.size.width / 2,
                y: blob.center.y - blob.size.height / 2,
                width: blob.size.width,
                height: blob.size.height
            )
            layer.fill(
                Path(ellipseIn: rect),
                with: .color(Color(white: blob.shade).opacity(blob.opacity))
            )
        }
    }

    private struct SmokeBlob {
        let center: CGPoint
        let size: CGSize
        let shade: Double
        let opacity: Double
    }

    private enum SmokeBlurBucket {
        case dense
        case medium
        case soft
    }


    @ViewBuilder
    private func sparkInvitation(now: Date, canvasSize: CGSize) -> some View {
        let time = now.timeIntervalSinceReferenceDate
        let pulse = (sin(time * 1.6) * 0.5 + 0.5)
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height * 0.5)

        Canvas { gc, _ in
            var gc = gc
            gc.blendMode = .plusLighter

            let glowR: CGFloat = 48 + CGFloat(pulse) * 22
            let glowStops: [Gradient.Stop] = [
                .init(color: Color(red: 1.0, green: 0.72, blue: 0.30).opacity(0.35 + 0.25 * pulse), location: 0),
                .init(color: .clear, location: 1)
            ]
            gc.fill(
                Path(ellipseIn: CGRect(x: center.x - glowR, y: center.y - glowR, width: glowR * 2, height: glowR * 2)),
                with: .radialGradient(Gradient(stops: glowStops), center: center, startRadius: 0, endRadius: glowR)
            )

            let r: CGFloat = 3.0 + CGFloat(pulse) * 2.5
            gc.fill(
                Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                with: .color(Color(red: 1.0, green: 0.88, blue: 0.60).opacity(0.6 + 0.4 * pulse))
            )
        }
    }


    private func flameIntensity(at date: Date) -> CGFloat {
        let elapsed = CGFloat(date.timeIntervalSince(phaseStart))
        let time = date.timeIntervalSinceReferenceDate

        switch phase {
        case .unlit, .dormant, .snuffing:
            return 0
        case .igniting:
            let t = min(1, elapsed / 0.55)
            return smoothStep(0, 1, t)
        case .lit:
            let flick = CGFloat(sin(time * 8.3 + Double(flickerSeed)) * 0.07
                                + sin(time * 13.7 + 1.3) * 0.04)
            return max(0.7, 1.0 + flick)
        }
    }

    private func flickerOffset(at date: Date) -> CGPoint {
        flickerOffset(time: date.timeIntervalSinceReferenceDate)
    }

    private func flickerOffset(time: Double) -> CGPoint {
        guard phase == .lit || phase == .igniting else { return .zero }
        let x = sin(time * 6.1 + Double(flickerSeed)) * 1.6 + sin(time * 11.2) * 0.7
        let y = sin(time * 7.8 + Double(flickerSeed) * 0.3) * 0.9
        return CGPoint(x: x, y: y)
    }


    private func handleDrag(_ point: CGPoint, size: CGSize) {
        switch phase {
        case .igniting, .lit:
            storedFlamePosition = point
        case .unlit, .snuffing, .dormant:
            break
        }
    }

    private func handleTap(_ point: CGPoint, size: CGSize) {
        let center = screenCenter(in: size)
        switch phase {
        case .unlit, .dormant:
            ignite(at: center)
        case .igniting, .lit, .snuffing:
            break
        }
    }

    private func handlePinch(scale: CGFloat, center: CGPoint) {
        guard phase == .lit || phase == .igniting else { return }
        let flameOrigin = storedFlamePosition ?? center
        let nextScale = clampedFlameScale(pinchStartFlameScale * scale)
        flameScale = nextScale

        if nextScale <= 0.14 {
            snuff(at: flameOrigin)
        }
    }


    private func ignite(at point: CGPoint) {
        transitionTask?.cancel()
        storedFlamePosition = point
        flameScale = 1
        pinchStartFlameScale = flameScale
        smokeStart = nil
        transition(to: .igniting)
        transitionTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(560))
            guard !Task.isCancelled, phase == .igniting else { return }
            transition(to: .lit)
        }
    }

    private func snuff(at point: CGPoint) {
        transitionTask?.cancel()
        snuffPosition = point
        pinchStartFlameScale = flameScale
        smokeStart = .now
        transition(to: .snuffing)
        transitionTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(340))
            guard !Task.isCancelled, phase == .snuffing else { return }
            transition(to: .dormant)
            try? await Task.sleep(for: .milliseconds(4660))
            guard !Task.isCancelled, phase == .dormant else { return }
            transition(to: .unlit)
        }
    }

    private func transition(to new: CandlePhase) {
        phase = new
        phaseStart = .now
        if new != .snuffing && new != .dormant {
            smokeStart = nil
        }
    }

    private func clampedFlameScale(_ scale: CGFloat) -> CGFloat {
        min(2.4, max(0.08, scale))
    }
}


private struct ReadingText: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("On SwiftUI")
                .font(.system(size: 30, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(Color(red: 0.98, green: 0.91, blue: 0.74))

            Text(candlelitPassage)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .lineSpacing(7)
                .foregroundStyle(Color(red: 0.96, green: 0.86, blue: 0.60))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}


struct CandleGestureOverlay: UIViewRepresentable {
    let onDragChanged: (CGPoint) -> Void
    let onTap: (CGPoint) -> Void
    let onPinchStarted: () -> Void
    let onPinchChanged: (CGFloat, CGPoint) -> Void
    let onPinchEnded: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = .clear

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        pan.delegate = context.coordinator
        v.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinch.delegate = context.coordinator
        v.addGestureRecognizer(pinch)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.delegate = context.coordinator
        v.addGestureRecognizer(tap)

        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: CandleGestureOverlay

        init(_ parent: CandleGestureOverlay) { self.parent = parent }

        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            guard let view = g.view else { return }
            switch g.state {
            case .began, .changed:
                parent.onDragChanged(g.location(in: view))
            default: break
            }
        }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let view = g.view else { return }
            parent.onTap(g.location(in: view))
        }

        @objc func handlePinch(_ g: UIPinchGestureRecognizer) {
            guard let view = g.view else { return }
            if g.numberOfTouches >= 2 {
                let a = g.location(ofTouch: 0, in: view)
                let b = g.location(ofTouch: 1, in: view)
                let center = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
                switch g.state {
                case .began:
                    parent.onPinchStarted()
                    parent.onPinchChanged(g.scale, center)
                case .changed:
                    parent.onPinchChanged(g.scale, center)
                case .ended, .cancelled, .failed:
                    parent.onPinchEnded()
                default: break
                }
            } else if g.state == .ended || g.state == .cancelled || g.state == .failed {
                parent.onPinchEnded()
            }
        }

        func gestureRecognizer(_ g: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }
}


private func smoothStep(_ edge0: CGFloat, _ edge1: CGFloat, _ value: CGFloat) -> CGFloat {
    guard edge0 != edge1 else { return value >= edge1 ? 1 : 0 }
    let t = min(1, max(0, (value - edge0) / (edge1 - edge0)))
    return t * t * (3 - 2 * t)
}

private func sinNoise(_ v: Double) -> Double {
    let s = sin(v * 12.9898 + 78.233) * 43758.5453
    return s - floor(s)
}


#if DEBUG
struct CandlelitReaderView_Previews: PreviewProvider {
    static var previews: some View {
        CandlelitReaderView()
    }
}
#endif
