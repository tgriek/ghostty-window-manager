import ArgumentParser
import Foundation
import GridCore

@main
struct Gwm: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gwm",
        abstract: "Open and tile Ghostty windows in a grid.",
        usage: """
            gwm <RxC> [--cmd <text>] [<options>]
            gwm tile [<RxC>] [<options>]
            """,
        subcommands: [Launch.self, Tile.self],
        defaultSubcommand: Launch.self
    )
}

/// Layout flags. Unset flags fall back to the config file, then to built-in defaults.
struct LayoutOptions: ParsableArguments {
    @Option(help: "Gap in points between windows and at the screen edges (default: 8).")
    var gap: Int?

    @Option(help: "Target screen: 'widest', 'main' (menu-bar screen) or a 1-based index (default: widest).",
            transform: parseDisplay)
    var display: DisplayPreference?

    @Option(name: .customLong("stage-strip"),
            help: "Points kept free for the Stage Manager strip while Stage Manager is on; 0 = don't reserve (default: 190).")
    var stageStrip: Int?

    @Flag(help: "Print the chosen screen and cell frames; do not create or move windows.")
    var dryRun = false

    func validate() throws {
        if let gap, !gapRange.contains(gap) {
            throw ValidationError("--gap must be between 0 and \(gapRange.upperBound).")
        }
        if let stageStrip, !stageStripRange.contains(stageStrip) {
            throw ValidationError("--stage-strip must be between 0 and \(stageStripRange.upperBound).")
        }
    }

    func overrides(cmd: String? = nil) -> Config {
        Config(cmd: cmd, gap: gap, display: display, stageStrip: stageStrip)
    }
}

func parseGrid(_ text: String) throws -> GridSpec {
    guard let grid = GridSpec.parse(text) else {
        throw ValidationError("Invalid grid '\(text)'. Use RxC with 1–\(GridSpec.maxDimension) rows and columns, e.g. 2x3.")
    }
    return grid
}

func parseDisplay(_ text: String) throws -> DisplayPreference {
    guard let preference = DisplayPreference.parse(text) else {
        throw ValidationError("Invalid display '\(text)'. Use 'widest', 'main' or a 1-based index.")
    }
    return preference
}

struct Launch: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "launch",
        abstract: "Open RxC new Ghostty windows in the current directory and tile them (default command)."
    )

    @Argument(help: "Grid as RxC, e.g. 2x3.", transform: parseGrid)
    var grid: GridSpec

    @Option(help: "Text typed into each new window (default: claude, or `cmd` in the config file). Use \"\" for a plain shell.")
    var cmd: String?

    @OptionGroup var layout: LayoutOptions

    func run() throws {
        try reportingErrors {
            let file = try ConfigFile.load()
            let settings = layout.overrides(cmd: cmd).merged(over: file.config)
            let target = try Target.resolve(grid: grid, settings: settings)
            let input = GhosttyScript.initialInput(cmd: settings.cmd)
            if layout.dryRun {
                print(file.summary)
                print("Initial input: " + (input.isEmpty ? "(none, plain shell)" : input.trimmingCharacters(in: .newlines)))
                target.printSummary(grid: grid)
                return
            }
            let workingDirectory = ProcessInfo.processInfo.environment["PWD"]
                ?? FileManager.default.currentDirectoryPath
            try LaunchFlow(target: target, input: input, workingDirectory: workingDirectory).run()
        }
    }
}

struct Tile: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Re-tile all open Ghostty windows in on-screen reading order."
    )

    @Argument(help: "Grid as RxC; omit to choose one from the window count.", transform: parseGrid)
    var grid: GridSpec?

    @OptionGroup var layout: LayoutOptions

    func run() throws {
        try reportingErrors { try TileFlow(grid: grid, options: layout).run() }
    }
}
