import SwiftUI
import PencilKit
import Combine

enum DrawingInstrument: String, CaseIterable {
    case pencil = "Pencil", marker = "Marker", eraser = "Eraser"
}

final class DrawingStudio: ObservableObject {
    let canvas = PKCanvasView()
    @Published var instrument: DrawingInstrument = .pencil
    @Published var color = Color(.sRGB, red: 0, green: 89.0 / 255.0, blue: 1, opacity: 1)
    @Published var canUndo = false
    @Published var canRedo = false
    @Published var hasDrawing = false

    init() {
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.isScrollEnabled = false
        canvas.accessibilityLabel = "Drawing canvas"
        canvas.accessibilityIdentifier = "drawingCanvas"
        applyTool()
    }

    func select(_ instrument: DrawingInstrument) {
        self.instrument = instrument
        applyTool()
        UISelectionFeedbackGenerator().selectionChanged()
    }

    func applyTool() {
        switch instrument {
        case .pencil: canvas.tool = PKInkingTool(.pencil, color: UIColor(color), width: 3)
        case .marker: canvas.tool = PKInkingTool(.marker, color: UIColor(color).withAlphaComponent(0.5), width: 20)
        case .eraser: canvas.tool = PKEraserTool(.bitmap, width: 24)
        }
    }

    func refreshHistory() {
        canUndo = canvas.undoManager?.canUndo ?? false
        canRedo = canvas.undoManager?.canRedo ?? false
        hasDrawing = !canvas.drawing.strokes.isEmpty
    }

    func undo() { canvas.undoManager?.undo(); refreshHistory() }
    func redo() { canvas.undoManager?.redo(); refreshHistory() }

    func clearDrawing() {
        guard !canvas.drawing.strokes.isEmpty else { return }
        replaceDrawing(with: PKDrawing())
    }

    private func replaceDrawing(with drawing: PKDrawing) {
        let previous = canvas.drawing
        canvas.drawing = drawing
        canvas.undoManager?.registerUndo(withTarget: self) { studio in
            studio.replaceDrawing(with: previous)
        }
        canvas.undoManager?.setActionName("Clear Drawing")
        refreshHistory()
    }
}

struct DrawingCanvas: UIViewControllerRepresentable {
    let studio: DrawingStudio

    func makeUIViewController(context: Context) -> DrawingCanvasController {
        DrawingCanvasController(studio: studio)
    }

    func updateUIViewController(_ controller: DrawingCanvasController, context: Context) {
        // Tool changes are applied by DrawingStudio, independently of view updates.
    }
}

final class DrawingCanvasController: UIViewController, PKCanvasViewDelegate {
    private let studio: DrawingStudio

    init(studio: DrawingStudio) {
        self.studio = studio
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use init(studio:)") }

    override func loadView() {
        view = studio.canvas
        studio.canvas.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        studio.canvas.becomeFirstResponder()
    }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        // PencilKit finishes registering undo after its drawing callback.
        DispatchQueue.main.async { [weak self] in self?.studio.refreshHistory() }
    }
}

struct GraphPaper: View {
    var body: some View {
        Color.white.overlay {
            Canvas { context, size in
                let spacing: CGFloat = 24
                let opacity: Double = 0.045
                for column in 0...Int(size.width / spacing) {
                    let x: CGFloat = CGFloat(column) * spacing
                    var line = Path()
                    line.move(to: CGPoint(x: x, y: 0))
                    line.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(line, with: .color(.black.opacity(opacity)), lineWidth: 0.6)
                }
                for row in 0...Int(size.height / spacing) {
                    let y: CGFloat = CGFloat(row) * spacing
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y))
                    line.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(line, with: .color(.black.opacity(opacity)), lineWidth: 0.6)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct StudioHeader: View {
    @ObservedObject var studio: DrawingStudio

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            HStack(spacing: 0) {
                historyButton("Undo", symbol: "arrow.uturn.backward", enabled: studio.canUndo, action: studio.undo)
                Rectangle().fill(Color.black.opacity(0.07)).frame(width: 1, height: 15)
                historyButton("Redo", symbol: "arrow.uturn.forward", enabled: studio.canRedo, action: studio.redo)
                Rectangle().fill(Color.black.opacity(0.07)).frame(width: 1, height: 15)
                historyButton("Clear drawing", symbol: "trash", enabled: studio.hasDrawing, action: studio.clearDrawing)
            }
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.9), lineWidth: 1))
        }
        .padding(.horizontal, 27)
    }

    private func historyButton(_ title: String, symbol: String, enabled: Bool,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.black.opacity(enabled ? 0.64 : 0.18))
                .frame(width: 44, height: 44)
        }
        .disabled(!enabled)
        .accessibilityLabel(title)
        .accessibilityIdentifier(title.lowercased())
    }
}

struct NativeColorWell: UIViewRepresentable {
    @Binding var color: Color

