# VSCodium

VS Code without Microsoft's telemetry and licence (`vscodium-bin` from the AUR; Fedora: VSCodium's
own RPM repository, `packages/extra/vscodium.sh`). Opt-in with the dev packages (`install.sh dev`).

- **Look:** nothing but the editor. No activity bar, minimap, scrollbars, breadcrumbs or sticky
  scroll; the sidebar on the right, JetBrains Mono, the native title bar.
- **Colours:** the desktop theme's, live: a theme switch shows at once, no reload. `theme` renders
  them (`templates/vscodium/colors.json`) and `desktop-vscodium` writes VSCodium's `settings.json`
  as the repo's base plus those colours, on VSCodium's own Default Dark/Light Modern. (A theme
  extension can't do this: VSCodium caches its colours across reloads and restarts. Tested.)
- **Extensions**, pinned from Open VSX in `packages/vscodium.txt` and installed by
  `packages/plugins.sh`: Vim, Prettier, ESLint, Go, basedpyright (Python), Containers (Docker),
  YAML, clangd. Bumping a version there and rerunning `plugins.sh` installs just that one.
- **Config:** settings in `.config/VSCodium/settings.jsonc` (the base: edit this one, then run
  `desktop-vscodium` or switch the theme), keys in `.config/VSCodium/User/keybindings.json`. A
  setting changed in VSCodium's own settings screen lasts until the next theme switch.

## Keys

Vim (VSCodeVim) the way `~/.vimrc` and nvim have it: Space is the leader, `jk` leaves insert mode,
yanks go to the system clipboard, `x` and a visual `p` don't overwrite what you yanked, `n`, `N`,
`Ctrl+d` and `Ctrl+u` keep the cursor centred.

| Keys | Does |
|---|---|
| `Alt+a` | show or hide the terminal (from the editor or the terminal) |
| `Ctrl+Shift+t` | a new terminal |
| `Ctrl+\` | split the terminal; `Alt+h` / `Alt+l` move between its panes; `Ctrl+Shift+w` closes one |
| `Ctrl+b`, `Space e` | show or hide the sidebar |
| `Ctrl+p`, `Space f f` | find a file by name; `Space f r` recent, `Space f b` open editors |
| `Ctrl+Shift+f`, `Space f s` | search in files; `Space /` in this file |
| `Tab` / `Shift+Tab`, `H` / `L` | next / previous editor; `Space x` or `Space q` closes it, `Space Q` all |
| `Space w` | save (`Space s n` without formatting) |
| `Space s v` / `Space s h` | split vertically (right) / horizontally (below); `Ctrl+h/j/k/l` between splits, the arrows resize |
| `Space s t` / `Space s x` | a new tab in this window / close the file (its split goes with its last file) |
| `g d`, `g r`, `K` | definition, references, hover; `] d` / `[ d` next / previous problem |
| `Space c a`, `c r`, `c f`, `c s` | code action, rename, format, symbols |
| `Space x x` | problems; `Space g s` git, `Space g b` blame, `Space u z` zen mode, `Space u r` reload |
| `Space n h` | clear the search highlight (vim's and the find widget's) |
| `Ctrl+w` `v` `s` `h` `j` `k` `l` `w` `q` `o` `=` `_` | vim's window commands: split, move, close, only, even, maximise |

In the file explorer: `j` / `k` move, `l` opens, `a` new file, `A` new folder, `r` rename, `d` delete,
`Ctrl+l` back to the editor. `Ctrl+n` / `Ctrl+p` move through pickers and suggestions.
