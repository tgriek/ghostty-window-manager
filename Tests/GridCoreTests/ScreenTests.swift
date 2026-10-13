import Testing
import GridCore

private let builtin = ScreenInfo(
    name: "Color LCD",
    frame: Rect(x: 0, y: 0, width: 1728, height: 1117),
    visibleFrame: Rect(x: 0, y: 70, width: 1728, height: 1010),
    isMain: true, isBuiltin: true)

private let ultrawideAbove = ScreenInfo(
    name: "DELL U4025QW",
    frame: Rect(x: -736, y: 1117, width: 3200, height: 1350),
    visibleFrame: Rect(x: -736, y: 1117, width: 3200, height: 1325),
    isMain: false, isBuiltin: false)

@Suite struct ScreenSelectionTests {
    @Test func widestIsDefault() throws {
        let choice = try pickScreen([builtin, ultrawideAbove], .widest)
        #expect(choice.screen == ultrawideAbove)
        #expect(choice.notice == nil)
    }

    @Test func mainIsMenuBarScreen() throws {
        #expect(try pickScreen([builtin, ultrawideAbove], .main).screen == builtin)
    }

    @Test func indexIsOneBased() throws {
        #expect(try pickScreen([builtin, ultrawideAbove], .index(1)).screen == builtin)
        #expect(try pickScreen([builtin, ultrawideAbove], .index(2)).screen == ultrawideAbove)
    }

    @Test func indexOutOfRangeThrows() {
        #expect(throws: GridError.noSuchDisplay(index: 3, available: 2)) {
            try pickScreen([builtin, ultrawideAbove], .index(3))
        }
    }

    @Test func onlyBuiltinFallsBackWithNotice() throws {
        let choice = try pickScreen([builtin], .widest)
        #expect(choice.screen == builtin)
        #expect(choice.notice?.contains("built-in") == true)
    }

    @Test func singleExternalHasNoNotice() throws {
        #expect(try pickScreen([ultrawideAbove], .widest).notice == nil)
    }

    @Test func tieGoesToFirstScreen() throws {
        var twin = ultrawideAbove
        twin.name = "Twin"
        #expect(try pickScreen([ultrawideAbove, twin], .widest).screen.name == "DELL U4025QW")
    }

    @Test func noScreensThrows() {
        #expect(throws: GridError.noScreens) { try pickScreen([], .widest) }
    }

    @Test func primaryHeightUsesMainScreen() {
        #expect(primaryHeight([ultrawideAbove, builtin]) == 1117)
    }
}

@Suite struct DisplayPreferenceTests {
    @Test(arguments: [
        ("widest", DisplayPreference.widest), ("WIDEST", .widest), ("main", .main),
        ("1", .index(1)), ("2", .index(2)),
    ])
    func parsesValid(text: String, expected: DisplayPreference) {
        #expect(DisplayPreference.parse(text) == expected)
    }

    @Test(arguments: ["0", "-1", "abc", "", "1.5", " 1", "ultrawide"])
    func rejectsInvalid(text: String) {
        #expect(DisplayPreference.parse(text) == nil)
    }

    @Test func describesForHelpText() {
        #expect(DisplayPreference.widest.description == "widest")
        #expect(DisplayPreference.index(2).description == "2")
    }
}

@Suite struct CocoaToAXTests {
    @Test func primaryScreenMapsToOrigin() {
        #expect(cocoaToAX(builtin.frame, primaryHeight: 1117) == Rect(x: 0, y: 0, width: 1728, height: 1117))
    }

    @Test func visibleFrameExcludesMenuBarAtTop() {
        // Dock 70 pt at the bottom, menu bar 37 pt at the top.
        #expect(cocoaToAX(builtin.visibleFrame, primaryHeight: 1117) == Rect(x: 0, y: 37, width: 1728, height: 1010))
    }

    @Test func ultrawideAboveHasNegativeY() {
        #expect(cocoaToAX(ultrawideAbove.frame, primaryHeight: 1117) == Rect(x: -736, y: -1350, width: 3200, height: 1350))
    }

    @Test func ultrawideLeftHasNegativeXAndShiftedY() {
        let left = Rect(x: -3200, y: -200, width: 3200, height: 1350)
        #expect(cocoaToAX(left, primaryHeight: 1117) == Rect(x: -3200, y: -33, width: 3200, height: 1350))
    }

