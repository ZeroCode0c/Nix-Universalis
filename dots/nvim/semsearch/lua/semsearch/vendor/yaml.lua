-- Minimal YAML parser for SemSearch's specific schema.
-- Handles: top-level sequences of mappings, nested mappings (tags),
-- block scalars (| literal, > folded), flow sequences ([a, b, c]),
-- block sequences (indented "- item" lines).
local M = {}

local function trim(s) return s:match('^%s*(.-)%s*$') end

local function indent_of(line)
  return #(line:match('^( *)') or '')
end

local function parse_flow_seq(s)
  local inner = trim(s):match('^%[(.*)%]$')
  if not inner then return nil end
  local result = {}
  for item in (inner .. ','):gmatch('([^,]*),') do
    local t = trim(item)
    t = t:match('^"(.*)"$') or t:match("^'(.*)'$") or t
    if t ~= '' then table.insert(result, t) end
  end
  return result
end

local function unquote(s)
  return s:match('^"(.*)"$') or s:match("^'(.*)'$") or s
end

local function finish_block(lines, mode)
  while #lines > 0 and lines[#lines] == '' do table.remove(lines) end
  if mode == 'folded' then
    local paras, cur = {}, {}
    for _, l in ipairs(lines) do
      if l == '' then
        if #cur > 0 then table.insert(paras, table.concat(cur, ' ')); cur = {} end
        table.insert(paras, '')
      else
        table.insert(cur, l)
      end
    end
    if #cur > 0 then table.insert(paras, table.concat(cur, ' ')) end
    while #paras > 0 and paras[#paras] == '' do table.remove(paras) end
    return table.concat(paras, '\n')
  else
    return table.concat(lines, '\n')
  end
end

function M.parse(content)
  local entries = {}
  local entry = nil

  local bs_field, bs_indent, bs_mode, bs_lines, bs_tgt = nil, nil, nil, nil, nil
  local bseq_field, bseq_indent = nil, nil
  local in_tags, tags_indent = false, nil

  local function flush_bs()
    if not bs_field then return end
    bs_tgt[bs_field] = finish_block(bs_lines, bs_mode)
    bs_field = nil
  end

  local function commit()
    if not entry or not next(entry) then return end
    entry.tags = entry.tags or {}
    for _, d in ipairs({ 'op', 'domain', 'properties', 'intent' }) do
      local v = entry.tags[d]
      if type(v) == 'string' then entry.tags[d] = { v }
      elseif not v then entry.tags[d] = {} end
    end
    for _, f in ipairs({ 'alt', 'related' }) do
      local v = entry[f]
      if type(v) == 'string' then entry[f] = { v }
      elseif not v then entry[f] = {} end
    end
    table.insert(entries, entry)
  end

  local function set_kv(tbl, key, val, line_ind)
    val = trim(val)
    if val == '|' or val == '>' then
      flush_bs()
      bs_field = key; bs_indent = line_ind + 2
      bs_mode = val == '|' and 'literal' or 'folded'
      bs_lines = {}; bs_tgt = tbl
      bseq_field = nil
    elseif val:match('^%[') then
      tbl[key] = parse_flow_seq(val) or {}; bseq_field = nil
    elseif val == '' then
      tbl[key] = {}; bseq_field = key; bseq_indent = line_ind + 2
    else
      tbl[key] = unquote(val); bseq_field = nil
    end
  end

  local ls = {}
  for l in (content .. '\n'):gmatch('(.-)\n') do table.insert(ls, l) end

  local i = 1
  while i <= #ls do
    local line = ls[i]
    local ind = indent_of(line)
    local s = trim(line)

    if bs_field then
      if s == '' then
        table.insert(bs_lines, ''); i = i + 1
      elseif ind >= bs_indent then
        table.insert(bs_lines, line:sub(bs_indent + 1)); i = i + 1
      else
        flush_bs()  -- don't advance; reprocess line
      end

    elseif bseq_field then
      if s == '' then
        i = i + 1
      elseif ind >= bseq_indent and s:match('^%- ') then
        local item = unquote(trim(s:sub(3)))
        if type(entry[bseq_field]) ~= 'table' then entry[bseq_field] = {} end
        table.insert(entry[bseq_field], item); i = i + 1
      else
        bseq_field = nil  -- reprocess
      end

    elseif s == '' or s:match('^#') then
      i = i + 1

    elseif ind == 0 and s:match('^%- ?') then
      flush_bs(); commit()
      entry = {}; in_tags = false; tags_indent = nil; bseq_field = nil
      if s ~= '-' then
        local rest = s:sub(3)
        local k, v = rest:match('^([%w_]+):%s*(.*)')
        if k then set_kv(entry, k, v, 0) end
      end
      i = i + 1

    elseif entry and s:match('^[%w_]+:') then
      local k, v = s:match('^([%w_]+):%s*(.*)')
      if not k then i = i + 1
      elseif k == 'tags' then
        in_tags = true; tags_indent = ind
        entry.tags = entry.tags or {}
        bseq_field = nil; i = i + 1
      elseif in_tags and tags_indent and ind > tags_indent then
        if v:match('^%[') then
          entry.tags[k] = parse_flow_seq(v) or {}
        elseif v == '' then
          entry.tags[k] = {}
        else
          entry.tags[k] = { unquote(trim(v)) }
        end
        i = i + 1
      else
        if ind <= (tags_indent or -1) then in_tags = false end
        set_kv(entry, k, v, ind); i = i + 1
      end

    else
      i = i + 1
    end
  end

  flush_bs(); commit()
  return entries
end

return M
