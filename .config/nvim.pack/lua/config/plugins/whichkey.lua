require("which-key").setup({
  preset = "helix",
  delay = 300,
  icons = {
    rules = false,
    breadcrumb = " ",
    separator = "󱦰  ",
    group = "󰹍 ",
  },
  plugins = {
    spelling = {
      enabled = false,
    },
  },
  win = {
    height = {
      max = math.huge,
    },
  },
  spec = {
    { mode = { "n", "v" }, { "<leader>f", group = "Find" } },
    { mode = { "n", "v" }, { "<leader>G", group = "Git" } },
    { mode = { "n", "v" }, { "<leader>g", group = "Gitsigns" } },
    { mode = { "n", "v" }, { "<leader>R", group = "Replace" } },
    { mode = { "n", "v" }, { "<leader>l", group = "LSP" } },
    { mode = { "n", "v" }, { "<leader>c", group = "LSP (Trouble)" } },
    { mode = { "n", "v" }, { "<leader>t", group = "Test" } },
    { mode = { "n", "v" }, { "<leader>D", group = "Debugger" } },
    { mode = { "n", "v" }, { "<leader>s", group = "Search" } },
    { mode = { "n", "v" }, { "<leader>u", group = "Toggle Features" } },
    { mode = { "n", "v" }, { "<leader>W", group = "Workspace" } },
    { mode = { "n", "v" }, { "[", group = "prev" } },
    { mode = { "n", "v" }, { "]", group = "next" } },
    { mode = { "n", "v" }, { "g", group = "goto" } },
  },
})

vim.keymap.set("n", "<leader>?", function()
  require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })
