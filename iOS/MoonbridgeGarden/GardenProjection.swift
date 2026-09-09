import Foundation

/// The simulation stays in cell units; only the presentation has perspective.
struct GardenProjection {
    let size: CGSize
    static let rows = 5
    static let columns = 9

    private var top: CGFloat { size.height * 0.20 }
    private var depth: CGFloat { size.height * 0.69 }

    func depthScale(_ row: CGFloat) -> CGFloat {
        0.72 + 0.28 * row / CGFloat(Self.rows)
    }

    func point(column: CGFloat, row: CGFloat) -> CGPoint {
        let scale = depthScale(row)
        let width = size.width * 0.78 * scale
        // Integrated depth scale makes distant lanes shallower as well as narrower.
        let t = row / CGFloat(Self.rows)
        return CGPoint(x: size.width * 0.47 + (column / CGFloat(Self.columns) - 0.5) * width,
                       y: top + depth * (0.72 * t + 0.14 * t * t) / 0.86)
    }

    func cell(at point: CGPoint) -> GridCell? {
        guard size.width > 0, size.height > 0, point.x.isFinite, point.y.isFinite else { return nil }
        let rawDepth = (point.y - top) / depth * 0.86
        // Round-off at shared edges must not send a click to the previous cell.
        let epsilon: CGFloat = 1e-10
        guard rawDepth >= -epsilon, rawDepth < 0.86 - epsilon else { return nil }
        let v = max(0, rawDepth)
        let t = (2 * v) / (0.72 + sqrt(0.72 * 0.72 + 0.56 * v))
        let row = t * CGFloat(Self.rows)
        let width = size.width * 0.78 * depthScale(row)
        let column = ((point.x - size.width * 0.47) / width + 0.5) * CGFloat(Self.columns)
        guard column >= -epsilon, column < CGFloat(Self.columns) - epsilon else { return nil }
        return GridCell(row: Int(row + epsilon), column: Int(max(0, column) + epsilon))
    }

    func spriteScale(row: Int) -> CGFloat {
        min(size.width * 0.78 / 9, size.height * 0.69 / 5) / 82
            * depthScale(CGFloat(row) + 0.5)
    }

    /// An upright local coordinate frame: no sprite shear or vertical flattening.
    func laneOrigin(row: Int, logicalSize: CGSize) -> CGPoint {
        let s = depthScale(CGFloat(row) + 0.5)
        let center = point(column: 4.5, row: CGFloat(row) + 0.5)
        return CGPoint(x: center.x - logicalSize.width * s / 2,
                       y: center.y - (CGFloat(row) + 0.5) * logicalSize.height / 5 * s)
    }
}
