import GridCore

/// `gwm RxC`: open one new Ghostty window per cell and place each as soon as it appears.
struct LaunchFlow {
    let target: Target
    let input: String
    let workingDirectory: String

    func run() throws {
        try Accessibility.requireTrust()

        let ghostty: GhosttyApp
        var startupWindows: Set<AXWindow> = []
        if let running = GhosttyApp.running() {
            ghostty = running
        } else {
            let started = try GhosttyLauncher.start()
            ghostty = started.app
            startupWindows = started.startupWindows
        }
        defer { closeStartupWindows(startupWindows) }

        for (index, cell) in target.cells.enumerated() {
            let before = Set(ghostty.windows())
            try GhosttyLauncher.newWindow(workingDirectory: workingDirectory, input: input)
            guard let window = poll(timeout: 5, { ghostty.windows().first { !before.contains($0) } }) else {
                throw GwmError.windowTimeout(placed: index, total: target.cells.count)
            }
            place(window, at: cell)
        }
    }

    /// Closes the single default window Ghostty opened when gwm started it, so exactly
    /// R×C windows remain. Several startup windows means restored state: leave them.
    private func closeStartupWindows(_ windows: Set<AXWindow>) {
        guard !windows.isEmpty else { return }
        guard windows.count == 1, let window = windows.first else {
            note("Ghostty opened \(windows.count) windows at startup (restored state); leaving them open.")
            return
        }
        window.close()
    }
}
