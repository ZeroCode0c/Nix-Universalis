-- dots/nvim/lua/plugins/rust.lua
-- rustaceanvim es mejor que el LSP genérico para rust
return {
  {
    "mrcjkb/rustaceanvim",
    version = "^4",
    ft = { "rust" },
    config = function()
      vim.g.rustaceanvim = {
        server = {
          settings = {
            ["rust-analyzer"] = {
              cargo    = { allFeatures = true },
              checkOnSave = { command = "clippy" },
            },
          },
        },
      }
    end,
  },
}
