-- dots/nvim/lua/plugins/dev-tools.lua
return {
  -- Ejecutar tests dentro de nvim (rust, python, go, etc)
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-neotest/neotest-python",
      "rouge8/neotest-rust",
      "nvim-neotest/neotest-go",
    },
    keys = {
      {
        "<leader>tt",
        function()
          require("neotest").run.run()
        end,
        desc = "Run nearest test",
      },
      {
        "<leader>tf",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Run file tests",
      },
      {
        "<leader>to",
        function()
          require("neotest").output.open()
        end,
        desc = "Test output",
      },
      {
        "<leader>ts",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Test summary",
      },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python"),
          require("neotest-rust"),
          require("neotest-go"),
        },
      })
    end,
  },

  -- Correr cargo commands sin salir de nvim
  {
    "saecki/crates.nvim",
    event = "BufRead Cargo.toml",
    opts = {
      completion = { cmp = { enabled = true } },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },

  -- Ver errores/warnings inline
  {
    "folke/trouble.nvim",
    opts = { use_diagnostic_signs = true },
  },

  -- Git diff avanzado
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff view" },
      { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "File history" },
    },
  },

  -- Terminal flotante
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        win = { position = "float", height = 0.8, width = 0.8 },
      },
    },
    keys = {
      {
        "<leader>gg",
        function()
          Snacks.lazygit()
        end,
        desc = "Lazygit",
      },
      {
        "<leader>ct",
        function()
          Snacks.terminal()
        end,
        desc = "Terminal flotante",
      },
    },
  },
}
