import Testing
import GridCore

@Suite struct ConfigParseTests {
    @Test func parsesEveryKeyWithCommentsBlankLinesAndQuotes() throws {
        let config = try Config.parse("""
            # my gwm settings

            cmd = "claude --dangerously-skip-permissions"
              gap=12
            display = main
            stage-strip = 220
            """)
        #expect(config == Config(cmd: "claude --dangerously-skip-permissions", gap: 12, display: .main, stageStrip: 220))
    }

    @Test func emptyFileIsEmptyConfig() throws {
        #expect(try Config.parse("") == Config())
    }

    @Test func emptyQuotedCmdMeansPlainShell() throws {
        #expect(try Config.parse(#"cmd = """#).cmd == "")
    }

    @Test func unquotedCmdKeepsSpacesAndEqualsSigns() throws {
        #expect(try Config.parse("cmd = FOO=1 claude --model opus").cmd == "FOO=1 claude --model opus")
    }

    @Test func handlesCRLFAndLastValueWins() throws {
        #expect(try Config.parse("gap = 4\r\ngap = 6\r\n") == Config(gap: 6))
    }

    @Test(arguments: [
        ("colour = red", 1, "unknown key 'colour'"),
        ("gap = 8\njust text", 2, "expected 'key = value'"),
        ("gap = abc", 1, "gap must be a whole number from 0 to 1000"),
        ("gap = 1001", 1, "gap must be a whole number from 0 to 1000"),
        ("gap = -1", 1, "gap must be a whole number from 0 to 1000"),
        ("stage-strip = 2001", 1, "stage-strip must be a whole number from 0 to 2000"),
        ("display = ultrawide", 1, "display must be 'widest', 'main' or a 1-based index"),
    ])
    func rejectsBadLines(text: String, line: Int, message: String) {
        #expect(throws: ConfigError(line: line, message: message)) { try Config.parse(text) }
    }

    @Test func errorDescriptionNamesTheLine() {
        #expect(ConfigError(line: 3, message: "unknown key 'x'").description == "line 3: unknown key 'x'")
    }
}

@Suite struct ConfigResolutionTests {
    @Test func commandLineWinsOverFile() {
        let file = Config(cmd: "claude --dangerously-skip-permissions", gap: 12, display: .main, stageStrip: 220)
        let cli = Config(cmd: "", gap: 4)
        #expect(cli.merged(over: file) == Config(cmd: "", gap: 4, display: .main, stageStrip: 220))
    }

    @Test func defaultsApplyWhenNothingIsSet() {
        let settings = Config()
        #expect(settings.resolvedGap == 8)
        #expect(settings.resolvedDisplay == .widest)
        #expect(settings.resolvedStageStrip == 190)
    }

    @Test func pathPrefersAbsoluteXDGConfigHome() {
        #expect(Config.path(environment: ["XDG_CONFIG_HOME": "/cfg"], home: "/Users/me") == "/cfg/gwm/config")
        #expect(Config.path(environment: ["XDG_CONFIG_HOME": "relative"], home: "/Users/me") == "/Users/me/.config/gwm/config")
        #expect(Config.path(environment: [:], home: "/Users/me") == "/Users/me/.config/gwm/config")
    }
}
