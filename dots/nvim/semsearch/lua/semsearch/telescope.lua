local M = {}

local FT_TO_LANG = { go = "go", python = "python", cpp = "cpp", c = "cpp", rust = "rust", haskell = "haskell" }

-- ── Colours ──────────────────────────────────────────────────────────────────

-- Canonical language colours (brand / GitHub-linguist, tuned for dark bg).
local _LANG_HL = {
  python = "SemSearchLangPython",
  rust = "SemSearchLangRust",
  go = "SemSearchLangGo",
  cpp = "SemSearchLangCpp",
  c = "SemSearchLangC",
  haskell = "SemSearchLangHaskell",
  lua = "SemSearchLangLua",
  javascript = "SemSearchLangJS",
  typescript = "SemSearchLangTS",
  ruby = "SemSearchLangRuby",
}

-- 8 soft colours for category hashing (Catppuccin-inspired).
local _CAT_PALETTE = {
  "SemSearchCat1",
  "SemSearchCat2",
  "SemSearchCat3",
  "SemSearchCat4",
  "SemSearchCat5",
  "SemSearchCat6",
  "SemSearchCat7",
  "SemSearchCat8",
}

local _hl_ready = false
local function _setup_hl()
  if _hl_ready then
    return
  end
  _hl_ready = true
  -- All colours taken directly from the active linkarzu/Eldritch palette so
  -- they feel native to the theme instead of imported from a foreign scheme.
  local set = function(name, fg)
    vim.api.nvim_set_hl(0, name, { fg = fg })
  end
  -- Languages — canonical associations within the palette
  set("SemSearchLangPython", "#f1fc79") -- linkarzu_color12  bright yellow
  set("SemSearchLangRust", "#e58f2a") -- linkarzu_color08  orange
  set("SemSearchLangGo", "#04d1f9") -- linkarzu_color03  cyan
  set("SemSearchLangCpp", "#f16c75") -- linkarzu_color11  coral/red
  set("SemSearchLangC", "#b7bfce") -- linkarzu_color09  steel-gray
  set("SemSearchLangHaskell", "#987afb") -- linkarzu_color04  purple
  set("SemSearchLangLua", "#fca6ff") -- linkarzu_color01  pink/magenta
  set("SemSearchLangJS", "#9ad900") -- linkarzu_color05  lime
  set("SemSearchLangTS", "#37f499") -- linkarzu_color02  emerald
  set("SemSearchLangRuby", "#f94dff") -- linkarzu_color24  hot-pink
  set("SemSearchLangDefault", "#b7bfce") -- linkarzu_color09  steel-gray
  -- Categories — 8 vibrant, distinct palette slots (no pastels)
  set("SemSearchCat1", "#987afb") -- purple
  set("SemSearchCat2", "#37f499") -- emerald
  set("SemSearchCat3", "#04d1f9") -- cyan
  set("SemSearchCat4", "#fca6ff") -- pink
  set("SemSearchCat5", "#9ad900") -- lime
  set("SemSearchCat6", "#e58f2a") -- orange
  set("SemSearchCat7", "#f1fc79") -- yellow
  set("SemSearchCat8", "#f16c75") -- coral
end

