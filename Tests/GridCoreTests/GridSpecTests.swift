import Testing
import GridCore

@Suite struct GridSpecTests {
    @Test(arguments: [("2x3", 2, 3), ("1x1", 1, 1), ("3X4", 3, 4), ("12x2", 12, 2), ("99x99", 99, 99)])
    func parsesValid(text: String, rows: Int, cols: Int) {
        let spec = GridSpec.parse(text)
        #expect(spec?.rows == rows)
        #expect(spec?.cols == cols)
    }

    @Test(arguments: [
        "0x3", "3x0", "3", "abc", "-1x3", "2x-3", "2x", "x3", "2x3x4",
        " 2x3", "2x3 ", "", "２x3", "+2x3", "100x1", "1x100", "99999999999999999999x2",
    ])
    func rejectsInvalid(text: String) {
        #expect(GridSpec.parse(text) == nil)
    }

    @Test func describesAsRxC() {
        #expect(GridSpec(rows: 2, cols: 3)?.description == "2x3")
        #expect(GridSpec(rows: 2, cols: 3)?.cellCount == 6)
    }

    @Test(arguments: [
        (1, 1, 1), (2, 1, 2), (3, 1, 3), (4, 2, 2), (5, 2, 3), (6, 2, 3),
        (7, 2, 4), (8, 2, 4), (9, 3, 3), (10, 3, 4), (11, 3, 4), (12, 3, 4),
    ])
    func autoGridFollowsRowRule(count: Int, rows: Int, cols: Int) {
        let grid = GridSpec.auto(count: count)
        #expect(grid.rows == rows)
        #expect(grid.cols == cols)
    }
}
