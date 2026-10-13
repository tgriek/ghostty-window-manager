import GridCore

/// `gwm tile [RxC]`: arrange every tileable Ghostty window in reading order.
struct TileFlow {
    let grid: GridSpec?
    let options: LayoutOptions

    func run() throws {
        try Accessibility.requireTrust()
        guard let ghostty = GhosttyApp.running() else { throw GwmError.noWindows }
        let windows = ghostty.windows().compactMap { window in window.frame.map { (window: window, frame: $0) } }
        guard !windows.isEmpty else { throw GwmError.noWindows }

        let grid = self.grid ?? GridSpec.auto(count: windows.count)
        let target = try Target.resolve(grid: grid, options: options)
        let plan = planTile(windowFrames: windows.map(\.frame), cells: target.cells)

        if options.dryRun {
            target.printSummary(grid: grid)
            print("Windows:")
            for assignment in plan.assignments {
                print("  \(windows[assignment.window].window.title) → \(assignment.frame)")
            }
        } else {
            for assignment in plan.assignments {
                place(windows[assignment.window].window, at: assignment.frame)
            }
        }

        if !plan.leftovers.isEmpty {
            let titles = plan.leftovers.map { "'\(windows[$0].window.title)'" }.joined(separator: ", ")
            warn("\(plan.leftovers.count) window(s) did not fit the \(grid) grid and were left in place: \(titles)")
        }
    }
}
