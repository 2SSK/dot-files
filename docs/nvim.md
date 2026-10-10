# Neovim

nvim is the main editor; vim (`~/.vimrc`) is a light fallback with the same basic keys. Both
follow the desktop theme live with a transparent background: run `theme set <family>` and
every open nvim and vim switches.

## Layout

| Path | Purpose |
| --- | --- |
| `~/.config/nvim/init.lua` | Loads `core`, then lazy.nvim, then the theme |
| `lua/core/` | `options`, `keymaps`, `terminal` (no plugins needed) |
| `lua/config/plugins/` | One file per plugin or area |
| `lua/config/multiplugins.lua` | Small plugins: bufferline, git-conflict, silicon, tmux navigator, cmdline |
| `lua/config/theme.lua`, `colors/desktop.lua` | Desktop theme: palette → mini.base16, transparency, live reload |
| `plugin/floatterminal.lua` | Floating terminal |
| `lazy-lock.json` | Pinned plugin versions |
| `~/.vimrc` | vim: options, keys, netrw, the theme's `vim.vim` |

The theme engine renders `nvim.lua` (base16 palette), `vim.vim` and `silicon.tmTheme` into
`~/.local/state/desktop/theme/`. nvim reloads on SIGUSR1 from `theme`; vim checks the file
once a second.

## Look

- Colours from the desktop palette; transparent background, line numbers and tab bar.
- Status line (lualine) with rounded section edges; tab bar (bufferline) on top.
- Only the indent line of the scope under the cursor is drawn.
- Messages and the command line in a floating line (`cmdheight=0`), notifications as pop-ups,
  prompts in floating windows, a start dashboard.

## Features

**Finding** (snacks picker, ivy layout at the bottom, 70% of the screen)
- Files (hidden and ignored included, junk excluded), recent files, live grep with glob
  filters (`pattern -- -g *.lua`), word under cursor, buffers, TODOs, help, lines in the buffer.
- File explorer sidebar on the right with git status; oil (`-`) edits a directory like a buffer.

**Editing**
- Completion menu (blink.cmp): LSP, paths, snippets (friendly-snippets), buffer words, with docs.
- Copilot as ghost text: accept, reject, cycle suggestions or ask for a new one.
- Auto pairs, surround (`sa` add, `sd` delete, `sr` replace), move lines with `Alt+h/j/k/l`.
- Text objects: `af`/`if` function, `ac`/`ic` class, `aa`/`ia` argument, quotes and brackets
  (mini.ai); `an`/`in` in visual mode grow or shrink the selection by syntax node.
- TODO/FIXME/HACK/NOTE highlighted; hex colours shown in their colour.

**Code**
- LSP: Lua, Python, TS/JS, C/C++, Zig, Tailwind, GraphQL, HTML/CSS, Emmet, Copilot (Mason
  installs these), plus Go (`gopls`) and Rust (`rust-analyzer`) when their toolchain is installed.
- Format on save (prettier, stylua, black + isort, beautysh), linting (nvim-lint).
- Treesitter highlighting, indentation and folding for 30 languages; folds start open.

**Git**
- Changed lines in the sign column; inline diff overlay.
- Status, log and file history pickers; blame for the current line; GitHub issues and PRs.
- Merge conflicts highlighted, resolved with two keys, listed in the quickfix list.

**Workflow**
- Splits, tabs, a terminal below or floating; `Ctrl+h/j/k/l` crosses nvim splits and tmux panes.
- Per-project sessions, zen mode, markdown rendered in place plus a browser preview.
- Code screenshots of a selection in the theme's colours (saved to the current directory).

## Keys

Leader is `Space`. Press it and wait to see every group (which-key); `Space ?` lists the
keys of the current buffer.

### Everyday

| Key | Action |
| --- | --- |
| `jk` | Leave insert mode (also in the terminal) |
| `Esc` | Clear the search highlight and notifications |
| `Space w` / `q` / `Q` | Save / quit / quit all |
| `-` / `Space -` | Parent directory in oil / in a float |
| `Ctrl+h/j/k/l` | Move between splits and tmux panes |
| `Alt+h/j/k/l` | Move the line or selection |
| `]t` / `[t` | Next / previous TODO |

