# VSCodium

VS Code without Microsoft's telemetry and licence (`vscodium-bin` from the AUR; Fedora: VSCodium's
own RPM repository, `packages/extra/vscodium.sh`). Opt-in with the dev packages (`install.sh dev`).

- **Look:** nothing but the editor. No activity bar, minimap, scrollbars, breadcrumbs or sticky
  scroll; the sidebar on the right, JetBrains Mono, the native title bar.
- **Colours:** the **Desktop** theme, the desktop theme's palette rendered by `theme` like every
  other app (`templates/vscodium/desktop-color-theme.json`). After a theme switch, `Space u r`
  (*Reload Window*) shows it: VSCodium reads a theme's file once and keeps it until a reload
  (tested: neither the file changing nor switching themes away and back re-reads it).
- **Extensions**, pinned from Open VSX in `packages/vscodium.txt` and installed by
  `packages/plugins.sh`: Vim, Prettier, ESLint, Go, basedpyright (Python), Containers (Docker),
  YAML, clangd. Bumping a version there and rerunning `plugins.sh` installs just that one.
- **Config:** `.config/VSCodium/User/settings.json` and `keybindings.json` (linked by setup; a
  setting changed in VSCodium's UI lands in the repo's copy).

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
| `Space s v` / `Space s h` | split right / down; `Ctrl+h/j/k/l` between splits, the arrows resize |
| `g d`, `g r`, `K` | definition, references, hover; `] d` / `[ d` next / previous problem |
| `Space c a`, `c r`, `c f`, `c s` | code action, rename, format, symbols |
| `Space x x` | problems; `Space g s` git, `Space g b` blame, `Space u z` zen mode, `Space u r` reload |

In the file explorer: `j` / `k` move, `l` opens, `a` new file, `A` new folder, `r` rename, `d` delete,
`Ctrl+l` back to the editor. `Ctrl+n` / `Ctrl+p` move through pickers and suggestions.
