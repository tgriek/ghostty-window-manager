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
