public enum GridError: Error, Equatable, CustomStringConvertible {
    case cellsTooSmall(grid: GridSpec, width: Double, height: Double)
    case noScreens
    case noSuchDisplay(index: Int, available: Int)

    public var description: String {
        switch self {
        case let .cellsTooSmall(grid, width, height):
            return "A \(grid) grid gives \(points(width))×\(points(height)) pt cells; the minimum is "
                + "\(Int(minimumCellWidth))×\(Int(minimumCellHeight)) pt. Use fewer rows/columns or a smaller --gap."
        case .noScreens:
            return "No screens found."
        case let .noSuchDisplay(index, available):
            return "Display \(index) does not exist; \(available) display(s) attached (see --dry-run)."
        }
    }
}

public let minimumCellWidth = 300.0
public let minimumCellHeight = 150.0

/// The area shrunk to whole points (edges rounded inward).
private func snapped(_ area: Rect) -> (left: Double, top: Double, right: Double, bottom: Double) {
    (area.x.rounded(.up), area.y.rounded(.up), area.maxX.rounded(.down), area.maxY.rounded(.down))
}

/// Size of a regular (non-last) cell. May be zero or negative for impossible grids.
public func cellSize(_ grid: GridSpec, in area: Rect, gap: Double) -> (width: Double, height: Double) {
    let bounds = snapped(area)
    let width = ((bounds.right - bounds.left - gap * Double(grid.cols + 1)) / Double(grid.cols)).rounded(.down)
    let height = ((bounds.bottom - bounds.top - gap * Double(grid.rows + 1)) / Double(grid.rows)).rounded(.down)
    return (width, height)
}

public func validateCellSize(_ grid: GridSpec, in area: Rect, gap: Double) throws {
    let size = cellSize(grid, in: area, gap: gap)
    guard size.width >= minimumCellWidth, size.height >= minimumCellHeight else {
        throw GridError.cellsTooSmall(grid: grid, width: size.width, height: size.height)
    }
}

/// Row-major cell frames in the same (top-left origin, y-down) space as `area`.
/// Frames are whole points; the last column and row absorb the rounding remainder
/// so the outer edges sit exactly `gap` from the area's edges.
public func layout(_ grid: GridSpec, in area: Rect, gap: Double) -> [Rect] {
    let bounds = snapped(area)
    let size = cellSize(grid, in: area, gap: gap)
    var cells: [Rect] = []
    cells.reserveCapacity(grid.cellCount)
    for row in 0..<grid.rows {
        for col in 0..<grid.cols {
            let x = bounds.left + gap + Double(col) * (size.width + gap)
            let y = bounds.top + gap + Double(row) * (size.height + gap)
            let width = col == grid.cols - 1 ? bounds.right - gap - x : size.width
            let height = row == grid.rows - 1 ? bounds.bottom - gap - y : size.height
            cells.append(Rect(x: x, y: y, width: width, height: height))
        }
    }
    return cells
}
