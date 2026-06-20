local plugins = {
  -- DAP UI
  {
    "rcarriga/nvim-dap-ui",
    event = "VeryLazy",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },

  -- Mason DAP integration
  {
    "jay-babu/mason-nvim-dap.nvim",
    event = "VeryLazy",
    dependencies = {
      "mason-org/mason.nvim",
      "mfussenegger/nvim-dap",
    },
    opts = {
      handlers = {},
    },
  },

  {
    "mfussenegger/nvim-dap",
    config = function()
  local dap = require("dap")
  local map = vim.keymap.set

  ---------------------------------------------------
  -- Prefijo: <leader>d  (MENÚ DE DEBUG)
  ---------------------------------------------------

  -- ▶️ Control general
  map("n", "<leader>dd", dap.continue, {
    desc = "DAP Start / Continue",
  })

  map("n", "<leader>do", dap.step_over, {
    desc = "DAP Step Over",
  })

  map("n", "<leader>di", dap.step_into, {
    desc = "DAP Step Into",
  })

  map("n", "<leader>du", dap.step_out, {
    desc = "DAP Step Out",
  })

  map("n", "<leader>dr", dap.restart, {
    desc = "DAP Restart",
  })

  map("n", "<leader>dq", dap.terminate, {
    desc = "DAP Terminate",
  })

  ---------------------------------------------------
  -- 🧨 Breakpoints
  ---------------------------------------------------
  map("n", "<leader>db", dap.toggle_breakpoint, {
    desc = "Toggle Breakpoint",
  })

  map("n", "<leader>dB", function()
    local cond = vim.fn.input("Condición: ")
    dap.set_breakpoint(cond)
  end, {
    desc = "Conditional Breakpoint",
  })

  map("n", "<leader>dl", function()
    local log = vim.fn.input("Log: ")
    dap.set_breakpoint(nil, nil, log)
  end, {
    desc = "Log Breakpoint",
  })

  map("n", "<leader>df", dap.list_breakpoints, {
    desc = "List Breakpoints",
  })

  ---------------------------------------------------
  -- 🔍 Inspección
  ---------------------------------------------------
  map("n", "<leader>dh", function()
    require("dap.ui.widgets").hover()
  end, { desc = "Hover Variables" })

  map("n", "<leader>ds", function()
    require("dap.ui.widgets").scopes()
  end, { desc = "Show Scopes" })

  ---------------------------------------------------
  -- 🧪 REPL
  ---------------------------------------------------
  map("n", "<leader>de", dap.repl.open, {
    desc = "Open REPL",
  })

  map("n", "<leader>dE", dap.repl.close, {
    desc = "Close REPL",
  })

  map("n", "<leader>dc", dap.run_to_cursor, {
    desc = "Run to Cursor",
  })

  ---------------------------------------------------
  -- 🪟 UI
  ---------------------------------------------------
  map("n", "<leader>dui", function()
    require("dapui").toggle({})
  end, {
    desc = "Toggle DAP UI",
  })
    end,
  }
}

return plugins
