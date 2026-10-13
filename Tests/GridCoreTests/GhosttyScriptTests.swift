import Foundation
import Testing
import GridCore

@Suite struct InitialInputTests {
    @Test func defaultsToClaude() { #expect(GhosttyScript.initialInput(cmd: nil) == "claude\n") }
    @Test func emptyMeansPlainShell() { #expect(GhosttyScript.initialInput(cmd: "") == "") }
    @Test func appendsNewline() { #expect(GhosttyScript.initialInput(cmd: "npm test") == "npm test\n") }
    @Test func doesNotDoubleNewline() { #expect(GhosttyScript.initialInput(cmd: "ls\n") == "ls\n") }
    @Test func keepsMultiLineText() { #expect(GhosttyScript.initialInput(cmd: "cd x\nls") == "cd x\nls\n") }
}

@Suite struct LiteralTests {
    @Test func escapesNewline() {
        #expect(GhosttyScript.literal("claude\n") == #""claude\n""#)
    }

    @Test func escapesQuotesAndBackslashes() {
        #expect(GhosttyScript.literal(#"say "hi" \o/"#) == #""say \"hi\" \\o/""#)
    }

    @Test func escapesTabAndReturn() {
        #expect(GhosttyScript.literal("a\tb\rc") == #""a\tb\rc""#)
    }

    @Test func leavesSpacesAndUnicodeAlone() {
        #expect(GhosttyScript.literal("/Users/me/My Project/ünï 🚀") == "\"/Users/me/My Project/ünï 🚀\"")
    }

    /// Runs `return <literal>` through AppleScript (no app involved) and checks the text survives.
    @Test(arguments: [
        "/Users/me/My Project", #"/tmp/"quoted" dir"#, #"/tmp/back\slash"#,
        "/tmp/ünï 🚀", "/tmp/new\nline", "tab\there\r\n", "claude\n", "",
    ])
    @MainActor
    func roundTripsThroughAppleScript(text: String) throws {
        let script = try #require(NSAppleScript(source: "return " + GhosttyScript.literal(text)))
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        #expect(error == nil)
        #expect(result.stringValue == text)
    }
}

@Suite struct NewWindowScriptTests {
    @Test func buildsFullScript() {
        let source = GhosttyScript.newWindow(workingDirectory: "/Users/me/proj", input: "claude\n")
        #expect(source == """
            tell application id "com.mitchellh.ghostty"
                set cfg to new surface configuration
                set initial working directory of cfg to "/Users/me/proj"
                set initial input of cfg to "claude\\n"
                new window with configuration cfg
            end tell
            """)
    }

    @Test func omitsInitialInputWhenEmpty() {
        let source = GhosttyScript.newWindow(workingDirectory: "/tmp", input: "")
        #expect(!source.contains("initial input"))
        #expect(source.contains("new window with configuration cfg"))
    }

    @Test(.enabled(if: FileManager.default.fileExists(atPath: "/Applications/Ghostty.app")))
    func compilesAgainstGhosttyDictionary() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let source = dir.appendingPathComponent("new-window.applescript")
        try GhosttyScript.newWindow(workingDirectory: #"/tmp/a "b" \c"#, input: "claude\n")
            .write(to: source, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osacompile")
        process.arguments = ["-o", dir.appendingPathComponent("new-window.scpt").path, source.path]
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
    }
}
