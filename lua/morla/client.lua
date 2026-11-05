-- One model call: `claude -p`, request on stdin, reply on stdout. Runs in a
-- folder of its own so no project's CLAUDE.md is read (ARCHITECTURE D2).
local config = require('morla.config')
local prompt = require('morla.prompt')

local M = {}

local function workdir()
  local dir = vim.fn.stdpath('cache') .. '/morla'
  vim.fn.mkdir(dir, 'p')
  return dir
end

-- cb(command | nil, error | nil), called on the main loop.
function M.translate(req, cb)
  local opts = config.options
  local argv = vim.list_extend(vim.deepcopy(opts.cmd), { '--system-prompt', prompt.system })
  local ok, err = pcall(vim.system, argv, {
    stdin = prompt.build(req),
    text = true,
    cwd = workdir(),
    timeout = opts.timeout,
  }, vim.schedule_wrap(function(res)
    if res.code ~= 0 then
      local msg = vim.trim(res.stderr or '')
      if res.signal == 15 or res.code == 124 then msg = 'timed out' end
      return cb(nil, msg ~= '' and msg or ('exit ' .. res.code))
    end
    local cmd = prompt.parse(res.stdout)
    if not cmd then return cb(nil, 'empty reply') end
    cb(cmd)
  end))
  if not ok then cb(nil, tostring(err)) end
end

return M
