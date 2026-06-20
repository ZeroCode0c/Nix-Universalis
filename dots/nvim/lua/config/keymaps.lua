-- Delete without yanking (black hole register)
vim.keymap.set({ "n", "v" }, "<Del>", '"_d', { desc = "Delete without yanking" })
vim.keymap.set("n", "<S-Del>", '"_dd', { desc = "Delete line without yanking" })

vim.keymap.set({ "n", "v" }, "d", '"_d', { desc = "Delete without yanking" })
vim.keymap.set("n", "dd", '"_dd', { desc = "Delete line without yanking" })

vim.keymap.set("n", "D", '"_D', { desc = "Delete big without yanking" })

local map = vim.keymap.set

-- Borrar marca específica (después de ` se escribirá la letra de la marca)
map("n", "`<Del>", function()
  local mark = vim.fn.input("Marca (`a-z`) a borrar: ")
  if mark ~= "" then
    vim.cmd("delmarks " .. mark)
    print("Marca `" .. mark .. "` borrada")
  end
end, { desc = "Borrar marca específica" })

-- Borrar todas las marcas (Shift+Delete)
map("n", "`<S-Del>", function()
  vim.cmd("delmarks a-z")
  print("Todas las marcas borradas")
end, { desc = "Borrar todas las marcas" })

-- local ls = require("luasnip")
--
-- vim.keymap.set({ "i", "s" }, "<Tab>", function()
--   if ls.expand_or_jumpable() then
--     return ls.expand_or_jump()
--   else
--     return "<Tab>"
--   end
-- end, { expr = true, silent = true })
--
-- vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
--   if ls.jumpable(-1) then
--     return ls.jump(-1)
--   else
--     return "<S-Tab>"
--   end
-- end, { expr = true, silent = true })

-- -- Normal mode: mover líneas
-- vim.keymap.set("n", "<C-j>", ":m .+1<CR>==", { desc = "Mover línea abajo" })
-- vim.keymap.set("n", "<C-k>", ":m .-2<CR>==", { desc = "Mover línea arriba" })
--
-- -- Visual mode: mover bloque
-- vim.keymap.set("v", "<C-j>", ":m '>+1<CR>gv=gv", { desc = "Mover bloque abajo" })
-- vim.keymap.set("v", "<C-k>", ":m '<-2<CR>gv=gv", { desc = "Mover bloque arriba" })
