import Foundation
import CoreGraphics

enum DockEdge: String, CaseIterable { case bottom = "Bottom", leading = "Left", trailing = "Right" }

struct DockGeometry {
    let size: CGSize
    func dockedSize(_ edge: DockEdge) -> CGSize {
        edge == .bottom ? CGSize(width: min(345, max(0, size.width - 16)), height: 82)
            : CGSize(width: 82, height: min(345, max(0, size.height - 32)))
    }
    func center(_ edge: DockEdge) -> CGPoint {
        switch edge {
        case .bottom: return CGPoint(x: size.width / 2, y: size.height - 65)
        case .leading: return CGPoint(x: 49, y: size.height / 2)
        case .trailing: return CGPoint(x: size.width - 49, y: size.height / 2)
        }
    }
    func iconSize(_ edge: DockEdge) -> CGFloat {
        let dimensions = dockedSize(edge)
        let length = edge == .bottom ? dimensions.width : dimensions.height
        return max(0, min(62, (length - 32 - 42) / 4))
    }
    func closestEdge(to point: CGPoint, retaining current: DockEdge? = nil) -> DockEdge {
        let nearest = DockEdge.allCases.min { distance(point, center($0)) < distance(point, center($1)) } ?? .bottom
        if let current, distance(point, center(current)) < distance(point, center(nearest)) + 24 { return current }
        return nearest
    }
    func proximity(_ point: CGPoint, to edge: DockEdge) -> CGFloat {
        let amount: CGFloat = max(0, min(1, 1 - distance(point, center(edge)) / 180))
        return amount * amount * (3 - 2 * amount)
    }
    func interpolatedSize(edge: DockEdge, openness: CGFloat) -> CGSize {
        let dock = dockedSize(edge)
        return CGSize(width: 96 + (dock.width - 96) * openness, height: 96 + (dock.height - 96) * openness)
    }
    func magnetized(_ point: CGPoint, edge: DockEdge, openness: CGFloat) -> CGPoint {
        let target = center(edge)
        let attraction: CGFloat = openness * 0.72
        let dimensions = interpolatedSize(edge: edge, openness: openness)
        let x = point.x + (target.x - point.x) * attraction
        let y = point.y + (target.y - point.y) * attraction
        return CGPoint(x: max(dimensions.width / 2 + 8, min(size.width - dimensions.width / 2 - 8, x)),
                       y: max(dimensions.height / 2 + 8, min(size.height - dimensions.height / 2 - 8, y)))
    }
    func releaseEdge(point: CGPoint, current: DockEdge, translation: CGSize, prediction: CGSize) -> DockEdge {
        if proximity(point, to: current) > 0.6 { return current }
        let dx = prediction.width - translation.width
        let dy = prediction.height - translation.height
        let factor: CGFloat = min(1, 140 / max(hypot(dx, dy), 1))
        return closestEdge(to: CGPoint(x: point.x + dx * factor, y: point.y + dy * factor), retaining: current)
    }
    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
}
