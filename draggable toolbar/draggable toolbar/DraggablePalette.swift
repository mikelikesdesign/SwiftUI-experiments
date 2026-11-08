import SwiftUI

struct DraggablePalette: View {
    @ObservedObject var studio: DrawingStudio
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var gestureActive = false
    @State private var dockedEdge: DockEdge = .bottom
    @State private var previewEdge: DockEdge = .bottom
    @State private var isDragging = false
    @State private var translation = CGSize.zero
    @State private var latchedEdge: DockEdge?
    @State private var feedback = UISelectionFeedbackGenerator()

    private var settle: Animation {
        reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.44, dampingFraction: 0.74)
    }

    var body: some View {
        GeometryReader { geometry in
            let layout = DockGeometry(size: geometry.size)
            let point = dragPoint(in: layout)
            let edge = isDragging ? previewEdge : dockedEdge
            let openness: CGFloat = isDragging ? layout.proximity(point, to: edge) : 1.0
            let dimensions = layout.interpolatedSize(edge: edge, openness: openness)
            let cornerRadius: CGFloat = 32.0 + 9.0 * openness
            ZStack {
                if isDragging {
                    ForEach(DockEdge.allCases, id: \.self) { target in
                        dropIndicator(edge: target, layout: layout, point: point)
                    }
                }
                ZStack {
                    surface(cornerRadius: cornerRadius)
                    ZStack {
                        ForEach(0..<4, id: \.self) { index in
                            paletteItem(at: index, edge: edge, openness: openness, layout: layout)
                        }
                    }
                    .frame(width: dimensions.width, height: dimensions.height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
                .frame(width: dimensions.width, height: dimensions.height)
                .rotationEffect(dockRotation(openness: openness))
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
                .position(isDragging ? layout.magnetized(point, edge: edge, openness: openness) : layout.center(dockedEdge))
                .highPriorityGesture(dragGesture(layout: layout))
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Drawing palette")
                .accessibilityValue(dockedEdge.rawValue)
                .accessibilityIdentifier("appDock")
                .accessibilityHint("Drag to the left, right, or bottom edge.")
                .accessibilityAction(named: "Dock on left") { dock(to: .leading) }
                .accessibilityAction(named: "Dock on right") { dock(to: .trailing) }
                .accessibilityAction(named: "Dock at bottom") { dock(to: .bottom) }
            }
            .coordinateSpace(name: "dockCanvas")
            .onChange(of: geometry.size) { _, _ in cancelDrag() }
        }
        .onChange(of: gestureActive) { _, active in
            if !active && isDragging { cancelDrag() }
        }
    }

    private func surface(cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        let borderColor: Color = .white.opacity(0.95)
        let borderWidth: CGFloat = 1
        let shadowOpacity: Double = isDragging ? 0.16 : 0.11
        let finish = LinearGradient(colors: [Color(white: 0.995), Color(white: 0.965)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing)
        return shape.fill(finish)
            .overlay(shape.stroke(borderColor, lineWidth: borderWidth))
            .shadow(color: .black.opacity(shadowOpacity), radius: 12, y: 8)
    }

    private func dockRotation(openness: CGFloat) -> Angle {
        let tilt: Double = Double(max(-10, min(10, translation.width * 0.05)))
        let degrees: Double = reduceMotion ? 0.0 : tilt * Double(1.0 - openness)
        return .degrees(degrees)
    }

    private func paletteItem(at index: Int, edge: DockEdge, openness: CGFloat, layout: DockGeometry) -> some View {
        let depth: CGFloat = CGFloat(index) * (1.0 - openness)
        let itemSize: CGFloat = 60.0 + (layout.iconSize(edge) - 60.0) * openness
        let scale: CGFloat = 1.0 - depth * 0.05
        let edgeDegrees: Double = edge == .bottom ? 0.0 : (edge == .leading ? 90.0 : -90.0)
        let toolDegrees: Double = index < 3 ? edgeDegrees * Double(openness) : 0.0
        let fanDegrees: Double = reduceMotion ? 0.0 : Double(depth) * -3.0
        let degrees: Double = toolDegrees + fanDegrees
        let opacity: Double = 1.0 - Double(depth) * 0.1
        let offset = iconOffset(index, edge: edge, openness: openness, layout: layout)
        let zOrder: Double = Double(4 - index)
        return paletteButton(index, openness: openness)
            .frame(width: itemSize, height: itemSize)
            .scaleEffect(scale)
            .rotationEffect(.degrees(degrees))
            .opacity(opacity)
            .offset(offset)
            .zIndex(zOrder)
    }

    @ViewBuilder
    private func paletteButton(_ index: Int, openness: CGFloat) -> some View {
        if index < 3 {
            let instrument = DrawingInstrument.allCases[index]
            let selected = studio.instrument == instrument
            let extensionLength: CGFloat = 24 * openness
            Button {
                withAnimation(settle) { studio.select(instrument) }
            } label: {
                // Seat the tools deeper in the dock while keeping a subtle selection lift.
                InstrumentArtwork(instrument: instrument, color: studio.color,
                                  barrelExtension: extensionLength * 80 / 67)
                    .frame(width: 37, height: 67 + extensionLength)
                    .shadow(color: .black.opacity(0.12), radius: 1.5, x: 0.5, y: 1)
                    .offset(y: extensionLength / 2 + (selected ? -1 : 6) * openness)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(instrument.rawValue)
            .accessibilityValue(selected ? "Selected" : "")
            .accessibilityIdentifier("tool-\(instrument.rawValue)")
        } else {
            NativeColorWell(color: $studio.color)
                .frame(width: 44, height: 44)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func dragPoint(in layout: DockGeometry) -> CGPoint {
        let origin = layout.center(dockedEdge)
        return CGPoint(x: origin.x + translation.width, y: origin.y + translation.height)
    }

    private func iconOffset(_ index: Int, edge: DockEdge, openness: CGFloat, layout: DockGeometry) -> CGSize {
        let stack = CGSize(width: CGFloat(index) * 4 - 6, height: CGFloat(index) * -6)
        let axis: CGFloat = (CGFloat(index) - 1.5) * (layout.iconSize(edge) + 14)
        let dock = edge == .bottom ? CGSize(width: axis, height: 0) : CGSize(width: 0, height: axis)
        return CGSize(width: stack.width + (dock.width - stack.width) * openness,
                      height: stack.height + (dock.height - stack.height) * openness)
    }

    private func dragGesture(layout: DockGeometry) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .named("dockCanvas"))
            .updating($gestureActive) { _, active, _ in active = true }
            .onChanged { value in
                if !isDragging {
                    previewEdge = dockedEdge
                    latchedEdge = dockedEdge
                    feedback.prepare()
                    withAnimation(.easeOut(duration: 0.16)) { isDragging = true }
                }
                translation = value.translation
                let point = dragPoint(in: layout)
                withAnimation(settle) {
                    previewEdge = layout.closestEdge(to: point, retaining: previewEdge)
                }
                let proximity = layout.proximity(point, to: previewEdge)
                if proximity > 0.6 && latchedEdge != previewEdge {
                    latchedEdge = previewEdge
                    feedback.selectionChanged()
                    feedback.prepare()
                } else if proximity < 0.35 {
                    latchedEdge = nil
                }
            }
            .onEnded { value in
                let target = layout.releaseEdge(point: dragPoint(in: layout), current: previewEdge,
                                               translation: value.translation, prediction: value.predictedEndTranslation)
                dock(to: target)
            }
    }

    private func dock(to edge: DockEdge) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.65)
        withAnimation(settle) {
            dockedEdge = edge
            previewEdge = edge
            isDragging = false
            translation = .zero
            latchedEdge = nil
        }
    }

    private func cancelDrag() {
        withAnimation(settle) {
            isDragging = false
            translation = .zero
            previewEdge = dockedEdge
            latchedEdge = nil
        }
    }

    private func dropIndicator(edge: DockEdge, layout: DockGeometry, point: CGPoint) -> some View {
        let proximity: CGFloat = layout.proximity(point, to: edge)
        let scale: CGFloat = 0.55 + 0.35 * proximity
        let dimensions = layout.dockedSize(edge)
        let radius: CGFloat = 32.0 + 9.0 * proximity
        let fillOpacity: Double = (0.06 + 0.10 * Double(proximity)) * 0.3
        let strokeOpacity: Double = 0.025 + 0.035 * Double(proximity)
        let width: CGFloat = 1
        let shape = RoundedRectangle(cornerRadius: radius)
        return shape.fill(Color.black.opacity(fillOpacity))
            .overlay(shape.stroke(Color.black.opacity(strokeOpacity), lineWidth: width))
            .frame(width: dimensions.width * scale, height: dimensions.height * scale)
            .position(layout.center(edge))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
