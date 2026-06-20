-- dots/nvim/lua/plugins/lsp.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nixd = {},
        lua_ls = {},
        pyright = {},
        rust_analyzer = {},
        gopls = {},
        clangd = {},
        html = {},
        cssls = {},
        tailwindcss = {},
        ts_ls = {},
        yamlls = {},
        taplo = {},
        bashls = {},
        hls = {},
      },
    },
  },
}
