return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "leoluz/nvim-dap-go",
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
      "williamboman/mason.nvim",
    },
    config = function()
      local dap = require("dap")
      local ui = require("dapui")

      require("dapui").setup()
      require("dap-go").setup()

      require("nvim-dap-virtual-text").setup({
        display_callback = function(variable)
          local name = string.lower(variable.name)
          local value = string.lower(variable.value)
          if name:match("secret") or name:match("api") or value:match("secret") or value:match("api") then
            return "*****"
          end

          if #variable.value > 15 then
            return " " .. string.sub(variable.value, 1, 15) .. "... "
          end

          return " " .. variable.value
        end,
      })

      -- C++ Debugger Configuration
      dap.adapters.cppdbg = {
        type = "executable",
        command = "OpenDebugAD7", -- Make sure this points to your OpenDebugAD7 installation
      }

      dap.configurations.cpp = {
        {
          name = "Launch file",
          type = "cppdbg",
          request = "launch",
         program = "${workspaceFolder}/path/to/your/executable", -- Update to your executable path
          args = {}, -- Arguments to pass to the program
          stopAtEntry = false,
          cwd = "${workspaceFolder}",
          environment = {}, -- Environment variables
          externalConsole = false,
          MIMode = "gdb", -- Use "lldb" for LLDB
          setupCommands = {
            {
              text = "-enable-pretty-printing",
              description = "Enable pretty printing",
              ignoreFailures = true,
            },
          },
        },
      }

      -- Elixir Debugger Configuration
      local elixir_ls_debugger = vim.fn.exepath("elixir-ls-debugger")
      if elixir_ls_debugger ~= "" then
        dap.adapters.mix_task = {
          type = "executable",
          command = elixir_ls_debugger,
        }

        dap.configurations.elixir = {
          {
            type = "mix_task",
            name = "phoenix server",
            task = "phx.server",
            request = "launch",
            projectDir = "${workspaceFolder}",
            exitAfterTaskReturns = false,
            debugAutoInterpretAllModules = false,
          },
        }
      end

      -- Additional Adapter Configuration (if needed)
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = "codelldb",
          args = { "--port", "${port}" },
        },
      }

      -- Updated Keybindings
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint) -- Toggle breakpoint
      vim.keymap.set("n", "<leader>dgb", dap.run_to_cursor) -- Run to cursor

      -- Eval variable under cursor
      vim.keymap.set("n", "<leader>d?", function()
        require("dapui").eval(nil, { enter = true })
      end)

      vim.keymap.set("n", "<leader>d1", dap.continue) -- Continue
      vim.keymap.set("n", "<leader>d2", dap.step_into) -- Step into
      vim.keymap.set("n", "<leader>d3", dap.step_over) -- Step over
      vim.keymap.set("n", "<leader>d4", dap.step_out) -- Step out
      vim.keymap.set("n", "<leader>d5", dap.step_back) -- Step back
      vim.keymap.set("n", "<leader>d13", dap.restart) -- Restart

      dap.listeners.before.attach.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        ui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        ui.close()
      end
    end,
  },
}
