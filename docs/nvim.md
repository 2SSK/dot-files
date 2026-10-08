# Neovim

Config: `~/.config/nvim` (lazy.nvim, plugins pinned in `lazy-lock.json`). Colours are the desktop
theme's palette: `theme` renders it, `colors/desktop.lua` applies it with mini.base16, and running
nvims switch live. vim (`~/.vimrc`) follows the theme through the terminal palette.

## Plugins (25)

| Area | Plugins |
| --- | --- |
| Core | lazy.nvim |
| Picker, dashboard, explorer, notifications, zen, git blame, indent guides | snacks.nvim |
| Editing, diff signs, colour and TODO highlights, icons, colourscheme | mini.nvim |
| Completion | blink.cmp, friendly-snippets |
| LSP, formatters, linters | nvim-lspconfig, mason.nvim, mason-lspconfig.nvim, mason-tool-installer.nvim, lazydev.nvim, conform.nvim, nvim-lint |
| Syntax | nvim-treesitter (main), nvim-treesitter-textobjects |
| UI | lualine.nvim, bufferline.nvim (tabs), which-key.nvim, tiny-cmdline.nvim |
| Files and navigation | oil.nvim, vim-tmux-navigator, auto-session |
| Git conflicts | git-conflict.nvim |
| Markdown | render-markdown.nvim, markdown-preview.nvim |
| Code screenshots | nvim-silicon (theme background and a code theme rendered from the palette) |

Built into Neovim 0.12 instead of plugins: Copilot suggestions (inline completion with
`copilot-language-server` from Mason), folding (LSP and treesitter), and visual-mode `an` / `in`
to grow or shrink the selection by syntax node.

## Keys

Leader is Space. `Space ?` shows the keys of the current buffer; which-key lists the groups.

| Group | Keys |
| --- | --- |
| Files | `w` save, `q` quit, `Q` quit all, `-` / `Space -` parent directory (oil) |
| `f` Find | `ff` files, `fr` recent, `fs` grep (`pattern -- -g *.lua`), `fc` word under cursor, `fb` buffers, `ft` TODOs, `fh` help, `Space /` lines |
| `e` Explorer | `ee` file explorer, `en` nvim config |
| `c` Code | `ca` action, `cr` rename, `cf` format, `cl` lint, `cd` line diagnostics, `cs` symbols, `cR` restart LSP, `cx` run `./run.sh` on the file |
| `x` Lists | `xx` diagnostics, `xX` buffer diagnostics, `xL` location list, `xQ` quickfix |
| `g` Git | `gs` status, `gl` log, `gf` file history, `gb` blame line, `gd` diff overlay, `gx` list conflicts, `gi` / `gI` issues, `gp` / `gP` pull requests |
| `u` UI | `un` dismiss notifications, `uh` notification history, `uz` zen |
| `s` Splits | `sv` / `sh` split, `se` equalise, `sx` close, `st` terminal below; `ss` (visual) screenshot |
| `t` Tabs | `to` new, `tx` close, `tf` buffer in new tab, `tt` floating terminal; `Shift+h/l` previous / next |
| `S` Session | `Sr` restore, `Ss` save |
| `m` Markdown | `md` preview in the browser |
| LSP | `gd` definition, `gD` declaration, `gR` references, `gi` implementation, `gt` type; built in: `K`, `[d` / `]d` |
| Conflicts | in a conflicted file: `co` ours, `ct` theirs, `cb` both, `c0` none, `]x` / `[x` next / previous |
| Insert | `Tab` accept Copilot suggestion, `Ctrl+]` dismiss it; menu: `Ctrl+j/k`, `Enter`, `Ctrl+e` |
| Other | `Esc` clears the search highlight, `Alt+h/j/k/l` moves lines, `]t` / `[t` TODOs, `Ctrl+h/j/k/l` splits and tmux panes, `Ctrl+t` terminal split |

## First start on a new machine

`tree-sitter-cli` and a C compiler (both in the `cli` package layer) build the treesitter
parsers; Mason installs the language servers listed in `config/plugins/mason.lua`, including
`copilot-language-server`. Sign in to Copilot once with `:LspCopilotSignIn` (an existing
`~/.config/github-copilot` sign-in is reused). In a read-only checkout (the test VM's share)
lazy.nvim keeps its lockfile in the state dir.
