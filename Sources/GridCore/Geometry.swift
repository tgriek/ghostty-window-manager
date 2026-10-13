import Foundation

/// A rectangle in points. Which coordinate space it lives in (Cocoa or AX)
/// is stated by whoever produces it.
public struct Rect: Equatable, Sendable, CustomStringConvertible {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var maxX: Double { x + width }
    public var maxY: Double { y + height }

    public var description: String {
        "x=\(points(x)) y=\(points(y)) w=\(points(width)) h=\(points(height))"
    }

    /// True when every edge is within `tolerance` points of `other`'s.
    public func isClose(to other: Rect, tolerance: Double = 2) -> Bool {
        abs(x - other.x) <= tolerance
            && abs(y - other.y) <= tolerance
            && abs(maxX - other.maxX) <= tolerance
            && abs(maxY - other.maxY) <= tolerance
    }
}

/// A point value as a whole number, without trapping on values outside `Int`'s range.
func points(_ value: Double) -> String {
    let rounded = value.rounded()
    return abs(rounded) < 1e15 ? String(Int(rounded)) : String(format: "%.0f", rounded)
}
