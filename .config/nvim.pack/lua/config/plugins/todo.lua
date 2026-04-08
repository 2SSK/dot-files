local todo_comments = require("todo-comments")

vim.keymap.set("n", "]t", function()
  todo_comments.jump_next()
end, { desc = "Next todo comment" })

vim.keymap.set("n", "[t", function()
  todo_comments.jump_prev()
end, { desc = "Previous todo comment" })

todo_comments.setup()
