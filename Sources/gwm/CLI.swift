import ArgumentParser
import Foundation
import GridCore

@main
struct Gwm: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gwm",
        abstract: "Open and tile Ghostty windows in a grid.",
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
        guard gap >= 0 else { throw ValidationError("--gap must be 0 or greater.") }
        guard stageStrip >= 0 else { throw ValidationError("--stage-strip must be 0 or greater.") }
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
            throw ValidationError("Opening windows is not wired up yet; use --dry-run.")
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
