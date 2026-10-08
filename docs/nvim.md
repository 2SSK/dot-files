# Neovim

Config: `~/.config/nvim` (lazy.nvim, plugins pinned in `lazy-lock.json`). Colours follow the
desktop theme live (`config/theme.lua`); vim (`~/.vimrc`) follows it through the terminal palette.

## Plugins (32)

| Area | Plugins |
| --- | --- |
| Core | lazy.nvim, plenary.nvim |
| Picker, dashboard, explorer, notifications, zen, lazygit, git blame, indent guides | snacks.nvim |
| Editing helpers: text objects, pairs, surround, move lines, diff signs, colour and TODO highlights, icons | mini.nvim |
| Completion | blink.cmp, friendly-snippets |
| LSP, formatters, linters | nvim-lspconfig, mason.nvim, mason-lspconfig.nvim, mason-tool-installer.nvim, lazydev.nvim, conform.nvim, nvim-lint |
| Syntax | nvim-treesitter (main), nvim-treesitter-textobjects |
| UI | lualine.nvim, which-key.nvim, tiny-cmdline.nvim |
| Files and navigation | oil.nvim, harpoon, vim-tmux-navigator, auto-session |
| AI | copilot.lua, CopilotChat.nvim |
| Markdown | render-markdown.nvim, markdown-preview.nvim |
| Other | nvim-silicon (code screenshots) |
| Colourschemes | tokyonight, catppuccin, gruvbox, rose-pine, e-ink |

Built into Neovim 0.12 instead of plugins: folding (LSP and treesitter), and visual-mode
`an` / `in` to grow or shrink the selection by syntax node.

## Keys that changed

| Key | Now |
| --- | --- |
| `<leader>ff` `fr` `fs` `fc` `fg` `/` `en` | snacks picker, same meaning (in grep, `pattern -- -g *.lua` filters by glob) |
| `<leader>fb` / `ft` / `fh` | Buffers / TODO comments / help (new) |
| `gd` `gR` `gi` `gt` `<leader>D` | LSP pickers in snacks |
| `<leader>xx` `xX` `cs` `xL` `xQ` | Diagnostics, symbols, location and quickfix lists in snacks (were Trouble) |
| `<leader>gs` / `gl` / `gf` / `gb` | lazygit / git log / file history / blame line (fugitive is gone) |
| `<leader>uz` / `un` | Zen mode / notification history |
| `Alt+h/j/k/l` | Move the line or selection (mini.move) |
| `]t` / `[t` | Next / previous TODO comment |
| `Ctrl+j/k`, `Enter`, `Ctrl+e` | Completion menu: next / previous, accept, close (blink.cmp) |

Removed: bufferline (use `<leader>fb` or harpoon), fugitive's merge keys (resolve conflicts in
lazygit), Trouble's LSP panel, obsidian.nvim.

## First start on a new machine

`tree-sitter-cli` and a C compiler (both in the `cli` package layer) build the treesitter
parsers; Mason installs the language servers listed in `config/plugins/mason.lua`. In a
read-only checkout (the test VM's share) lazy.nvim keeps its lockfile in the state dir.