    func makeUIView(context: Context) -> UIColorWell {
        let well = UIColorWell()
        well.supportsAlpha = false
        well.selectedColor = UIColor(color)
        well.title = "Colors"
        well.accessibilityLabel = "Color picker"
        well.accessibilityIdentifier = "colorPicker"
        well.addTarget(context.coordinator, action: #selector(Coordinator.colorChanged(_:)), for: .valueChanged)
        return well
    }

    func updateUIView(_ well: UIColorWell, context: Context) {
        context.coordinator.parent = self
        let selected = UIColor(color)
        if well.selectedColor != selected { well.selectedColor = selected }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject {
        var parent: NativeColorWell
        init(parent: NativeColorWell) { self.parent = parent }
        @objc func colorChanged(_ well: UIColorWell) {
            guard let selected = well.selectedColor else { return }
            parent.color = Color(uiColor: selected)
        }
    }
}

struct InstrumentArtwork: View {
    let instrument: DrawingInstrument
    let color: Color
    var barrelExtension: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 44, y: size.height / (80 + barrelExtension))
            switch instrument {
            case .pencil: pencil(in: context)
            case .marker: marker(in: context)
            case .eraser: eraser(in: context)
            }
        }
        .accessibilityHidden(true)
    }

    // Custom vectors styled after the iOS Markup tools; the dock owns their movement.
    private func casing(_ path: Path, left: CGFloat, right: CGFloat, in context: GraphicsContext) {
        let stops: [Gradient.Stop] = [
            .init(color: Color(white: 0.79), location: 0),
            .init(color: Color(white: 0.91), location: 0.14),
            .init(color: Color(white: 0.985), location: 0.37),
            .init(color: Color(white: 0.96), location: 0.61),
            .init(color: Color(white: 0.89), location: 0.85),
            .init(color: Color(white: 0.78), location: 1)
        ]
        context.fill(path, with: .linearGradient(Gradient(stops: stops),
                     startPoint: CGPoint(x: left, y: 0), endPoint: CGPoint(x: right, y: 0)))
        context.stroke(path, with: .color(.black.opacity(0.035)), lineWidth: 0.35)
    }

    private func inkFinish(_ path: Path, left: CGFloat, right: CGFloat, in context: GraphicsContext) {
        context.fill(path, with: .color(color))
        let stops: [Gradient.Stop] = [
            .init(color: .black.opacity(0.16), location: 0),
            .init(color: .white.opacity(0.20), location: 0.28),
            .init(color: .clear, location: 0.6),
            .init(color: .black.opacity(0.10), location: 1)
        ]
        context.fill(path, with: .linearGradient(Gradient(stops: stops),
                     startPoint: CGPoint(x: left, y: 0), endPoint: CGPoint(x: right, y: 0)))
    }

    private func pencil(in context: GraphicsContext) {
        let body = Path { path in
            path.move(to: CGPoint(x: 12, y: 34))
            path.addLine(to: CGPoint(x: 32, y: 34))
            path.addLine(to: CGPoint(x: 32, y: 78 + barrelExtension))
            path.addQuadCurve(to: CGPoint(x: 30, y: 80 + barrelExtension), control: CGPoint(x: 32, y: 80 + barrelExtension))
            path.addLine(to: CGPoint(x: 14, y: 80 + barrelExtension))
            path.addQuadCurve(to: CGPoint(x: 12, y: 78 + barrelExtension), control: CGPoint(x: 12, y: 80 + barrelExtension))
            path.closeSubpath()
        }
        casing(body, left: 12, right: 32, in: context)
        // A long graphite point, pale sharpened wood, and a faceted lacquer edge.
        let wood = polygon([(22, 4), (32, 35), (27, 32), (22, 36), (17, 32), (12, 35)])
        finish(wood, colors: [Color(red: 0.78, green: 0.70, blue: 0.57),
                             Color(red: 0.94, green: 0.89, blue: 0.78),
                             Color(red: 0.84, green: 0.76, blue: 0.62)],
               from: CGPoint(x: 12, y: 0), to: CGPoint(x: 32, y: 0), in: context)
        let graphite = Path { path in
            path.move(to: CGPoint(x: 22, y: 3))
            path.addQuadCurve(to: CGPoint(x: 23.2, y: 6), control: CGPoint(x: 22.7, y: 3.5))
            path.addLine(to: CGPoint(x: 25.8, y: 16))
            path.addQuadCurve(to: CGPoint(x: 18.2, y: 16), control: CGPoint(x: 22, y: 17))
            path.addLine(to: CGPoint(x: 20.8, y: 6))
            path.addQuadCurve(to: CGPoint(x: 22, y: 3), control: CGPoint(x: 21.3, y: 3.5))
        }
        inkFinish(graphite, left: 18, right: 26, in: context)
        context.fill(Path(CGRect(x: 17, y: 37, width: 0.6, height: 42 + barrelExtension)), with: .color(.white.opacity(0.6)))
        context.fill(Path(CGRect(x: 27, y: 37, width: 0.5, height: 42 + barrelExtension)), with: .color(.black.opacity(0.045)))
        inkFinish(Path(CGRect(x: 12, y: 48, width: 20, height: 3.5)), left: 12, right: 32, in: context)
    }

    private func marker(in context: GraphicsContext) {
        // iOS uses a continuous molded shoulder, with the color band on the barrel.
        let body = Path { path in
            path.move(to: CGPoint(x: 14, y: 24))
            path.addQuadCurve(to: CGPoint(x: 30, y: 24), control: CGPoint(x: 22, y: 23.3))
            path.addLine(to: CGPoint(x: 30, y: 35))
            path.addCurve(to: CGPoint(x: 35, y: 51), control1: CGPoint(x: 30, y: 42), control2: CGPoint(x: 35, y: 44))
            path.addLine(to: CGPoint(x: 35, y: 78 + barrelExtension))
            path.addQuadCurve(to: CGPoint(x: 33, y: 80 + barrelExtension), control: CGPoint(x: 35, y: 80 + barrelExtension))
            path.addLine(to: CGPoint(x: 11, y: 80 + barrelExtension))
            path.addQuadCurve(to: CGPoint(x: 9, y: 78 + barrelExtension), control: CGPoint(x: 9, y: 80 + barrelExtension))
            path.addLine(to: CGPoint(x: 9, y: 51))
            path.addCurve(to: CGPoint(x: 14, y: 35), control1: CGPoint(x: 9, y: 44), control2: CGPoint(x: 14, y: 42))
            path.closeSubpath()
        }
        casing(body, left: 9, right: 35, in: context)
        let nib = Path { path in
            path.move(to: CGPoint(x: 15, y: 24))
            path.addLine(to: CGPoint(x: 15, y: 16))
            path.addQuadCurve(to: CGPoint(x: 16.5, y: 13.5), control: CGPoint(x: 15, y: 14.5))
            path.addLine(to: CGPoint(x: 28, y: 8.5))
            path.addQuadCurve(to: CGPoint(x: 29.5, y: 10), control: CGPoint(x: 29.5, y: 7.8))
            path.addLine(to: CGPoint(x: 29.5, y: 24))
            path.closeSubpath()
        }
        inkFinish(nib, left: 15, right: 30, in: context)
        inkFinish(Path(CGRect(x: 9, y: 54, width: 26, height: 7)), left: 9, right: 35, in: context)
        context.fill(Path(CGRect(x: 15, y: 26, width: 1, height: 10)), with: .color(.white.opacity(0.45)))
    }

    private func eraser(in context: GraphicsContext) {
        let body = Path(roundedRect: CGRect(x: 10, y: 34, width: 24, height: 46 + barrelExtension), cornerRadius: 2)
        casing(body, left: 10, right: 34, in: context)
        let rubber = Path { path in
            path.move(to: CGPoint(x: 10, y: 35))
            path.addLine(to: CGPoint(x: 10, y: 20))
            path.addCurve(to: CGPoint(x: 15, y: 15), control1: CGPoint(x: 10, y: 16), control2: CGPoint(x: 11.5, y: 15))
            path.addQuadCurve(to: CGPoint(x: 29, y: 15), control: CGPoint(x: 22, y: 14.3))
            path.addCurve(to: CGPoint(x: 34, y: 20), control1: CGPoint(x: 32.5, y: 15), control2: CGPoint(x: 34, y: 16))
            path.addLine(to: CGPoint(x: 34, y: 35))
            path.closeSubpath()
        }
        finish(rubber, colors: [Color(red: 0.83, green: 0.38, blue: 0.42),
                               Color(red: 0.97, green: 0.58, blue: 0.60),
                               Color(red: 0.93, green: 0.48, blue: 0.51),
                               Color(red: 0.79, green: 0.35, blue: 0.40)],
               from: CGPoint(x: 10, y: 0), to: CGPoint(x: 34, y: 0), in: context)
        context.fill(Path(CGRect(x: 10, y: 35, width: 24, height: 0.5)), with: .color(.black.opacity(0.055)))
        context.fill(Path(CGRect(x: 10, y: 56, width: 24, height: 0.5)), with: .color(.black.opacity(0.07)))
        context.fill(Path(CGRect(x: 10, y: 56.5, width: 24, height: 0.5)), with: .color(.white.opacity(0.7)))
    }

    private func polygon(_ points: [(CGFloat, CGFloat)]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: CGPoint(x: first.0, y: first.1))
            for point in points.dropFirst() { path.addLine(to: CGPoint(x: point.0, y: point.1)) }
            path.closeSubpath()
        }
    }

    private func finish(_ path: Path, colors: [Color], from start: CGPoint, to end: CGPoint, in context: GraphicsContext) {
        context.fill(path, with: .linearGradient(Gradient(colors: colors), startPoint: start, endPoint: end))
        context.stroke(path, with: .color(.white.opacity(0.18)), lineWidth: 0.5)
    }
}
