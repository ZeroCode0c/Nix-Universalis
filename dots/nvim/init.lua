-- Filename: ~/github/dotfiles-latest/neovim/neobean/init.lua
-- ~/github/dotfiles-latest/neovim/neobean/init.lua
-- vim.opt.spell = false

vim.g.md_heading_bg = "transparent"
-- We're passing an env var from kitty, you can print it with:
-- :lua print(vim.env.NEOVIM_MODE)
-- Here we capture the environment variable to make it accessible to neovim
--
-- NOTE: To see all the files modified for skitty-notes just search for "neovim_mode"
vim.g.neovim_mode = vim.env.NEOVIM_MODE or "default"
-- vim.g.bullets_enable_in_empty_buffers = 0

-- -- I have 2 style options "solid" and "transparent"
-- -- This style is defined in my zshrc file
-- -- :lua print(vim.env.MD_HEADING_BG)
vim.g.md_heading_bg = vim.env.MD_HEADING_BG

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Keep LazyVim/Snacks searches scoped to the directory where nvim was opened.
-- LazyVim's default root spec prefers LSP/.git roots, which makes pickers like
-- find files and grep jump to the repository root even when starting in a
-- subdirectory.
vim.g.root_spec = { "cwd" }

-- Load custom highlights, I tried adding this as an autocommand, in the options.lua
-- file, also in the markdownl.lua file, but the highlights kept being overriden
-- so this is the only way I was able to make it work
-- Require the colors.lua module and access the colors directly without
-- additional file reads
require("config.highlights")

-- init.lua
require("luasnip.loaders.from_lua").load({
  paths = { vim.fn.stdpath("config") .. "/lua/snippets" },
})

-- Delay for `skitty` configuration
-- If I don't add this delay, I get the message
-- "Press ENTER or type command to continue"
if vim.g.neovim_mode == "skitty" then
  vim.wait(500, function()
    return false
  end) -- Wait for X miliseconds without doing anything
end

-- cosas de c++
vim.lsp.handlers["textDocument/inlayHint"] = function() end
require("config.dap_cpp")

-- prolog
require("config.prolog")
