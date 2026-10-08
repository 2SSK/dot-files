# tmux

Config: `~/.config/tmux/tmux.conf`. The prefix is **`` ` ``** (backtick); press it twice
to type a literal backtick.

The status bar sits at the top, with no plugin: the session name on the left (`●` while the
prefix is held), the windows centred (the current one bold in the theme's primary colour, the
rest muted) and the host name on the right. Colours come from the desktop theme
(`~/.local/state/desktop/theme/tmux.conf`), so `theme` recolours a running tmux too.

Plugins are pinned in `packages/plugins.txt` and installed by `setup.sh` into
`~/.config/tmux/plugins` (no tpm): tmux-resurrect, tmux-continuum, vim-tmux-navigator
and tmux-sessionx.

## Keys (after the prefix)

| Key | Action |
| --- | --- |
| `w` / `s` | Split side by side / stacked, in the current directory |
| `h` `j` `k` `l` | Move to the pane left / down / up / right |
| `Ctrl+h/j/k/l` | Resize the pane (repeatable) |
| `m` | Zoom the pane |
| `Ctrl+←` / `Ctrl+→` | Move the window left / right |
| `Space` | Session picker with previews (sessionx) |
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
