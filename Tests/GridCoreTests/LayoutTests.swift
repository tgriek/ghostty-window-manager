import Testing
import GridCore

private let ultrawide = Rect(x: 0, y: 0, width: 6400, height: 2700)

private func overlaps(_ a: Rect, _ b: Rect) -> Bool {
    a.x < b.maxX && b.x < a.maxX && a.y < b.maxY && b.y < a.maxY
}

@Suite struct LayoutTests {
    @Test func twoByThreeNoGap() {
        let cells = layout(GridSpec(rows: 2, cols: 3)!, in: ultrawide, gap: 0)
        #expect(cells == [
            Rect(x: 0, y: 0, width: 2133, height: 1350),
            Rect(x: 2133, y: 0, width: 2133, height: 1350),
            Rect(x: 4266, y: 0, width: 2134, height: 1350),
            Rect(x: 0, y: 1350, width: 2133, height: 1350),
            Rect(x: 2133, y: 1350, width: 2133, height: 1350),
            Rect(x: 4266, y: 1350, width: 2134, height: 1350),
        ])
    }

    @Test func twoByThreeGapEight() {
        let cells = layout(GridSpec(rows: 2, cols: 3)!, in: ultrawide, gap: 8)
        #expect(cells == [
            Rect(x: 8, y: 8, width: 2122, height: 1338),
            Rect(x: 2138, y: 8, width: 2122, height: 1338),
            Rect(x: 4268, y: 8, width: 2124, height: 1338),
            Rect(x: 8, y: 1354, width: 2122, height: 1338),
            Rect(x: 2138, y: 1354, width: 2122, height: 1338),
            Rect(x: 4268, y: 1354, width: 2124, height: 1338),
        ])
    }

    @Test(arguments: [0.0, 8.0])
    func outerEdgesFlushAndNoOverlaps(gap: Double) {
        let cells = layout(GridSpec(rows: 3, cols: 4)!, in: ultrawide, gap: gap)
        #expect(cells.count == 12)
        #expect(cells.map(\.x).min() == gap)
        #expect(cells.map(\.y).min() == gap)
        #expect(cells.map(\.maxX).max() == 6400 - gap)
        #expect(cells.map(\.maxY).max() == 2700 - gap)
        for i in cells.indices {
            for j in cells.indices where j > i {
                #expect(!overlaps(cells[i], cells[j]), "cells \(i) and \(j) overlap")
            }
        }
    }

    @Test func lastColumnAbsorbsRemainder() {
        let cells = layout(GridSpec(rows: 1, cols: 7)!, in: Rect(x: 0, y: 0, width: 1000, height: 800), gap: 0)
        #expect(cells.dropLast().allSatisfy { $0.width == 142 })
        #expect(cells.last == Rect(x: 852, y: 0, width: 148, height: 800))
    }

    @Test func fractionalNegativeAreaSnapsToWholePointsInside() {
        // An ultrawide above-left of the primary screen, in AX coordinates, with fractional edges.
        let area = Rect(x: -735.5, y: -1349.6, width: 3200.4, height: 1325.2)
        let cells = layout(GridSpec(rows: 2, cols: 2)!, in: area, gap: 8)
        for cell in cells {
            #expect(cell.x == cell.x.rounded())
            #expect(cell.y == cell.y.rounded())
            #expect(cell.width == cell.width.rounded())
            #expect(cell.height == cell.height.rounded())
        }
        #expect(cells.first?.x == -727)      // ceil(-735.5) + 8
        #expect(cells.first?.y == -1341)     // ceil(-1349.6) + 8
        #expect(cells.last?.maxX == 2456)    // floor(2464.9) - 8
        #expect(cells.last?.maxY == -33)     // floor(-24.4) - 8
    }

    @Test func validateAcceptsReasonableGrid() throws {
        try validateCellSize(GridSpec(rows: 2, cols: 3)!, in: ultrawide, gap: 8)
        try validateCellSize(GridSpec(rows: 10, cols: 1)!, in: ultrawide, gap: 8)
    }

    @Test func validateRejectsNarrowCells() {
        let grid = GridSpec(rows: 1, cols: 30)!
        #expect(throws: GridError.cellsTooSmall(grid: grid, width: 205, height: 2684)) {
            try validateCellSize(grid, in: ultrawide, gap: 8)
        }
    }

    @Test func validateRejectsShortCells() {
        #expect(throws: GridError.self) {
            try validateCellSize(GridSpec(rows: 20, cols: 1)!, in: ultrawide, gap: 8)
        }
    }

    @Test func validateRejectsHugeGapAndMaxGrid() {
        #expect(throws: GridError.self) {
            try validateCellSize(GridSpec(rows: 1, cols: 1)!, in: ultrawide, gap: 4000)
        }
        // Must be refused arithmetically, without building 9801 cells.
        #expect(throws: GridError.self) {
            try validateCellSize(GridSpec(rows: 99, cols: 99)!, in: ultrawide, gap: 8)
        }
    }

    @Test func cellsTooSmallMessageMentionsMinimum() {
        let error = GridError.cellsTooSmall(grid: GridSpec(rows: 1, cols: 30)!, width: 205, height: 2684)
        #expect(error.description.contains("205×2684"))
        #expect(error.description.contains("300×150"))
    }
}
