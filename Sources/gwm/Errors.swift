import ArgumentParser
import Foundation
import GridCore

enum GwmError: Error, CustomStringConvertible {
    case accessibilityDenied
    case automationDenied
    case appleScript(String)
    case noWindows
    case windowTimeout(placed: Int, total: Int)
    case ghosttyNotFound
    case grid(GridError)
    case config(path: String, message: String)

    var description: String {
        switch self {
        case .accessibilityDenied:
            return """
                Accessibility permission is required to move windows.
                Grant it in System Settings → Privacy & Security → Accessibility → Ghostty \
                (or whichever terminal runs gwm), then run gwm again.
                """
        case .automationDenied:
            return """
                gwm is not allowed to control Ghostty.
                Allow it in System Settings → Privacy & Security → Automation.
                """
        case let .appleScript(message):
            return "AppleScript error: \(message)"
        case .noWindows:
            return "No Ghostty windows found."
        case let .windowTimeout(placed, total):
            return "A new Ghostty window did not appear within 5 s; stopped after placing \(placed) of \(total) windows."
        case .ghosttyNotFound:
            return "Ghostty (\(GhosttyScript.bundleID)) is not installed."
        case let .grid(error):
            return error.description
        case let .config(path, message):
            return "Invalid config file \(path): \(message)"
        }
    }

    var exitCode: Int32 {
        switch self {
        case .accessibilityDenied, .automationDenied: return 2
        case .grid(.noSuchDisplay): return 64
        case .config: return 78
        default: return 1
        }
    }
}

/// Runs `body`, turning gwm/grid errors into a stderr message and the right exit code.
func reportingErrors(_ body: () throws -> Void) throws {
    do {
        try body()
    } catch let error as GwmError {
        FileHandle.standardError.write(Data("gwm: \(error)\n".utf8))
        throw ExitCode(error.exitCode)
    } catch let error as GridError {
        let wrapped = GwmError.grid(error)
        FileHandle.standardError.write(Data("gwm: \(wrapped)\n".utf8))
        throw ExitCode(wrapped.exitCode)
    }
}

func warn(_ message: String) {
    FileHandle.standardError.write(Data("gwm: warning: \(message)\n".utf8))
}

func note(_ message: String) {
    FileHandle.standardError.write(Data("gwm: \(message)\n".utf8))
}
