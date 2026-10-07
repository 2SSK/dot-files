# Shell

zsh is the default shell; bash is a full fallback with the same features through
[ble.sh](https://github.com/akinomyoga/ble.sh). Both share one environment, one set of
aliases and functions, and one [starship](https://starship.rs) prompt.

## Layout

| Path | Purpose |
| --- | --- |
| `~/.zshenv` | Sets `ZDOTDIR=~/.config/zsh` and loads the shared environment |
| `~/.config/shell/env.sh` | `EDITOR`, XDG dirs, `PATH` (deduplicated, existing dirs only) |
| `~/.config/shell/aliases.sh` | Aliases for both shells |
| `~/.config/shell/functions.sh` | Fuzzy helpers for both shells |
| `~/.config/shell/fzf.sh` | fzf options for both shells |
| `~/.config/zsh/` | `.zshrc` and its modules: `options`, `completion`, `keys`, `plugins`, `tools` |
| `~/.bashrc`, `~/.config/bash/` | bash modules: `options`, `keys`, `tools` |
| `~/.config/starship.toml` | Prompt |
| `~/.config/zsh/local.zsh`, `~/.config/bash/local.bash` | Machine-only settings and secrets (untracked) |

Plugins are pinned to release tags in `packages/plugins.txt` and installed by `setup.sh`:
zsh-autosuggestions, zsh-syntax-highlighting and fzf-tab for zsh, ble.sh for bash.

## Prompt

```
~/Dotfiles  rewrite !2 ?1                                     took 3s
❯
```

- Line 1: directory, git branch and status, language versions inside a project, and how
  long the last command took (over 2 s).
- Line 2: `❯` green, red after a failed command, `❮` in vim normal mode.
- `user@host` appears only over SSH or as root; `bash` is shown when running bash.

Git status symbols: `!` modified, `+` staged, `?` untracked, `✘` deleted, `»` renamed,
`*` stashed, `=` conflicted, `⇡`/`⇣` ahead/behind.

## Keys

### Vim mode

| Key | Action |
| --- | --- |
| *(start)* | Insert mode, beam cursor |
| `jk` or `Esc` | Normal mode, block cursor, prompt shows `❮` |
| `v` *(normal mode)* | Edit the command line in `$EDITOR`; save and quit runs it |

All normal vim motions and edits work on the command line (`w`, `b`, `0`, `$`, `dd`, `cw`, `ci"`, `u`, `.`).

### History and suggestions

| Key | Action |
| --- | --- |
| `Ctrl+k` / `Ctrl+j`, `↑` / `↓` | Search history for lines starting with what you typed |
| `Ctrl+r` | Fuzzy-search all history (fzf) |
| `Ctrl+e` | Accept the grey suggestion |
| `Ctrl+w` | Accept the suggestion and run it |
| `Ctrl+l` | Accept the next word of the suggestion *(zsh)* |
| `Ctrl+u` | Turn suggestions on or off *(zsh)* |

History is shared between open zsh sessions, deduplicated, and stored in
`~/.local/state/{zsh,bash}/history`. Commands starting with a space are not saved;
history expansions like `!!` are shown for confirmation before they run.

### Navigation and completion

| Key / command | Action |
| --- | --- |
| `Tab` | Completion menu: fzf-tab in zsh (type to filter, `<` `>` switch groups, previews for `cd`/`ls`), ble.sh menu in bash |
| `Ctrl+t` | Insert a file path chosen with fzf (bat preview) |
| `Alt+c` | `cd` into a directory chosen with fzf |
| `cd <part>` | Jump to the most used directory matching `<part>` (zoxide) |
| `cdi` | Pick a directory interactively (zoxide) |
| `<dir>` | Typing a directory name alone enters it |
| `Alt+s` | Toggle `sudo` in front of the line; on an empty line, use the previous command *(zsh)* |

## Functions

| Function | Use |
| --- | --- |
| `fkill [SIGNAL]` | Pick your processes (`Tab` selects several) and send `TERM` or `SIGNAL` |
| `frg <pattern>` | Search with ripgrep, preview with the match highlighted, `Enter` opens `$EDITOR` at that line |
| `fgl [git log args]` | Browse the git log graph with commit previews; `Enter` shows the full commit |
| `fdex [shell]` | Pick a running Docker container and exec into it (`sh` by default) |

## Aliases

| Group | Aliases |
| --- | --- |
| Files | `ls`, `ll`, `la` (coloured, directories first); `cp`, `mv`, `rm` ask before overwriting; `mkdir` creates parents |
| Colour | `grep`, `diff`, `ip`, `dir`, `vdir` use their built-in colours |
| Git | `gs` status, `gd` diff, `gds` staged diff, `ga` add, `gap` add patch, `gc` commit, `gp` push, `gu` pull, `gb` branch, `gsw` switch, `gm` merge, `grb` rebase, `gr` reset, `gcl` clone, `gl` log graph |
| Docker | `dco` compose, `dps` ps, `dpa` ps -a, `dx` exec -it |
| Tools | `vi` nvim, `t` tmux, `y` yazi, `lg` lazygit, `ldc` lazydocker, `ff` fastfetch, `top` btop |
| Shell | `cl` clear, `e` exit, `rel` restart the shell, `nrd` npm run dev |

## Colours

Starship, fzf, autosuggestions, `ls`, bat and btop (TTY theme, transparent background) use
the terminal's 16 ANSI colours, so they follow the central desktop theme that kitty and foot
load. See [theme.md](theme.md).

## Maintenance

- Tool init scripts (starship, zoxide, fzf, dircolors) are cached in `~/.cache/shell`;
  delete it after changing how a tool is initialised.
- Completion data is rebuilt at most once a day (`~/.cache/zsh/zcompdump`).
- Startup time: `zsh -i -c exit` takes about 60 ms with all plugins.
