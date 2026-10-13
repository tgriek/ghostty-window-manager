import Foundation
import GridCore

/// The user's `~/.config/gwm/config` (or `$XDG_CONFIG_HOME/gwm/config`), if present.
struct ConfigFile {
    let path: String
    let exists: Bool
    let config: Config

    static func load() throws -> ConfigFile {
        let path = Config.path(environment: ProcessInfo.processInfo.environment, home: NSHomeDirectory())
        guard FileManager.default.fileExists(atPath: path) else {
            return ConfigFile(path: path, exists: false, config: Config())
        }
        let text: String
        do {
            text = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            throw GwmError.config(path: path, message: error.localizedDescription)
        }
        do {
            return ConfigFile(path: path, exists: true, config: try Config.parse(text))
        } catch let error as ConfigError {
            throw GwmError.config(path: path, message: error.description)
        }
    }

    var summary: String { exists ? "Config: \(path)" : "Config: none (\(path) not found)" }
}
