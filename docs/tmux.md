# tmux

Config: `~/.config/tmux/tmux.conf`. The prefix is **`` ` ``** (backtick); press it twice
to type a literal backtick.

The status bar sits at the top, with no plugin: the session name on the left (`●` while the
prefix is held), the windows centred (the current one bold in the theme's primary colour, the
rest muted) and the host name on the right. Colours come from the desktop theme
(`~/.local/state/desktop/theme/tmux.conf`), so `theme` recolours a running tmux too.

Plugins are pinned in `packages/plugins.txt` and installed by `setup.sh` into
`~/.config/tmux/plugins` (no tpm): tmux-resurrect and vim-tmux-navigator.

## Keys (after the prefix)

| Key | Action |
| --- | --- |
| `w` / `s` | Split side by side / stacked, in the current directory |
| `h` `j` `k` `l` | Move to the pane left / down / up / right |
| `Ctrl+h/j/k/l` | Resize the pane (repeatable) |
| `m` | Zoom the pane |
| `Ctrl+←` / `Ctrl+→` | Move the window left / right |
| `Space` | Session picker (fzf in a popup): Enter goes, a new name makes one, Ctrl-X kills; `fts` in a shell |
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
the session picker (`fts`). They're saved every 15 minutes by `tmux-save.timer` (resurrect: windows,
splits, folders, pane contents, nvim sessions), whether a client is attached or not. A server up
less than 2 minutes isn't saved, so a fresh one never replaces a good save; and a save cut short (a
shutdown) that left resurrect's `last` pointing at nothing is repaired before the restore.
`prefix v` saves now. (No tmux-continuum: it saved only while an attached client's status bar
redrew, and its save during a shutdown once left nothing to restore.)

## herdr

[herdr](https://github.com/herdrdev/herdr) (a multiplexer for AI coding agents) uses the same keys:
tmux's sessions are its workspaces, windows its tabs, panes its panes. Its whole config is a theme
template (`~/.local/share/desktop/templates/herdr.toml`): `~/.config/herdr/config.toml` links to the
rendered file, so edit the template, not the link, and `theme` recolours a running herdr. Check it
with `herdr config check`.

| Key (after `` ` ``) | Action |
| --- | --- |
| `w` / `s`, `h` `j` `k` `l`, `Ctrl+h/j/k/l`, `m` | As in tmux: split, move, resize, zoom (`z` zooms too) |
| `c`, `n` / `p`, `1`–`9`, `,`, `&` | New tab, next / previous, go to, rename, close |
| `Ctrl+←` / `Ctrl+→` | Move the tab left / right |
| `Space` | Workspace picker |
| `x`, `d`, `r`, `[`, `?` | Close pane, detach, reload the config, copy mode, help |
| `Shift+r`, `Shift+s` | Resize mode, herdr's settings |

`Ctrl+h/j/k/l` without the prefix stay with the app: herdr can't hand them to nvim's splits the way
vim-tmux-navigator does, so they'd break nvim's own split moves.
