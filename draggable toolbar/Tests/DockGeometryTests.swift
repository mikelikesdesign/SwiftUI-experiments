import Foundation
import CoreGraphics

// Run from the project directory:
// swiftc 'draggable toolbar/DockGeometry.swift' Tests/DockGeometryTests.swift -o /tmp/dock-tests && /tmp/dock-tests
@main
struct DockGeometryTests {
    static func main() {
        let sizes = [CGSize(width: 393, height: 852), CGSize(width: 852, height: 393),
                     CGSize(width: 320, height: 568), CGSize(width: 1024, height: 1366),
                     CGSize(width: 1366, height: 1024)]
        for size in sizes {
            let layout = DockGeometry(size: size)
            for edge in DockEdge.allCases {
                let target = layout.center(edge)
                precondition(layout.closestEdge(to: target) == edge)
                precondition(layout.releaseEdge(point: target, current: edge,
                                                translation: .zero, prediction: .zero) == edge,
                             "Releasing at a dock must keep the selected edge")

                for previous in DockEdge.allCases where previous != edge {
                    precondition(layout.closestEdge(to: target, retaining: previous) == edge,
                                 "Dragging to another dock must switch the preview edge")
                }

                let dimensions = layout.interpolatedSize(edge: edge, openness: 0)
                for point in [CGPoint(x: -100, y: -100),
                              CGPoint(x: size.width + 100, y: size.height + 100)] {
                    let position = layout.magnetized(point, edge: edge, openness: 0)
                    precondition(position.x >= dimensions.width / 2 + 8)
                    precondition(position.x <= size.width - dimensions.width / 2 - 8)
                    precondition(position.y >= dimensions.height / 2 + 8)
                    precondition(position.y <= size.height - dimensions.height / 2 - 8,
                                 "The dragged toolbar must stay within the canvas")
                }
            }
        }
        print("Manual dock dragging checks passed for phone/tablet and portrait/landscape.")
    }
}