    @Test func ultrawideRightBottomAligned() {
        let right = Rect(x: 1728, y: 0, width: 3200, height: 1350)
        #expect(cocoaToAX(right, primaryHeight: 1117) == Rect(x: 1728, y: -233, width: 3200, height: 1350))
    }
}

@Suite struct StageStripTests {
    @Test func reservedOnLeftWhenEnabledAndVisible() {
        #expect(stageStrip(enabled: true, autoHide: false, dockOrientation: nil, width: 190)
            == StageStrip(width: 190, side: .left))
        #expect(stageStrip(enabled: true, autoHide: false, dockOrientation: "bottom", width: 190)?.side == .left)
    }

    @Test func movesRightWhenDockIsOnTheLeft() {
        #expect(stageStrip(enabled: true, autoHide: false, dockOrientation: "left", width: 190)?.side == .right)
    }

    @Test func noReservationWhenOffHiddenOrZero() {
        #expect(stageStrip(enabled: false, autoHide: false, dockOrientation: nil, width: 190) == nil)
        #expect(stageStrip(enabled: true, autoHide: true, dockOrientation: nil, width: 190) == nil)
        #expect(stageStrip(enabled: true, autoHide: false, dockOrientation: nil, width: 0) == nil)
    }

    @Test func reservingTrimsTheStripSide() {
        let area = Rect(x: -736, y: -1350, width: 3200, height: 1325)
        #expect(reservingStageStrip(area, StageStrip(width: 190, side: .left))
            == Rect(x: -546, y: -1350, width: 3010, height: 1325))
        #expect(reservingStageStrip(area, StageStrip(width: 190, side: .right))
            == Rect(x: -736, y: -1350, width: 3010, height: 1325))
    }

    @Test func stripWiderThanAreaLeavesNothing() {
        let area = Rect(x: 0, y: 0, width: 100, height: 100)
        #expect(reservingStageStrip(area, StageStrip(width: 500, side: .left)).width == 0)
    }

    @Test func gridNeverCoversTheStrip() {
        let area = reservingStageStrip(Rect(x: 0, y: 37, width: 6400, height: 2600), StageStrip(width: 190, side: .left))
        let cells = layout(GridSpec(rows: 2, cols: 3)!, in: area, gap: 8)
        #expect(cells.map(\.x).min() == 198)
        #expect(cells.map(\.maxX).max() == 6392)
    }
}

@Suite struct LayoutFrameTests {
    private let ultrawideNoMenuBar = ScreenInfo(
        name: "DELL U4025QW",
        frame: Rect(x: 1728, y: -233, width: 3200, height: 1350),
        visibleFrame: Rect(x: 1728, y: -233, width: 3200, height: 1350),
        isMain: false, isBuiltin: false)

    @Test func reservesMenuBarWhenVisibleFrameIncludesIt() {
        // Seen live: the ultrawide's visibleFrame equals its frame, yet macOS keeps
        // windows 22 pt below its top edge.
        #expect(layoutFrame(of: ultrawideNoMenuBar, menuBarHeight: 22)
            == Rect(x: 1728, y: -233, width: 3200, height: 1328))
    }

    @Test func keepsVisibleFrameThatAlreadyExcludesMenuBar() {
        let builtin = ScreenInfo(
            name: "Built-in",
            frame: Rect(x: 0, y: 0, width: 1728, height: 1117),
            visibleFrame: Rect(x: 0, y: 0, width: 1728, height: 1084),
            isMain: true, isBuiltin: true)
        #expect(layoutFrame(of: builtin, menuBarHeight: 22) == builtin.visibleFrame)
    }

    @Test func noReservationWhenMenuBarAutoHides() {
        #expect(layoutFrame(of: ultrawideNoMenuBar, menuBarHeight: 0) == ultrawideNoMenuBar.visibleFrame)
    }

    @Test func topRowStartsBelowMenuBarInAXSpace() {
        let area = cocoaToAX(layoutFrame(of: ultrawideNoMenuBar, menuBarHeight: 22), primaryHeight: 1117)
        let cells = layout(GridSpec(rows: 2, cols: 3)!, in: area, gap: 8)
        #expect(cells.first?.y == 30)          // 0 + 22 menu bar + 8 gap: where macOS clamped the windows
        #expect(cells.last?.maxY == 1342)      // bottom edge unchanged
    }
}
