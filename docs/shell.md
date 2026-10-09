# Shell

zsh is the primary shell. bash is kept simple: the same environment, aliases, functions
and [starship](https://starship.rs) prompt, with history, but no plugins or vim mode.

## Layout

| Path | Purpose |
| --- | --- |
| `~/.zshenv` | Sets `ZDOTDIR=~/.config/zsh` and loads the shared environment |
| `~/.config/shell/env.sh` | `EDITOR`, XDG dirs, `PATH` (deduplicated, existing dirs only) |
| `~/.config/shell/aliases.sh` | Aliases for both shells |
| `~/.config/shell/functions.sh` | Fuzzy helpers for both shells |
| `~/.config/shell/fzf.sh` | fzf options for both shells |
| `~/.config/zsh/` | `.zshrc` and its modules: `options`, `completion`, `keys`, `plugins`, `tools` |
| `~/.bashrc`, `~/.config/bash/` | bash modules: `options` (history), `tools` (starship) |
| `~/.config/starship/starship.toml` | Prompt |
| `~/.config/zsh/local.zsh`, `~/.config/bash/local.bash` | Machine-only settings and secrets (untracked) |

zsh plugins are pinned to release tags in `packages/plugins.txt` and installed by
`setup.sh`: zsh-autosuggestions, zsh-syntax-highlighting and fzf-tab.

## Prompt

`~/.config/starship/starship.toml` is the original starship config. Its colours are ANSI names (blue,
green, ...), so the prompt follows the desktop theme like the rest of the terminal.

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
| `Ctrl+p` / `Ctrl+n`, `↑` / `↓` | Search history for lines starting with what you typed |
| `Ctrl+r` | Fuzzy-search all history (fzf) |
| `Ctrl+e` | Accept the grey suggestion |
| `Ctrl+w` | Accept the suggestion and run it |
| `Alt+l` | Accept the next word of the suggestion |
| `Ctrl+u` | Turn suggestions on or off *(zsh)* |

History is shared between open zsh sessions, deduplicated, and stored in
`~/.local/state/{zsh,bash}/history`. Commands starting with a space are not saved;
history expansions like `!!` are shown for confirmation before they run.

### Navigation and completion

| Key / command | Action |
| --- | --- |
| `Tab` | Completion menu with fzf-tab (type to filter, `<` `>` switch groups, previews for `cd`/`ls`) *(zsh)* |
| `Ctrl+t` | Insert a file path chosen with fzf (bat preview) |
| `Alt+c` | `cd` into a directory chosen with fzf |
| `cd <part>` | Jump to the most used directory matching `<part>` (zoxide) |
| `cdi` | Pick a directory interactively (zoxide) |
| `<dir>` | Typing a directory name alone enters it |
| `Alt+s` | Toggle `sudo` in front of the line; on an empty line, use the previous command *(zsh)* |

`Ctrl+h/j/k/l` are reserved for moving between tmux panes and nvim splits
([tmux.md](tmux.md)).

## Functions

| Function | Use |
| --- | --- |
| `fkill [SIGNAL]` | Pick your processes (`Tab` selects several) and send `TERM` or `SIGNAL` |
| `frg <pattern>` | Search with ripgrep, preview with the match highlighted, `Enter` opens `$EDITOR` at that line |
| `fgl [git log args]` | Browse the git log graph with commit previews; `Enter` shows the full commit |
| `fdex [shell]` | Pick a running Docker container and exec into it (`sh` by default) |
| `y [dir]` | yazi file manager; quitting leaves the shell in the directory you were browsing |
| `mkcd <dir>` | Create a directory and enter it |
| `extract <archive>` | Unpack tar.*, zip, rar, 7z, gz, bz2, xz, zst into the current directory |
| `backup <file>` | Copy beside it, stamped with the time |
| `killport <port>` | Stop whatever listens on a TCP port |
| `calc <expr>`, `dirsize [dir]`, `path`, `hgrep <text>`, `sysinfo` | Arithmetic (2 decimals), a directory's size, PATH one per line, search history, host summary |

## Aliases

| Group | Aliases |
| --- | --- |
| Files | `ls`, `ll` (long, with git status), `la` (all), `lt`/`tree` (tree, 2/3 levels), `lsa` (all, with sizes): [eza](https://eza.rocks) with icons, directories first; plain coloured `ls` when eza is missing. `cp`, `mv`, `rm` ask before overwriting; `mkdir` creates parents |
| Colour | `grep`, `diff`, `ip`, `dir`, `vdir` use their built-in colours |
| Git | `gs` status, `gd` diff, `gds` staged diff, `ga` add, `gap` add patch, `gc` commit, `gp` push, `gu` pull, `gb` branch, `gsw` switch, `gm` merge, `grb` rebase, `gr` reset, `gcl` clone, `gl` log graph |
| Docker | `dco` compose, `dps` ps, `dpa` ps -a, `dx` exec -it |
| Tools | `vi` nvim, `t` tmux, `lg` lazygit, `ldc` lazydocker, `ff` fastfetch, `top` btop |
| Packages (yay) | `u` upgrade everything, `i` install, `r` remove with unneeded deps, `s` fuzzy-search repos and AUR with a preview and install the picks |
| Clipboard | `c` copy, `v` paste: wl-clipboard on Wayland, xclip on X11 |
| Navigation | `..`, `...`, `.3`, `.4`, `.5` up; `g.` ~/.config, `gD` ~/Documents, `gS` ~/Pictures/Screenshots |
| System | `df`, `du`, `free` human-readable; `mem`, `cpu` top 5 processes; `psg` find a process; `off` power off |
| Network | `myip` local and external address, `ports` listening sockets, `listening` open connections; `status`, `list`, `connect`, `disconnect` (nmcli) |
| Shell | `cl` clear, `e` exit, `rel` restart the shell, `rmf` rm -rf, `gi` git init, `di` docker image, `nrd` npm run dev, `ys`/`yd` yarn start/dev |
| Fun | `weather`, `tc` tty-clock, `sl`, `p` pipes.sh, `cb` cbonsai, `aq` asciiquarium, `cm` cmatrix |

## Colours

Starship, fzf, autosuggestions, `ls`, bat and btop (TTY theme, transparent background) use
the terminal's 16 ANSI colours, so they follow the central desktop theme that kitty and foot
load. See [theme.md](theme.md).

## Maintenance

- Tool init scripts (starship, zoxide, fzf, dircolors) are cached in `~/.cache/shell`;
  delete it after changing how a tool is initialised.
- Completion data is rebuilt at most once a day (`~/.cache/zsh/zcompdump`).
- Startup time: `zsh -i -c exit` takes about 60 ms with all plugins.
