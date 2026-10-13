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

struct LayoutOptions: ParsableArguments {
    @Option(help: "Gap in points between windows and at the screen edges.")
    var gap: Int = 8

    @Option(help: "Target screen: 'ultrawide' (widest), 'main' (menu-bar screen) or a 1-based index.",
            transform: parseDisplay)
    var display: DisplayPreference = .widest

    @Option(name: .customLong("stage-strip"),
            help: "Points kept free for the Stage Manager strip while Stage Manager is on (0 = don't reserve).")
    var stageStrip: Int = 190

    @Flag(help: "Print the chosen screen and cell frames; do not create or move windows.")
    var dryRun = false

    func validate() throws {
        guard (0...1000).contains(gap) else { throw ValidationError("--gap must be between 0 and 1000.") }
        guard (0...2000).contains(stageStrip) else { throw ValidationError("--stage-strip must be between 0 and 2000.") }
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
        throw ValidationError("Invalid display '\(text)'. Use 'ultrawide', 'main' or a 1-based index.")
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

    @Option(help: "Initial input typed into each window (default: cds). Use \"\" for a plain shell.")
    var cmd: String?

    @OptionGroup var layout: LayoutOptions

    func run() throws {
        try reportingErrors {
            let target = try Target.resolve(grid: grid, options: layout)
            if layout.dryRun {
                target.printSummary(grid: grid)
                return
            }
            let workingDirectory = ProcessInfo.processInfo.environment["PWD"]
                ?? FileManager.default.currentDirectoryPath
            try LaunchFlow(target: target, input: GhosttyScript.initialInput(cmd: cmd),
                           workingDirectory: workingDirectory).run()
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
