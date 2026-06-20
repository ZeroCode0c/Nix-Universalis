-- ~/.config/nvim/lua/plugins/nvim-cmp.lua
return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "L3MON4D3/LuaSnip", -- motor de snippets
    "saadparwaiz1/cmp_luasnip", -- integración LuaSnip <-> nvim-cmp
    "hrsh7th/cmp-buffer", -- completado desde el buffer
    "hrsh7th/cmp-path", -- completado de rutas
    "hrsh7th/cmp-nvim-lsp", -- completado desde LSP
    "hrsh7th/cmp-cmdline", -- completado en cmdline
    "rafamadriz/friendly-snippets", -- snippets ya hechos
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    -- Carga automática de snippets desde friendly-snippets
    require("luasnip.loaders.from_vscode").lazy_load()

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = false }), -- Enter confirma selección

        -- Tab y Shift-Tab no hacen nada
        ["<Tab>"] = cmp.mapping(function(fallback)
          fallback()
        end, { "i", "s" }),

        ["<S-Tab>"] = cmp.mapping(function(fallback)
          fallback()
        end, { "i", "s" }),
      }),
      sources = cmp.config.sources({
        { name = "luasnip", priority = 1000 },
        { name = "nvim_lsp", priority = 750 },
        { name = "buffer", priority = 500 },
        { name = "path", priority = 250 },
      }),
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      experimental = {
        ghost_text = true,
      },
    })

    -- Configuración para completado en búsqueda (/)
    cmp.setup.cmdline("/", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = { { name = "buffer" } },
    })

    -- Configuración para completado en comandos (:)
    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
    })
  end,
}