### Find `Space f`, explorer `Space e`

| Key | Action |
| --- | --- |
| `ff` / `fr` | Files / recent files |
| `fs` / `fc` | Grep / grep the word under the cursor |
| `fb` / `ft` / `fh` | Buffers / TODOs / help |
| `Space /` | Lines in this buffer |
| `ee` / `en` | File explorer / nvim config files |

In a picker: type to filter, `Ctrl+j/k` or arrows to move, `Enter` open, `Ctrl+v` / `Ctrl+s`
open in a vertical / horizontal split, `Tab` select several, `Esc` close.

### Code `Space c`, lists `Space x`

| Key | Action |
| --- | --- |
| `gd` / `gD` / `gR` / `gi` / `gt` | Definition / declaration / references / implementation / type |
| `K` | Hover docs |
| `[d` / `]d` | Previous / next diagnostic |
| `ca` / `cr` | Code action / rename |
| `cf` / `cl` | Format (file or selection) / lint |
| `cd` / `cs` | Line diagnostics / symbols |
| `cR` / `cx` | Restart LSP / run `./run.sh` on this file |
| `xx` / `xX` | Diagnostics / this buffer's diagnostics |
| `xL` / `xQ` | Location list / quickfix list |

### Git `Space g`

| Key | Action |
| --- | --- |
| `gs` / `gl` / `gf` | Status / log / this file's history |
| `gb` / `gd` | Blame line / diff overlay |
| `gi` / `gI` | GitHub issues: open / all |
| `gp` / `gP` | Pull requests: open / all |
| `gx` | List conflicts |
| `co` / `ct` / `cb` / `c0` | In a conflict: keep ours / theirs / both / none |
| `]x` / `[x` | Next / previous conflict |

### Insert mode

| Key | Action |
| --- | --- |
| `Ctrl+a` / `Tab` | Accept the Copilot suggestion (`Tab` jumps in a snippet first) |
| `Ctrl+r` / `Ctrl+]` | Reject the suggestion |
| `Alt+n` / `Alt+p` | Next / previous suggestion |
| `Alt+r` | Ask Copilot for a new suggestion |
| `Ctrl+Space` | Open the completion menu |
| `Ctrl+j/k`, `Enter`, `Ctrl+e` | Move, accept, close the menu |
| `Ctrl+b/f` | Scroll the docs |

With no suggestion showing, `Ctrl+a` and `Ctrl+r` keep their usual insert-mode meaning (the last
insert again; paste a register).

### Windows `Space s`, tabs `Space t`, UI `Space u`

| Key | Action |
| --- | --- |
| `sv` / `sh` / `se` / `sx` | Split vertically / horizontally, equalise, close |
| `Ctrl+arrows` | Resize the split |
| `to` / `tx` / `tf` | New tab / close tab / this buffer in a new tab |
| `Shift+h` / `Shift+l` | Previous / next tab |
| `tt` / `st` / `Ctrl+t` | Floating terminal / terminal below / terminal on the right |
| `un` / `uh` | Dismiss notifications / notification history |
| `uz` | Zen mode |
| `Sr` / `Ss` | Restore / save the session for this directory |
| `md` | Markdown preview in the browser |
| `ss` *(visual)* | Screenshot the selection |

## vim

The same options and most keys as nvim (`jk`, `Space w/q`, splits `Space s…`, tabs
`Space t…`, `Tab` / `Shift+Tab` buffers, `Space e` netrw explorer), no plugins.

## First start on a new machine

`tree-sitter-cli` and a C compiler (both in the `cli` package layer) build the treesitter
parsers; Mason installs the language servers, including `copilot-language-server`. Sign in
to Copilot once with `:LspCopilotSignIn` (an existing `~/.config/github-copilot` sign-in is
reused). In a read-only checkout (the test VM's share) lazy.nvim keeps its lockfile in the
state dir.
