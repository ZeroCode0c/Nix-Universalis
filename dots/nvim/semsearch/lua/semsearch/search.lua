local M = {}

local LANG_TOKENS =
  { go = "go", golang = "go", python = "python", py = "python", cpp = "cpp", ["c++"] = "cpp", haskell = "haskell" }

local WEIGHTS = {
  tags_op         = 25,
  tags_domain     = 20,
  tags_properties = 15,
  tags_intent     = 10,
  symbol          = 50,
  category        = 40,
  when_text       = 5,
}

-- Both arguments are already lowercase (stored in entry._lc at load time).
local function field_score_lc(t, v)
  if not v or v == "" then return 0 end
  if v == t then return 10 end
  if v:sub(1, #t) == t then return 7 end
  if v:find(t, 1, true) then return 5 end
  local pos = 1
  for ci = 1, #t do
    local c = t:sub(ci, ci)
    local found = v:find(c, pos, true)
    if not found then return 0 end
    pos = found + 1
  end
  return 2
end

local function score_list_lc(t, list)
  local best = 0
  for _, v in ipairs(list) do
    local s = field_score_lc(t, v)
    if s > best then best = s end
  end
  return best
end

local function score_entry(entry, tokens)
  local lc = entry._lc
  if not lc then return 0 end
  local total = 0
  for _, tok in ipairs(tokens) do
    local s = score_list_lc(tok, lc.tags_op)          * WEIGHTS.tags_op
            + score_list_lc(tok, lc.tags_domain)       * WEIGHTS.tags_domain
            + score_list_lc(tok, lc.tags_properties)   * WEIGHTS.tags_properties
            + score_list_lc(tok, lc.tags_intent)       * WEIGHTS.tags_intent
            + field_score_lc(tok, lc.symbol)            * WEIGHTS.symbol
            + score_list_lc(tok, lc.category)           * WEIGHTS.category
            + field_score_lc(tok, lc.when)              * WEIGHTS.when_text
            + field_score_lc(tok, lc.not_when)          * WEIGHTS.when_text
    total = total + s
  end
  return total
end

-- Cache stop_set — stop_words list is fixed after setup so we build it once.
local _stop_set = nil
local _stop_words_ref = nil

local function get_stop_set(stop_words)
  if stop_words == _stop_words_ref then return _stop_set end
  local set = {}
  for _, w in ipairs(stop_words or {}) do set[w] = true end
  _stop_set = set
  _stop_words_ref = stop_words
  return set
end

local function tokenize(query, stop_words)
  local tokens = {}
  local stop_set = get_stop_set(stop_words)
  for tok in query:lower():gmatch("%S+") do
    if not stop_set[tok] then
      table.insert(tokens, tok)
    end
  end
  return tokens
end

function M.query(query_str, opts)
  local loader = require("semsearch.loader")
  local cfg = opts or {}
  local stop_words = cfg.stop_words or {}
  local max_results = cfg.max_results

  local tokens = tokenize(query_str, stop_words)
  local lang_filter = nil

  local filtered_tokens = {}
  for _, tok in ipairs(tokens) do
    if LANG_TOKENS[tok] then
      lang_filter = LANG_TOKENS[tok]
    else
      table.insert(filtered_tokens, tok)
    end
  end
  tokens = filtered_tokens

  if #tokens == 0 then
    local all = loader.get_all()
    if lang_filter then
      local filtered = {}
      for _, e in ipairs(all) do
        if e.language == lang_filter then table.insert(filtered, e) end
      end
      all = filtered
    end
    local result = {}
    for i = 1, (max_results and math.min(#all, max_results) or #all) do
      table.insert(result, all[i])
    end
    return result
  end

  local scored = {}
  for _, entry in pairs(loader.index) do
    if not lang_filter or entry.language == lang_filter then
      local s = score_entry(entry, tokens)
      if s > 0 then
        table.insert(scored, { entry = entry, score = s })
      end
    end
  end

  table.sort(scored, function(a, b)
    if a.score ~= b.score then return a.score > b.score end
    return a.entry.id < b.entry.id
  end)

  local results = {}
  for i = 1, (max_results and math.min(#scored, max_results) or #scored) do
    table.insert(results, scored[i].entry)
  end
  return results
end

return M
