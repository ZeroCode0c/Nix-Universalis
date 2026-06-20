local M = {}

-- Index: { [id] = Entry, ... }
M.index = {}

-- Sorted list cache; invalidated on each load()
local _all_cache = nil

local yaml = require('semsearch.vendor.yaml')

local function parse_yaml_file(filepath)
  local lines = vim.fn.readfile(filepath)
  if not lines then return {} end
  local content = table.concat(lines, '\n')
  local ok, data = pcall(yaml.parse, content)
  if not ok then
    vim.notify('SemSearch: failed to parse ' .. filepath .. '\n' .. tostring(data), vim.log.levels.WARN)
    return {}
  end
  return data or {}
end

local function scan_yaml_files(dir)
  local files = {}
  local handle = vim.uv.fs_scandir(dir)
  if not handle then return files end
  while true do
    local name, kind = vim.uv.fs_scandir_next(handle)
    if not name then break end
    local path = dir .. '/' .. name
    if kind == 'directory' then
      for _, f in ipairs(scan_yaml_files(path)) do
        table.insert(files, f)
      end
    elseif kind == 'file' and name:match('%.ya?ml$') then
      table.insert(files, path)
    end
  end
  return files
end

function M.load(cfg)
  M.index = {}
  _all_cache = nil
  local dir = cfg.index_dir
  local stat = vim.uv.fs_stat(dir)
  if not stat or stat.type ~= 'directory' then
    vim.notify('SemSearch: index_dir not found: ' .. dir, vim.log.levels.WARN)
    return
  end

  local files = scan_yaml_files(dir)
  local count = 0

  for _, filepath in ipairs(files) do
    local entries = parse_yaml_file(filepath)
    for _, entry in ipairs(entries) do
      if type(entry) == 'table' and entry.id and entry.language then
        if not cfg.languages or vim.tbl_contains(cfg.languages, entry.language) then
          -- Normalize tags to always be tables
          entry.tags = entry.tags or {}
          for _, dim in ipairs({ 'op', 'domain', 'properties', 'intent' }) do
            if type(entry.tags[dim]) == 'string' then
              entry.tags[dim] = { entry.tags[dim] }
            end
            entry.tags[dim] = entry.tags[dim] or {}
          end
          -- Normalize category to always be a list (supports multi-category entries)
          if type(entry.category) == 'string' then
            entry.category = { entry.category }
          end
          entry.category = entry.category or {}
          -- Normalize list fields
          for _, field in ipairs({ 'alt', 'related' }) do
            if type(entry[field]) == 'string' then
              entry[field] = { entry[field] }
            end
            entry[field] = entry[field] or {}
          end
          entry._source_file = filepath
          -- Pre-lowercase all searchable fields once so search.lua never calls
          -- .lower() at query time (hot path on every keystroke).
          entry._lc = {
            symbol        = (entry.symbol or ""):lower(),
            when          = (entry.when or ""):lower(),
            not_when      = (entry.not_when or ""):lower(),
            tags_op       = vim.tbl_map(string.lower, entry.tags.op),
            tags_domain   = vim.tbl_map(string.lower, entry.tags.domain),
            tags_properties = vim.tbl_map(string.lower, entry.tags.properties),
            tags_intent   = vim.tbl_map(string.lower, entry.tags.intent),
            category      = vim.tbl_map(string.lower, entry.category),
          }
          M.index[entry.id] = entry
          count = count + 1
        end
      end
    end
  end

  vim.notify(string.format('SemSearch: loaded %d entries from %d files', count, #files), vim.log.levels.INFO)
end

function M.get_all()
  if _all_cache then return _all_cache end
  local list = {}
  for _, entry in pairs(M.index) do
    table.insert(list, entry)
  end
  table.sort(list, function(a, b) return a.id < b.id end)
  _all_cache = list
  return list
end

return M
