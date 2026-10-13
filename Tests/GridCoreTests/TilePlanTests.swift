import Testing
import GridCore

private func at(_ x: Double, _ y: Double) -> Rect {
    Rect(x: x, y: y, width: 2000, height: 1300)
}

@Suite struct ReadingOrderTests {
    @Test func jitteredGridReadsTopToBottomLeftToRight() {
        let frames = [
            at(2140, 12),   // row 0, col 1
            at(10, 3),      // row 0, col 0
            at(4270, 18),   // row 0, col 2
            at(4260, 1360), // row 1, col 2
            at(5, 1349),    // row 1, col 0
            at(2130, 1365), // row 1, col 1
        ]
        #expect(readingOrder(frames) == [1, 0, 2, 4, 5, 3])
    }

    @Test func twentyPointsIsSameRowTwentyOneIsNot() {
        #expect(readingOrder([at(500, 0), at(0, 20)]) == [1, 0])
        #expect(readingOrder([at(500, 0), at(0, 21)]) == [0, 1])
    }

    @Test func rowsAnchorOnTopWindowSoTheyDoNotChain() {
        // y = 0, 15, 30: 15 joins the first row, 30 is 30 below the anchor → new row.
        #expect(readingOrder([at(200, 0), at(100, 15), at(0, 30)]) == [1, 0, 2])
    }

    @Test func identicalFramesKeepIndexOrder() {
        #expect(readingOrder([at(0, 0), at(0, 0), at(0, 0)]) == [0, 1, 2])
    }

    @Test func emptyIsEmpty() {
        #expect(readingOrder([]) == [])
    }

    @Test func laidOutGridIsAlreadyInReadingOrder() {
        let cells = layout(GridSpec(rows: 3, cols: 4)!, in: Rect(x: -3200, y: -1350, width: 3200, height: 1325), gap: 8)
        #expect(readingOrder(cells) == Array(0..<12))
    }
}

@Suite struct PlanTileTests {
    private let cells = layout(GridSpec(rows: 2, cols: 4)!, in: Rect(x: 0, y: 0, width: 6400, height: 2700), gap: 8)

    @Test func retilingATiledSetIsIdempotent() {
        let windows = [cells[3], cells[0], cells[6], cells[1], cells[2], cells[5], cells[4]]
        let plan = planTile(windowFrames: windows, cells: cells)
        #expect(plan.assignments.map(\.window) == [1, 3, 4, 0, 6, 5, 2])
        #expect(plan.assignments.allSatisfy { windows[$0.window] == $0.frame })
        #expect(plan.leftovers.isEmpty)
    }

    @Test func fewerWindowsLeaveTrailingCellsEmpty() {
        let windows = [cells[0], cells[1], cells[2]]
        let plan = planTile(windowFrames: windows, cells: cells)
        #expect(plan.assignments.map(\.frame) == Array(cells.prefix(3)))
        #expect(plan.leftovers.isEmpty)
    }

    @Test func extraWindowsAreLastInReadingOrder() {
        let row = [at(400, 0), at(0, 0), at(300, 0), at(100, 0), at(200, 0)]
        let three = Array(cells.prefix(3))
        let plan = planTile(windowFrames: row, cells: three)
        #expect(plan.assignments == [
            Assignment(window: 1, frame: three[0]),
            Assignment(window: 3, frame: three[1]),
            Assignment(window: 4, frame: three[2]),
        ])
        #expect(plan.leftovers == [2, 0])
    }
}
