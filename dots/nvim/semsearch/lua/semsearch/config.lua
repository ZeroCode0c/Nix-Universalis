local M = {}

M.defaults = {
  index_dir = vim.fn.stdpath("config") .. "/semsearch",
  max_results = 40,
  languages = nil,
  lsp_hover = true,
  keymap_prefix = "<leader>f",
  stop_words = {
    "en",
    "el",
    "la",
    "a",
    "de",
    "para",
    "que",
    "con",
    "los",
    "las",
    "in",
    "the",
    "an",
    "of",
    "for",
    "to",
    "with",
    "and",
    "or",
  },
}

function M.resolve(user_opts)
  return vim.tbl_deep_extend("force", M.defaults, user_opts or {})
end

return M
