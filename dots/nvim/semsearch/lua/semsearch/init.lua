local M = {}
local _cfg = nil

function M.setup(opts)
  _cfg = require('semsearch.config').resolve(opts)
  M._register_commands()
  if _cfg.keymap_prefix then
    M._register_keymaps(_cfg.keymap_prefix)
  end
  -- Defer index loading so it doesn't block Neovim startup.
  vim.schedule(function()
    require('semsearch.loader').load(_cfg)
  end)
end

function M._register_commands()
  vim.api.nvim_create_user_command('SemSearch', function(cmd_opts)
    local q = cmd_opts.args ~= '' and cmd_opts.args or nil
    require('semsearch.telescope').open(q, _cfg, vim.bo.filetype)
  end, { nargs = '?', desc = 'SemSearch: semantic symbol search' })

  vim.api.nvim_create_user_command('SemNew', function(_)
    local lang_map = { go = 'go', python = 'python', cpp = 'cpp', c = 'cpp' }
    local lang = lang_map[vim.bo.filetype] or 'go'
    local dir = _cfg.index_dir .. '/' .. lang
    vim.fn.mkdir(dir, 'p')
    local ts = os.time()
    local path = dir .. '/new_entry_' .. ts .. '.yaml'
    vim.fn.writefile({
      '- id: ' .. lang .. '_new_entry_' .. ts,
      '  language: ' .. lang,
      '  symbol: YourSymbol',
      '  import: ""',
      '  category: patrones',
      '  tags:',
      '    op: [map]',
      '    domain: [listas]',
      '    properties: [eager]',
      '    intent: [transformar]',
      '  when: >',
      '    When to use this.',
      '  not_when: >',
      '    When NOT to use this.',
      '  syntax: |',
      '    // syntax here',
      '  my_example: |',
      '    // example here',
      '  related: []',
      '  notes: ""',
    }, path)
    vim.cmd('edit ' .. vim.fn.fnameescape(path))
  end, { desc = 'SemSearch: scaffold new entry for current filetype' })

  vim.api.nvim_create_user_command('SemReload', function(_)
    require('semsearch.loader').load(_cfg)
  end, { desc = 'SemSearch: reload index from disk' })

  vim.api.nvim_create_user_command('SemEdit', function(cmd_opts)
    M.edit_entry(cmd_opts.args)
  end, { nargs = '?', desc = 'SemSearch: open YAML source for an entry id' })
end

function M.edit_entry(id)
  local loader = require('semsearch.loader')
  if id and id ~= '' then
    local entry = loader.index[id]
    if not entry then
      vim.notify('SemSearch: entry not found: ' .. id, vim.log.levels.WARN)
      return
    end
    local f = entry._source_file
    if not f then
      vim.notify('SemSearch: source file unknown for: ' .. id, vim.log.levels.WARN)
      return
    end
    vim.cmd('edit ' .. vim.fn.fnameescape(f))
    vim.fn.search('id: ' .. id)
  else
    vim.cmd('edit ' .. vim.fn.fnameescape(_cfg.index_dir))
  end
end

function M._register_keymaps(prefix)
  local opts = { noremap = true, silent = true }
  vim.keymap.set('n', prefix .. 's', function()
    require('semsearch.telescope').open(nil, _cfg, vim.bo.filetype)
  end, opts)
  vim.keymap.set('n', prefix .. 'n', '<cmd>SemNew<CR>', opts)
  vim.keymap.set('n', prefix .. 'e', function()
    local word = vim.fn.expand('<cword>')
    require('semsearch.telescope').open(word, _cfg, vim.bo.filetype)
  end, opts)
end

return M
