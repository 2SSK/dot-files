return {
  "EL-MASTOR/bufferlist.nvim",
  lazy = true,
  keys = { { "<Leader>b", desc = "Open bufferlist" } }, -- keymap to load the plugin, it should be the same as keymap.open_bufferlist
  dependencies = "nvim-tree/nvim-web-devicons",
  cmd = "BufferList",
  opts = {
    keymap = {
      open_bufferlist = "<leader>b",
      close_buf_prefix = "c",
      force_close_buf_prefix = "f",
      save_buf = "s",
      multi_close_buf = "m",
      multi_save_buf = "w",
      save_all_unsaved = "a",
      close_all_saved = "d0",
      close_bufferlist = "q",
    },
    width = 40,
    prompt = "", -- for multi_{close,save}_buf prompt
    save_prompt = "󰆓 ",
    top_prompt = true, -- set this to false if you want the prompt to be at the bottom of the window instead of on top of it.
  },
}
