-- ~/.config/nvim/lua/plugins/luasnip.lua
return {
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",

    config = function()
      local ok, ls = pcall(require, "luasnip")
      if not ok then
        return
      end

      -- Opcional: carga friendly-snippets
      -- pcall(require, "luasnip.loaders.from_vscode").lazy_load()

      -- Expandir / aceptar snippet con Ctrl+y
      vim.keymap.set({ "i", "s" }, "<C-y>", function()
        if ls.expand_or_jumpable() then
          ls.expand_or_jump()
        end
      end, { expr = true, silent = true })

      -- Saltar al siguiente nodo con Ctrl+j
      vim.keymap.set({ "i", "s" }, "<C-j>", function()
        if ls.jumpable(1) then
          ls.jump(1)
        end
      end, { silent = true })

      -- Saltar al nodo anterior con Ctrl+k
      vim.keymap.set({ "i", "s" }, "<C-k>", function()
        if ls.jumpable(-1) then
          ls.jump(-1)
        end
      end, { silent = true })

      -- Avanzar en choice_node con Ctrl+l
      vim.keymap.set({ "i", "s" }, "<C-l>", function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end, { silent = true })

      -- Retroceder en choice_node con Ctrl+h
      vim.keymap.set({ "i", "s" }, "<C-h>", function()
        if ls.choice_active() then
          ls.change_choice(-1)
        end
      end, { silent = true })
    end,
  },
}
