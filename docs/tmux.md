# tmux

Config: `~/.config/tmux/tmux.conf`. The prefix is **`` ` ``** (backtick); press it twice
to type a literal backtick. The status bar sits at the top with the session on the left
(`*` while the prefix is active), windows in the centre and the host on the right. It uses
the terminal's ANSI colours, so it follows the central theme.

Plugins are pinned in `packages/plugins.txt` and installed by `setup.sh` into
`~/.config/tmux/plugins` (no tpm): tmux-resurrect, tmux-continuum, vim-tmux-navigator,
tmux-sessionx and tmux-floax.

## Keys (after the prefix)

| Key | Action |
| --- | --- |
| `w` / `s` | Split side by side / stacked, in the current directory |
| `h` `j` `k` `l` | Move to the pane left / down / up / right |
| `Ctrl+h/j/k/l` | Resize the pane (repeatable) |
| `m` | Zoom the pane |
| `Ctrl+←` / `Ctrl+→` | Move the window left / right |
| `Space` | Session picker with previews (sessionx) |
| `t` | Floating scratch terminal (floax) |
| `y` | Toggle typing into all panes at once |
| `v` | Save the session now (resurrect) |
| `r` | Reload the config |
| `[` | Copy mode: `v` starts a selection, `y` copies |

## Without the prefix

| Key | Action |
| --- | --- |
| `Ctrl+h/j/k/l` | Move between tmux panes and nvim splits alike (vim-tmux-navigator) |

## Sessions

Sessions are saved every 15 minutes and restored when tmux starts (continuum +
resurrect, including pane contents and nvim sessions). Auto-save only runs when this is
the only tmux server, so separate environments don't overwrite each other's saves.
