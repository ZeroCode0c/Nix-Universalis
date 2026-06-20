return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "blade", "haskell" })

      -- NixOS ships Neovim with parsers in {nix-profile}/lib/nvim/parser/.
      -- That directory is in Neovim's C-level parser search path but NOT in
      -- the Lua rtp, so nvim-treesitter.config.get_installed() (which only
      -- scans its own stdpath("data")/site/parser/) returns [] for them.
      -- LazyVim.treesitter.have("markdown") then returns false and the
      -- FileType autocmd exits before calling vim.treesitter.start() —
      -- meaning treesitter never activates, and fenced-block injections never run.
      --
      -- Fix: wrap get_installed so it also scans the Nix parser locations.
      -- This runs in opts (before config/TS.setup), so LazyVim.treesitter
      -- .get_installed(true) picks up the patched version at the right time.
      local ok, ts_config = pcall(require, "nvim-treesitter.config")
      if not ok then
        return
      end

      local orig = ts_config.get_installed
      ts_config.get_installed = function(type_filter)
        local result = orig(type_filter)
        if type_filter == "queries" then
          return result
        end

        local seen = {}
        for _, lang in ipairs(result) do
          seen[lang] = true
        end

        -- Directories to scan: rtp parser/ dirs + well-known Nix paths
        local dirs = vim.api.nvim_get_runtime_file("parser", true)
        for _, d in ipairs({
          vim.fn.expand("~/.nix-profile/lib/nvim/parser"),
          "/run/current-system/sw/lib/nvim/parser",
        }) do
          if vim.fn.isdirectory(d) == 1 then
            table.insert(dirs, d)
          end
        end

        for _, dir in ipairs(dirs) do
          if vim.fn.isdirectory(dir) == 1 then
            for fname in vim.fs.dir(dir) do
              local lang = fname:match("^(.+)%.so$")
              if lang and not seen[lang] then
                seen[lang] = true
                table.insert(result, lang)
              end
            end
          end
        end

        return result
      end
    end,
    init = function()
      vim.filetype.add({
        pattern = { [".*%.blade%.php"] = "blade" },
      })
    end,
  },
}
