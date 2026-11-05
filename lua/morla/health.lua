-- :checkhealth morla
local M = {}

function M.check()
  local h = vim.health
  local config = require('morla.config')
  h.start('morla')
  if vim.fn.has('nvim-0.10') == 1 then
    h.ok('Neovim ' .. tostring(vim.version()))
  else
    h.error('Neovim 0.10 or later is needed (vim.system)')
  end
  local exe = config.options.cmd[1]
  if vim.fn.executable(exe) == 1 then
    h.ok(exe .. ' found: ' .. vim.fn.exepath(exe))
  else
    h.error(exe .. ' not found on PATH')
  end
  h.info('history file: ' .. config.options.history_file)
  h.info('key: ' .. tostring(config.options.key))
end

return M
