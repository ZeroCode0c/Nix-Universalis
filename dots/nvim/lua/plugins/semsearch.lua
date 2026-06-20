local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")

return {
  {
    dir = config_dir .. "/semsearch",
    name = "semsearch",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("semsearch").setup({
        index_dir = config_dir .. "/semsearch/semsearch",
        max_results = 500,
        lsp_hover = true,
        keymap_prefix = "<leader>k",
      })
    end,
  },
}
