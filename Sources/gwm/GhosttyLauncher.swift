import AppKit
import GridCore

/// Calls `probe` every `interval` seconds until it returns a value or `timeout` passes.
func poll<T>(timeout: TimeInterval, interval: TimeInterval = 0.05, _ probe: () -> T?) -> T? {
    let deadline = Date(timeIntervalSinceNow: timeout)
    repeat {
        if let value = probe() { return value }
        Thread.sleep(forTimeInterval: interval)
    } while Date() < deadline
    return probe()
}

enum GhosttyLauncher {
    /// Asks Ghostty for one new window via its AppleScript dictionary.
    static func newWindow(workingDirectory: String, input: String) throws {
        let source = GhosttyScript.newWindow(workingDirectory: workingDirectory, input: input)
        guard let script = NSAppleScript(source: source) else {
            throw GwmError.appleScript("could not create the AppleScript")
        }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        guard let error else { return }
        let number = error[NSAppleScript.errorNumber] as? Int ?? 0
        if number == -1743 { throw GwmError.automationDenied }
        throw GwmError.appleScript(error[NSAppleScript.errorMessage] as? String ?? "error \(number)")
    }

    /// Starts Ghostty and waits (≤ 5 s) for the window(s) it opens on its own.
    static func start() throws -> (app: GhosttyApp, startupWindows: Set<AXWindow>) {
        guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: GhosttyScript.bundleID) != nil else {
            throw GwmError.ghosttyNotFound
        }
        let open = Process()
        open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        open.arguments = ["-b", GhosttyScript.bundleID]
        try open.run()
        open.waitUntilExit()

        guard let app = poll(timeout: 5, { GhosttyApp.running() }) else {
            throw GwmError.appleScript("Ghostty did not start within 5 s")
        }
        _ = poll(timeout: 5) { app.windows().isEmpty ? nil : true }
        Thread.sleep(forTimeInterval: 0.5) // let any restored windows finish appearing
        return (app, Set(app.windows()))
    }
}
