-- En tu configuración de LazyVim:
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.pl" },
  callback = function()
    vim.bo.filetype = "prolog"
  end,
})
