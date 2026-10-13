# gwm — Ghostty window manager

Open a grid of [Ghostty](https://ghostty.org) windows with one command, or snap the ones you already have back into a grid. Built for running several Claude Code sessions side by side, but any command works.

```bash
gwm 2x3        # 6 new Ghostty windows in the current directory, each running `claude`, tiled 2 rows × 3 columns
gwm tile       # re-tile every open Ghostty window (grid picked from the window count)
```

## Requirements

- macOS 14 or later
- Ghostty 1.3 or later (needs its AppleScript support, on by default)
- To build: Xcode 16 / Swift 6 toolchain

## Install

With Homebrew:

```bash
brew install tgriek/tap/gwm
```

From source:

```bash
git clone https://github.com/tgriek/ghostty-window-manager
cd ghostty-window-manager
make install          # builds a release binary and symlinks it to ~/.local/bin/gwm
```

### Permissions (once)

`gwm` drives Ghostty through two macOS permissions, granted to the app you run `gwm` from (normally Ghostty itself):

- **Accessibility** — to move and resize windows. System Settings → Privacy & Security → Accessibility.
- **Automation** — to open new Ghostty windows. macOS asks the first time; it is listed under Privacy & Security → Automation.

## Usage

```bash
gwm <RxC> [--cmd <text>] [options]     # open R×C new windows and tile them
gwm tile [<RxC>] [options]             # re-tile all open Ghostty windows
```

- `gwm 2x3` opens 6 new windows in `$PWD` and types the configured command (default `claude`) into each. Existing windows are left alone.
- `--cmd "npm run dev"` types something else; `--cmd ""` gives a plain shell.
- `gwm tile` arranges all standard Ghostty windows (not minimized or full screen) in reading order: top to bottom, then left to right, so running it twice changes nothing. Without a grid it picks one from the window count: 1–3 windows → 1 row, 4–8 → 2 rows, 9+ → 3 rows. Windows that don't fit an explicit grid stay where they are.

Options for both commands:

| Option | Default | Meaning |
|---|---|---|
| `--gap N` | `8` | Points between windows and at the screen edges (0–1000) |
| `--display widest\|main\|N` | `widest` | Target screen: the widest one, the menu-bar screen, or a 1-based index |
| `--stage-strip N` | `190` | Points kept free for the Stage Manager strip while Stage Manager is on (0 = don't reserve) |
| `--dry-run` | | Print the displays, config and cell frames; open or move nothing |

`gwm` lays out inside the screen's usable area: below the menu bar, above the Dock, and clear of the Stage Manager strip (on the left, or the right when the Dock is on the left). Grids whose cells would be smaller than 300×150 pt are refused.

## Configuration

Put your own defaults in `~/.config/gwm/config` (or `$XDG_CONFIG_HOME/gwm/config`). Command-line flags override it.

```ini
# One `key = value` per line; lines starting with # are ignored.
cmd = claude --dangerously-skip-permissions
gap = 12
display = widest
stage-strip = 190
```

`cmd` is typed into an interactive shell, so shell aliases and functions work too. `gwm 2x3 --dry-run` shows which config file was loaded and what will be typed.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Runtime failure: cells too small, no Ghostty windows, a new window didn't appear within 5 s |
| 2 | Missing Accessibility or Automation permission |
| 64 | Invalid arguments |
| 78 | Invalid config file |

## Development

```bash
swift test      # unit tests for the layout logic (GridCore)
swift build     # debug build at .build/debug/gwm
```

`GridCore` holds all the pure logic: grid parsing, layout, screen selection, reading order, config and AppleScript generation. The `gwm` target is a thin macOS layer on top: NSScreen, the Accessibility API and NSAppleScript.

## License

MIT