local function _cat_hl(cat)
  if not cat or cat == "" then
    return "SemSearchCat1"
  end
  local h = 0
  for i = 1, #cat do
    h = (h * 31 + string.byte(cat, i)) % 256
  end
  return _CAT_PALETTE[(h % #_CAT_PALETTE) + 1]
end

-- ── Treesitter ────────────────────────────────────────────────────────────────

-- Attach markdown treesitter with injection support on scratch/nofile buffers.
-- Injections are what make ```python blocks highlight as Python inside markdown.
-- Plain vim.treesitter.start() on a nofile buffer often leaves the parser in a
-- partial state (no child trees), especially when the buffer is reused across
-- previewer entries. Strategy:
--   1. Stop any stale highlighter so the reused preview buf starts clean.
--   2. Prefer nvim-treesitter's own attach() — it processes injections.scm
--      reliably regardless of buftype.
--   3. Fall back to the built-in, then force a full-buffer parse so injection
--      queries actually run and child language trees are created.
local function attach_md_treesitter(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  pcall(vim.treesitter.stop, buf)
  local ok_nts, nts_hl = pcall(require, "nvim-treesitter.highlight")
  if ok_nts and type(nts_hl.attach) == "function" then
    pcall(nts_hl.attach, buf, "markdown")
    return
  end
  local started = pcall(vim.treesitter.start, buf, "markdown")
  if started then
    local ok_p, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
    if ok_p and parser then
      -- parse(true) ensures all regions are parsed, including injection subtrees.
      parser:parse(true)
    end
  end
end

-- ── LSP hover cache ───────────────────────────────────────────────────────────

-- Persists across open() calls so navigating back to a symbol is instant.
-- nil = not requested, false = request in flight, string = result ('' = no doc).
local _hover_cache = {}

-- Base preview lines per entry id (LSP content is appended separately).
-- Pure function of entry data so safe to cache for the session.
local _preview_lines_cache = {}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function format_list(tbl)
  if not tbl or #tbl == 0 then
    return ""
  end
  return table.concat(tbl, ", ")
end

local _SEP = " · " -- U+00B7 middle dot: 2 UTF-8 bytes → #_SEP == 4, not 3

-- Flatten category list → display string ("regex/strings") and first element for colour.
local function _cat_text(cat)
  if type(cat) == "table" then
    return table.concat(cat, "/"), cat[1]
  end
  return cat or "", cat
end

-- Returns (display_string, highlight_list) for the Telescope results list.
local function entry_display(entry)
  _setup_hl()
  local sym_str = string.format("%-35s", entry.symbol or "")
  local cat_label, cat1 = _cat_text(entry.category)
  local cat_str = string.format("%-15s", cat_label)
  local lang = entry.language or ""
  local str = sym_str .. _SEP .. cat_str .. _SEP .. lang

  local cat_start = #sym_str + #_SEP
  local lang_start = cat_start + #cat_str + #_SEP
  return str,
    {
      { { cat_start, cat_start + #cat_label }, _cat_hl(cat1) },
      { { lang_start, lang_start + #lang }, _LANG_HL[lang] or "SemSearchLangDefault" },
    }
end

-- Wraps text in a fenced code block for the detail/preview buffer.
-- Fences have NO leading whitespace so treesitter markdown injection fires.
local function code_section(title, text, lang)
  if not text or text == "" then
    return {}
  end
  local lines = { "", "## " .. title, "", "```" .. (lang or "") }
  for _, l in ipairs(vim.split(text, "\n", { plain = true })) do
    table.insert(lines, l)
  end
  table.insert(lines, "```")
  return lines
end

local function prose_section(title, text)
  if not text or text == "" then
    return {}
  end
  local lines = { "", "## " .. title, "" }
  for _, l in ipairs(vim.split(text, "\n", { plain = true })) do
    table.insert(lines, l)
  end
  return lines
end

local function build_preview_lines(entry)
  local lang = entry.language or ""
  local lines = {}

  local function tag_line()
    local parts = {}
    for _, dim in ipairs({ "op", "domain", "properties", "intent" }) do
      local vals = entry.tags and entry.tags[dim] or {}
      if #vals > 0 then
        table.insert(parts, "**" .. dim .. "**: " .. format_list(vals))
      end
    end
    return table.concat(parts, " · ")
  end

  -- Header
  table.insert(lines, "# " .. entry.symbol)
  table.insert(lines, "_" .. _cat_text(entry.category) .. " · " .. lang .. "_")
  if entry.import then
    table.insert(lines, "`import " .. entry.import .. "`")
  end
  table.insert(lines, "")
  table.insert(lines, tag_line())
  table.insert(lines, "")
  table.insert(lines, "---")

  for _, l in ipairs(prose_section("WHEN", entry.when)) do
    table.insert(lines, l)
  end
  if entry.not_when and entry.not_when ~= "" then
    for _, l in ipairs(prose_section("NOT WHEN", entry.not_when)) do
      table.insert(lines, l)
    end
  end
  for _, l in ipairs(code_section("SYNTAX", entry.syntax, lang)) do
    table.insert(lines, l)
  end
  if entry.my_example and entry.my_example ~= "" then
    for _, l in ipairs(code_section("MY EXAMPLE", entry.my_example, lang)) do
      table.insert(lines, l)
    end
  end
  if entry.related and #entry.related > 0 then
    table.insert(lines, "")
    table.insert(lines, "**related:** " .. format_list(entry.related))
  end
  if entry.notes and entry.notes ~= "" then
    for _, l in ipairs(prose_section("NOTES", entry.notes)) do
      table.insert(lines, l)
    end
  end
  -- Keybindings footer (always visible at the bottom)
  table.insert(lines, "")
  table.insert(lines, "---")
  table.insert(lines, "`<C-s>` insertar símbolo  ·  `<C-y>` insertar syntax  ·  `q` volver  ·  `<Esc>` cerrar")
  return lines
end

-- Returns a shallow copy of cached base preview lines so callers can append
-- LSP content without corrupting the cache.
local function get_preview_lines(entry)
  local cached = _preview_lines_cache[entry.id]
  if not cached then
    cached = build_preview_lines(entry)
    _preview_lines_cache[entry.id] = cached
  end
  local copy = {}
  for i = 1, #cached do copy[i] = cached[i] end
  return copy
end

-- Appends LSP documentation lines to a buffer and re-attaches treesitter.
local function append_lsp_lines(buf, doc)
  if not doc or doc == "" then
    return
  end
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local doc_lines = { "", "---", "", "## LSP DOCUMENTATION", "" }
  -- Insert raw LSP markdown directly so fenced code blocks keep their
  -- language tag (```python, ```go, etc.) for treesitter injection.
  -- stylize_markdown strips the fence markers and applies highlights only
  -- to a temp buf we discard, losing all language info.
  for _, l in ipairs(vim.split(doc, "\n", { plain = true })) do
    table.insert(doc_lines, l)
  end
  local cur = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for _, l in ipairs(doc_lines) do
    table.insert(cur, l)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, cur)
  -- Re-attach after appending so new fenced blocks get injection highlights.
  attach_md_treesitter(buf)
end

-- ── Main ──────────────────────────────────────────────────────────────────────

function M.open(query_str, cfg, filetype)
  local ok_telescope, _ = pcall(require, "telescope")
  if not ok_telescope then
    vim.notify("SemSearch: telescope.nvim is required", vim.log.levels.ERROR)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")
  local sorters = require("telescope.sorters")
  local search = require("semsearch.search")
  local lsp_bridge = require("semsearch.lsp_bridge")

  -- Determine default language token from filetype
  local lang_from_ft = filetype and FT_TO_LANG[filetype]
  local default_text
  if query_str and query_str ~= "" then
    -- If query doesn't already contain a language token, prepend detected one
    local has_lang = query_str:match("%f[%a]go%f[%A]")
      or query_str:match("%f[%a]python%f[%A]")
      or query_str:match("%f[%a]cpp%f[%A]")
      or query_str:match("%f[%a]py%f[%A]")
    default_text = (lang_from_ft and not has_lang) and (lang_from_ft .. " " .. query_str) or query_str
  else
    default_text = lang_from_ft and (lang_from_ft .. " ") or ""
  end

  local function get_results(input)
    return search.query(input or "", {
      stop_words  = cfg.stop_words,
      max_results = cfg.max_results,
    })
  end

  local previewer = previewers.new_buffer_previewer({
    title = "SemSearch",
    define_preview = function(self, entry_item)
      local bufnr = self.state.bufnr
      local entry = entry_item.value
      local key = (entry.language or "") .. ":" .. (entry.symbol or "")

      -- Bump generation so any in-flight async callback for the previous entry
      -- knows not to write to this buffer once we've moved on.
      self.state.gen = (self.state.gen or 0) + 1
      local gen = self.state.gen

      -- Stop the old parser BEFORE writing new lines; the previewer reuses the
      -- same bufnr across entries so a leftover LanguageTree causes injection
      -- queries to silently skip on the next call.
      pcall(vim.treesitter.stop, bufnr)
      local lines = get_preview_lines(entry)

      -- Append cached LSP now (synchronous) so treesitter sees all content
      -- in one shot; async path appends and re-attaches separately below.
      if type(_hover_cache[key]) == "string" and _hover_cache[key] ~= "" then
        local doc_lines = { "", "---", "", "## LSP DOCUMENTATION", "" }
        for _, l in ipairs(vim.split(_hover_cache[key], "\n", { plain = true })) do
          table.insert(doc_lines, l)
        end
        for _, l in ipairs(doc_lines) do
          table.insert(lines, l)
        end
      end

      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.bo[bufnr].filetype = "markdown"
      -- Schedule so the previewer window is fully initialised before we attach;
      -- treesitter injection needs a live window to resolve column widths.
      vim.schedule(function()
        attach_md_treesitter(bufnr)
      end)

      -- Request hover if not yet cached
      if cfg.lsp_hover and _hover_cache[key] == nil then
        _hover_cache[key] = false -- mark in-flight
        lsp_bridge.hover(entry, function(doc)
          _hover_cache[key] = doc or ""
          if not doc or doc == "" then
            return
          end
          vim.schedule(function()
            if self.state.gen ~= gen then
              return
            end -- user navigated away
            if not vim.api.nvim_buf_is_valid(bufnr) then
              return
            end
            append_lsp_lines(bufnr, doc)
          end)
        end)
      end
    end,
  })

  local function open_detail(entry, prev_buf, return_query)
    local lines = get_preview_lines(entry)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].modifiable = false

    local width = math.floor(vim.o.columns * 0.72)
    local height = math.floor(vim.o.lines * 0.72)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      style = "minimal",
      border = "rounded",
      width = width,
      height = height,
      row = row,
      col = col,
    })
    -- Attach after open_win so the window context is available for injection parsing.
    attach_md_treesitter(buf)
    vim.wo[win].wrap = true
    vim.wo[win].conceallevel = 2 -- let markdown conceal syntax chars

    local function close()
      vim.api.nvim_win_close(win, true)
    end
    -- q: volver al picker con la misma query
    vim.keymap.set("n", "q", function()
      close()
      vim.schedule(function()
        M.open(return_query, cfg, filetype)
      end)
    end, { buffer = buf, nowait = true })
    -- <Esc>: cerrar todo
    vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })

    -- <C-s>: insert symbol name at cursor position (inline)
    vim.keymap.set("n", "<C-s>", function()
      close()
      if prev_buf and vim.api.nvim_buf_is_valid(prev_buf) then
        local cur_win = vim.fn.bufwinid(prev_buf)
        if cur_win ~= -1 then
          local cursor = vim.api.nvim_win_get_cursor(cur_win)
          local row = cursor[1] - 1
          local col = cursor[2]
          local line = vim.api.nvim_buf_get_lines(prev_buf, row, row + 1, false)[1] or ""
          local new_line = line:sub(1, col) .. entry.symbol .. line:sub(col + 1)
          vim.api.nvim_buf_set_lines(prev_buf, row, row + 1, false, { new_line })
          vim.api.nvim_win_set_cursor(cur_win, { cursor[1], col + #entry.symbol })
        end
      end
    end, { buffer = buf })

    -- <C-y>: insert full syntax snippet as new lines below cursor
    vim.keymap.set("n", "<C-y>", function()
      if not entry.syntax then
        return
      end
      close()
      local syntax_lines = vim.split(entry.syntax, "\n", { plain = true })
      if prev_buf and vim.api.nvim_buf_is_valid(prev_buf) then
        local cur_win = vim.fn.bufwinid(prev_buf)
        if cur_win ~= -1 then
          local cursor = vim.api.nvim_win_get_cursor(cur_win)
          vim.api.nvim_buf_set_lines(prev_buf, cursor[1], cursor[1], false, syntax_lines)
        end
      end
    end, { buffer = buf })

    -- Async LSP hover appended at the bottom
    if cfg.lsp_hover then
      local key = (entry.language or "") .. ":" .. (entry.symbol or "")

      local function do_lsp(doc)
        if not doc or doc == "" then
          return
        end
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(buf) then
            return
          end
          vim.bo[buf].modifiable = true
          append_lsp_lines(buf, doc)
          vim.bo[buf].modifiable = false
        end)
      end

      -- Use cached result immediately if available, otherwise request
      if type(_hover_cache[key]) == "string" and _hover_cache[key] ~= "" then
        do_lsp(_hover_cache[key])
      else
        lsp_bridge.hover(entry, function(doc)
          _hover_cache[key] = doc or ""
          do_lsp(doc)
        end)
      end
    end
  end

  local prev_buf = vim.api.nvim_get_current_buf()

  pickers
    .new({}, {
      prompt_title = "SemSearch  │  <CR> detalle  <C-s> símbolo  <C-y> syntax  <C-e> editar",
      default_text = default_text,
      finder = finders.new_dynamic({
        fn = function(prompt)
          return get_results(prompt or "")
        end,
        entry_maker = function(entry)
          return {
            value = entry,
            display = function(e)
              return entry_display(e.value)
            end,
            -- Include language so Telescope's own sorter (when used) can match it;
            -- with empty sorter this is just metadata.
            ordinal = entry.language .. " " .. entry.id .. " " .. entry.symbol .. " " .. _cat_text(entry.category),
          }
        end,
      }),
      -- Our fn already scores and sorts; bypass Telescope's sorter entirely.
      sorter = sorters.empty(),
      previewer = previewer,
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local sel = action_state.get_selected_entry()
          local current_query = action_state.get_current_line()
          actions.close(prompt_bufnr)
          if sel then
            open_detail(sel.value, prev_buf, current_query)
          end
        end)
        map("i", "<C-e>", function()
          local sel = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if sel then
            require("semsearch").edit_entry(sel.value.id)
          end
        end)
        -- <C-s>: insert symbol name at cursor position (inline)
        map("i", "<C-s>", function()
          local sel = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if sel and prev_buf and vim.api.nvim_buf_is_valid(prev_buf) then
            local cur_win = vim.fn.bufwinid(prev_buf)
            if cur_win ~= -1 then
              local cursor = vim.api.nvim_win_get_cursor(cur_win)
              local row = cursor[1] - 1
              local col = cursor[2]
              local line = vim.api.nvim_buf_get_lines(prev_buf, row, row + 1, false)[1] or ""
              local new_line = line:sub(1, col) .. sel.value.symbol .. line:sub(col + 1)
              vim.api.nvim_buf_set_lines(prev_buf, row, row + 1, false, { new_line })
              vim.api.nvim_win_set_cursor(cur_win, { cursor[1], col + #sel.value.symbol })
            end
          end
        end)
        -- <C-y>: insert full syntax snippet as new lines below cursor
        map("i", "<C-y>", function()
          local sel = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if sel and sel.value.syntax then
            local syntax_lines = vim.split(sel.value.syntax, "\n", { plain = true })
            local cur_win = vim.fn.bufwinid(prev_buf)
            if cur_win ~= -1 then
              local cursor = vim.api.nvim_win_get_cursor(cur_win)
              vim.api.nvim_buf_set_lines(prev_buf, cursor[1], cursor[1], false, syntax_lines)
            end
          end
        end)
        return true
      end,
    })
    :find()
end

return M
