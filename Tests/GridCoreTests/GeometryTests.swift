import Testing
import GridCore

@Suite struct GeometryTests {
    @Test func describesWholePoints() {
        #expect(Rect(x: 8, y: -1350, width: 2122, height: 1338).description == "x=8 y=-1350 w=2122 h=1338")
    }

    @Test func isCloseWithinTolerance() {
        let target = Rect(x: 0, y: 0, width: 100, height: 100)
        #expect(target.isClose(to: Rect(x: 1, y: -2, width: 101, height: 100)))
        #expect(!target.isClose(to: Rect(x: 0, y: 0, width: 90, height: 100)))
        #expect(!target.isClose(to: Rect(x: 3, y: 0, width: 100, height: 100)))
    }
}

@Suite struct HugeValueTests {
    @Test func rectDescriptionSurvivesHugeValues() {
        #expect(Rect(x: 9.3e18, y: -1e20, width: 0, height: 0).description == "x=9300000000000000000 y=-100000000000000000000 w=0 h=0")
    }

    @Test func cellsTooSmallMessageSurvivesHugeGap() {
        let grid = GridSpec(rows: 1, cols: 1)!
        let area = Rect(x: 0, y: 0, width: 6400, height: 2700)
        let size = cellSize(grid, in: area, gap: 9223372036854775807)
        let error = GridError.cellsTooSmall(grid: grid, width: size.width, height: size.height)
        #expect(error.description.hasPrefix("A 1x1 grid gives -"))
    }
}
