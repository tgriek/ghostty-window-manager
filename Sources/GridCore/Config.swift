import Foundation

public let gapRange = 0...1000
public let stageStripRange = 0...2000

/// Settings from `~/.config/gwm/config` or the command line. `nil` means "not set here".
public struct Config: Equatable, Sendable {
    public static let defaultGap = 8
    public static let defaultStageStrip = 190

    public var cmd: String?
    public var gap: Int?
    public var display: DisplayPreference?
    public var stageStrip: Int?

    public init(cmd: String? = nil, gap: Int? = nil, display: DisplayPreference? = nil, stageStrip: Int? = nil) {
        self.cmd = cmd
        self.gap = gap
        self.display = display
        self.stageStrip = stageStrip
    }

    public var resolvedGap: Int { gap ?? Self.defaultGap }
    public var resolvedDisplay: DisplayPreference { display ?? .widest }
    public var resolvedStageStrip: Int { stageStrip ?? Self.defaultStageStrip }

    /// Values set in `self` win; unset ones fall back to `base`.
    public func merged(over base: Config) -> Config {
        Config(cmd: cmd ?? base.cmd, gap: gap ?? base.gap,
               display: display ?? base.display, stageStrip: stageStrip ?? base.stageStrip)
    }

    /// `$XDG_CONFIG_HOME/gwm/config` when that is an absolute path, else `~/.config/gwm/config`.
    public static func path(environment: [String: String], home: String) -> String {
        if let xdg = environment["XDG_CONFIG_HOME"], xdg.hasPrefix("/") {
            return xdg + "/gwm/config"
        }
        return home + "/.config/gwm/config"
    }

    /// Parses `key = value` lines. Blank lines and lines starting with `#` are ignored;
    /// a value may be wrapped in double quotes; a repeated key keeps its last value.
    public static func parse(_ text: String) throws -> Config {
        var config = Config()
        // "\r\n" is a single Character in Swift, so normalise it before splitting.
        let lines = text.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n", omittingEmptySubsequences: false)
        for (index, rawLine) in lines.enumerated() {
            let lineNumber = index + 1
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("#") { continue }
            guard let equals = line.firstIndex(of: "=") else {
                throw ConfigError(line: lineNumber, message: "expected 'key = value'")
            }
            let key = line[..<equals].trimmingCharacters(in: .whitespaces).lowercased()
            let value = unquoted(line[line.index(after: equals)...].trimmingCharacters(in: .whitespaces))
            switch key {
            case "cmd":
                config.cmd = value
            case "gap":
                guard let gap = Int(value), gapRange.contains(gap) else {
                    throw ConfigError(line: lineNumber, message: "gap must be a whole number from 0 to \(gapRange.upperBound)")
                }
                config.gap = gap
            case "display":
                guard let display = DisplayPreference.parse(value) else {
                    throw ConfigError(line: lineNumber, message: "display must be 'widest', 'main' or a 1-based index")
                }
                config.display = display
            case "stage-strip":
                guard let strip = Int(value), stageStripRange.contains(strip) else {
                    throw ConfigError(line: lineNumber,
                                      message: "stage-strip must be a whole number from 0 to \(stageStripRange.upperBound)")
                }
                config.stageStrip = strip
            default:
                throw ConfigError(line: lineNumber, message: "unknown key '\(key)'")
            }
        }
        return config
    }

    private static func unquoted(_ value: String) -> String {
        guard value.count >= 2, value.hasPrefix("\""), value.hasSuffix("\"") else { return value }
        return String(value.dropFirst().dropLast())
    }
}

public struct ConfigError: Error, Equatable, CustomStringConvertible {
    public let line: Int
    public let message: String

    public init(line: Int, message: String) {
        self.line = line
        self.message = message
    }

    public var description: String { "line \(line): \(message)" }
}
