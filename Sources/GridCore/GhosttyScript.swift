/// AppleScript text for driving Ghostty 1.3's scripting dictionary.
public enum GhosttyScript {
    public static let bundleID = "com.mitchellh.ghostty"
    /// Typed into the shell (not run as `command`) so shell aliases and functions work.
    public static let defaultInput = "claude\n"

    /// `nil` → default; `""` → plain shell; otherwise the text with a trailing newline.
    public static func initialInput(cmd: String?) -> String {
        guard let cmd else { return defaultInput }
        if cmd.isEmpty || cmd.hasSuffix("\n") { return cmd }
        return cmd + "\n"
    }

    /// A double-quoted AppleScript string literal for `text`.
    public static func literal(_ text: String) -> String {
        var out = "\""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\\": out += "\\\\"
            case "\"": out += "\\\""
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default: out.unicodeScalars.append(scalar)
            }
        }
        return out + "\""
    }

    public static func newWindow(workingDirectory: String, input: String) -> String {
        var lines = [
            "tell application id \(literal(bundleID))",
            "    set cfg to new surface configuration",
            "    set initial working directory of cfg to \(literal(workingDirectory))",
        ]
        if !input.isEmpty {
            lines.append("    set initial input of cfg to \(literal(input))")
        }
        lines += [
            "    new window with configuration cfg",
            "end tell",
        ]
        return lines.joined(separator: "\n")
    }
}
