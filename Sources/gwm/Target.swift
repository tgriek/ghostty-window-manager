import GridCore

/// The chosen screen plus the grid's cell frames on it, all in AX coordinates.
struct Target {
    let screens: [ScreenInfo]
    let screen: ScreenInfo
    let strip: StageStrip?
    let area: Rect
    let cells: [Rect]

    static func resolve(grid: GridSpec, options: LayoutOptions) throws -> Target {
        let screens = Screens.current()
        let choice = try pickScreen(screens, options.display)
        if let notice = choice.notice { note(notice) }
        var area = cocoaToAX(choice.screen.visibleFrame, primaryHeight: primaryHeight(screens))
        let strip = StageManager.strip(width: Double(options.stageStrip))
        if let strip { area = reservingStageStrip(area, strip) }
        let gap = Double(options.gap)
        try validateCellSize(grid, in: area, gap: gap)
        return Target(screens: screens, screen: choice.screen, strip: strip, area: area,
                      cells: layout(grid, in: area, gap: gap))
    }

    func printSummary(grid: GridSpec) {
        print("Displays:")
        for (index, info) in screens.enumerated() {
            var tags: [String] = []
            if info.isMain { tags.append("main") }
            if info.isBuiltin { tags.append("built-in") }
            if info == screen { tags.append("selected") }
            let size = "\(Int(info.frame.width))×\(Int(info.frame.height)) pt"
            print("  \(index + 1): \(info.name) \(size)" + (tags.isEmpty ? "" : " [\(tags.joined(separator: ", "))]"))
        }
        if let strip {
            print("Stage Manager strip: \(Int(strip.width)) pt kept free on the \(strip.side == .left ? "left" : "right")")
        }
        print("Layout area: \(area)")
        print("Grid \(grid):")
        for (index, cell) in cells.enumerated() {
            print("  r\(index / grid.cols + 1)c\(index % grid.cols + 1): \(cell)")
        }
    }
}
