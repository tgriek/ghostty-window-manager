/// Indices of `frames` (AX coordinates) sorted top→bottom, then left→right.
/// A window starts a new row when its top edge is more than `rowTolerance`
/// below the top-most window of the current row.
public func readingOrder(_ frames: [Rect], rowTolerance: Double = 20) -> [Int] {
    let byTop = frames.indices.sorted { (frames[$0].y, frames[$0].x, $0) < (frames[$1].y, frames[$1].x, $1) }
    var rows: [[Int]] = []
    var rowTop = 0.0
    for index in byTop {
        if rows.isEmpty || frames[index].y - rowTop > rowTolerance {
            rows.append([index])
            rowTop = frames[index].y
        } else {
            rows[rows.count - 1].append(index)
        }
    }
    return rows.flatMap { row in row.sorted { (frames[$0].x, $0) < (frames[$1].x, $1) } }
}

public struct Assignment: Equatable, Sendable {
    public let window: Int
    public let frame: Rect

    public init(window: Int, frame: Rect) {
        self.window = window
        self.frame = frame
    }
}

public struct TilePlan: Equatable, Sendable {
    /// Windows (by index into the input) paired with their cell, in cell order.
    public let assignments: [Assignment]
    /// Windows that did not fit, in reading order.
    public let leftovers: [Int]
}

public func planTile(windowFrames: [Rect], cells: [Rect]) -> TilePlan {
    let order = readingOrder(windowFrames)
    return TilePlan(
        assignments: zip(order, cells).map { Assignment(window: $0, frame: $1) },
        leftovers: Array(order.dropFirst(cells.count))
    )
}
