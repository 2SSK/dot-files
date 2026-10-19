# tmux

Config: `~/.config/tmux/tmux.conf`. The prefix is **`` ` ``** (backtick); press it twice
to type a literal backtick.

The status bar sits at the top, with no plugin: the session name on the left (`●` while the
prefix is held), the windows centred (the current one bold in the theme's primary colour, the
rest muted) and the host name on the right. Colours come from the desktop theme
(`~/.local/state/desktop/theme/tmux.conf`), so `theme` recolours a running tmux too.

Plugins are pinned in `packages/plugins.txt` and installed by `setup.sh` into
`~/.config/tmux/plugins` (no tpm): tmux-resurrect, vim-tmux-navigator and tmux-sessionx.

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

tmux starts in the background when you log in (i3's and sway's autostart run `tmux-save start`),
its saved sessions restored, so they're already there: `tmux attach -t <name>`, or `tmux attach` and
the sessionx picker. They're saved every 15 minutes by `tmux-save.timer` (resurrect: windows,
splits, folders, pane contents, nvim sessions), whether a client is attached or not. A server up
less than 2 minutes isn't saved, so a fresh one never replaces a good save; and a save cut short (a
shutdown) that left resurrect's `last` pointing at nothing is repaired before the restore.
`prefix v` saves now. (No tmux-continuum: it saved only while an attached client's status bar
redrew, and its save during a shutdown once left nothing to restore.)
