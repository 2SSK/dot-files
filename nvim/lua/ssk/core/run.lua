vim.api.nvim_set_keymap("n", "<C-n>", "", {
  noremap = true,
  silent = true,
  callback = function()
    local file_path = vim.api.nvim_buf_get_name(0)
    local file_name = vim.fn.fnamemodify(file_path, ":t")
    local file_type = vim.bo.filetype

    if file_type == "lua" then
      vim.cmd(":terminal lua " .. file_path)
    elseif file_type == "c" then
      vim.cmd(
        ":terminal gcc " .. file_path .. " -o " .. file_name:gsub("%.c$", "") .. " && ./" .. file_name:gsub("%.c$", "")
      )
    elseif file_type == "cpp" then
      vim.cmd(
        ":terminal g++ "
          .. file_path
          .. " -o "
          .. file_name:gsub("%.cpp$", "")
          .. " && ./"
          .. file_name:gsub("%.cpp$", "")
      )
    elseif file_type == "python" then
      vim.cmd(":terminal python3 " .. file_path)
    elseif file_type == "go" then
      vim.cmd(":terminal go run " .. file_path)
    elseif file_type == "rust" then
      vim.cmd(
        ":terminal rustc "
          .. file_path
          .. " -o "
          .. file_name:gsub("%.rs$", "")
          .. " && ./"
          .. file_name:gsub("%.rs$", "")
      )
    elseif file_type == "java" then
      vim.cmd(":terminal javac " .. file_path .. " && java " .. file_name:gsub("%.java$", ""))
    elseif file_type == "javascript" then
      vim.cmd(":terminal node " .. file_path)
    elseif file_type == "typescript" then
      vim.cmd(":terminal ts-node " .. file_path)
    elseif file_type == "sh" then
      vim.cmd(":terminal bash " .. file_path)
    else
      print("File type not supported for this command")
    end
  end,
})
