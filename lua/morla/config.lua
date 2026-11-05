-- Defaults, and the merged options every other module reads.
local M = {}

M.defaults = {
  -- The model call. stdin carries the request; morla appends
  -- `--system-prompt <text>`. `--setting-sources ""` keeps the user's
  -- CLAUDE.md, hooks and permission rules out of the call (ARCHITECTURE D2).
  cmd = {
    'claude', '-p',
    '--model', 'haiku',
    '--tools', '',
    '--setting-sources', '',
    '--strict-mcp-config',
    '--disable-slash-commands',
    '--no-session-persistence',
  },
  timeout = 60000, -- ms
  -- The key that translates the line under the cursor in `q:`, and on the
  -- `:` line (which hands the line to `q:` first). False turns it off.
  key = '<C-g>',
  history_file = vim.fn.stdpath('data') .. '/morla/history.jsonl',
  examples = 8, -- past translations sent with each request
  recent_commands = 20, -- lines of `:` history sent with each request
  selection_lines = 20, -- lines of the last visual selection sent
}

M.options = vim.deepcopy(M.defaults)

function M.set(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend('force', vim.deepcopy(M.defaults), opts)
  -- A list replaces the default whole; deep-extend would merge it by index.
  if opts.cmd then M.options.cmd = vim.deepcopy(opts.cmd) end
  return M.options
end

return M
