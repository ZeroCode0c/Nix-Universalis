local M = {}

local LANG_FT = { go = 'go', python = 'python', cpp = 'cpp' }

-- Extract readable text from an LSP hover result.
local function extract_text(result)
  if not result then return nil end
  local c = result.contents
  if type(c) == 'string' then return c ~= '' and c or nil end
  if type(c) == 'table' then
    local val = c.value or (c[1] and c[1].value)
    return (val and val ~= '') and val or nil
  end
  return nil
end

-- Find a loaded buffer of the right filetype that has LSP clients attached.
local function find_live_buf(ft)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == ft then
      local clients = vim.lsp.get_clients({ bufnr = buf })
      if #clients > 0 then
        return buf, clients[1]
      end
    end
  end
  return nil, nil
end

-- Hover via workspace/symbol → textDocument/hover.
-- This works with any LSP server that supports workspaceSymbolProvider.
local function hover_via_workspace(client, live_buf, sym_query, callback)
  client.request('workspace/symbol', { query = sym_query }, function(err, symbols)
    if err or not symbols or #symbols == 0 then
      callback(nil); return
    end
    -- Pick the symbol whose name most closely matches
    local best = nil
    local best_len = math.huge
    for _, sym in ipairs(symbols) do
      local n = sym.name or ''
      if n == sym_query then
        best = sym; break
      end
      if n:find(sym_query, 1, true) and #n < best_len then
        best = sym; best_len = #n
      end
    end
    if not best then best = symbols[1] end

    local loc = best.location or (best.locationLink and {
      uri   = best.locationLink.targetUri,
      range = best.locationLink.targetSelectionRange,
    })
    if not loc then callback(nil); return end

    client.request('textDocument/hover', {
      textDocument = { uri = loc.uri },
      position     = loc.range.start,
    }, function(e2, result)
      callback(e2 and nil or extract_text(result))
    end, live_buf)
  end, live_buf)
end

-- Write a minimal source snippet to a temp file, open it in a hidden buf,
-- wait for the LSP to attach, then request hover.
-- Used as fallback when workspace/symbol is not supported.
local SNIPPETS = {
  go = function(e)
    local imp = e.import and ('import "' .. e.import .. '"\n') or ''
    local sym = e.symbol:match('([^.]+)$') or e.symbol
    return imp .. 'package main\nfunc _() { var _ ' .. sym .. '\n_ = ' .. e.symbol .. ' }\n', 3
  end,
  python = function(e)
    local mod = e.import
    local head = mod and ('import ' .. mod .. '\n') or ''
    return head .. '_ = ' .. e.symbol .. '\n', mod and 2 or 1
  end,
  cpp = function(e)
    local inc = e.import and ('#include ' .. e.import .. '\n') or ''
    local sym = e.symbol:match('([^:]+)$') or e.symbol
    return inc .. 'auto _f() { return ' .. sym .. '; }\n', e.import and 2 or 1
  end,
}

local EXT = { go = '.go', python = '.py', cpp = '.cpp' }

local function hover_via_tempfile(entry, ft, callback)
  local snippet_fn = SNIPPETS[entry.language]
  if not snippet_fn then callback(nil); return end

  local content, sym_line = snippet_fn(entry)
  local ext = EXT[entry.language] or ('.' .. ft)
  local tmppath = vim.fn.tempname() .. ext
  vim.fn.writefile(vim.split(content, '\n', { plain = true }), tmppath)

  local buf = vim.fn.bufadd(tmppath)
  vim.fn.bufload(buf)
  vim.bo[buf].filetype = ft

  -- Wait up to 3 s for LSP to attach, then request hover
  local waited = 0
  local function try_hover()
    local clients = vim.lsp.get_clients({ bufnr = buf })
    if #clients == 0 then
      waited = waited + 1
      if waited > 30 then  -- 3 s timeout
        vim.api.nvim_buf_delete(buf, { force = true })
        vim.fn.delete(tmppath)
        callback(nil)
        return
      end
      vim.defer_fn(try_hover, 100)
      return
    end
    local client = clients[1]
    local lines  = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local line   = math.min(sym_line - 1, #lines - 1)
    local col    = (lines[line + 1] or ''):find(entry.symbol:match('([^.]+)$') or entry.symbol, 1, true) or 1
    client.request('textDocument/hover', {
      textDocument = { uri = vim.uri_from_bufnr(buf) },
      position     = { line = line, character = col - 1 },
    }, function(err, result)
      vim.schedule(function()
        vim.api.nvim_buf_delete(buf, { force = true })
        vim.fn.delete(tmppath)
        callback(err and nil or extract_text(result))
      end)
    end, buf)
  end
  vim.defer_fn(try_hover, 200)
end

function M.hover(entry, callback)
  if not entry or not entry.symbol then callback(nil); return end
  local ft = LANG_FT[entry.language]
  if not ft then callback(nil); return end

  local live_buf, client = find_live_buf(ft)

  if client and client.server_capabilities.workspaceSymbolProvider then
    local sym_query = entry.symbol:match('([^.%s]+)$') or entry.symbol
    hover_via_workspace(client, live_buf, sym_query, function(doc)
      if doc then callback(doc)
      else hover_via_tempfile(entry, ft, callback) end
    end)
  elseif live_buf then
    hover_via_tempfile(entry, ft, callback)
  else
    -- No live buffer of this type: try tempfile and hope LSP auto-attaches
    hover_via_tempfile(entry, ft, callback)
  end
end

return M
