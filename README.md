# gwm — Ghostty window manager

Open several Ghostty windows running Claude Code (`cds`) and tile them in a grid on the widest screen.

## Install

```bash
make install   # builds release and symlinks ~/.local/bin/gwm
```

First run asks for two macOS permissions for Ghostty (or whichever terminal runs `gwm`):
System Settings → Privacy & Security → **Accessibility** (to move windows) and **Automation** (to open Ghostty windows).

## Use

```bash
gwm 2x3                 # 6 new windows in $PWD, each typing `cds`, tiled 2 rows × 3 columns
gwm 2x2 --cmd "npm test"  # different initial input; --cmd "" for a plain shell
gwm tile                # re-tile every open Ghostty window (grid chosen from the count)
gwm tile 2x4            # re-tile into an explicit grid
```

Options for both: `--gap N` (default 8), `--display ultrawide|main|N` (default: widest screen; N is 1-based), `--stage-strip N` (points kept free for the Stage Manager strip while Stage Manager is on; default 190, 0 = off), `--dry-run` (print frames, change nothing).

Exit codes: 0 ok · 1 runtime failure · 2 missing permission · 64 invalid arguments.
