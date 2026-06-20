return {
  -- TailwindCSS LSP
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tailwindcss = {},
      },
    },
  },

  -- Colores inline (para las clases Tailwind)
  {
    "NvChad/nvim-colorizer.lua",
    opts = {
      user_default_options = {
        tailwind = true,
      },
    },
  },

  -- Autocompletado con color previews
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "roobert/tailwindcss-colorizer-cmp.nvim",
    },
    opts = function(_, opts)
      -- aseguramos que opts.formatting exista
      opts.formatting = opts.formatting or {}

      -- traemos el formateador original (para no romper iconos ni menús)
      local format_kinds = opts.formatting.format

      -- configuramos el colorizer
      require("tailwindcss-colorizer-cmp").setup({
        color_square_width = 2,
      })

      -- ahora reemplazamos el formateador
      opts.formatting.format = function(entry, item)
        -- no llamamos a formatter directamente, lo pasamos como función
        local tailwind_formatter = require("tailwindcss-colorizer-cmp").formatter
        if format_kinds then
          item = format_kinds(entry, item) -- mantener íconos originales
        end
        item = tailwind_formatter(entry, item)
        return item
      end

      return opts
    end,
  },
}
