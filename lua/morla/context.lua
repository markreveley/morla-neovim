-- What the model is told about the editor: the window the request came
-- from, its buffer, the last visual selection, the buffer list and recent
-- `:` history. gather() reads it; render() turns it into prompt text.
local config = require('morla.config')

local M = {}

local function relname(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then return '[No Name]' end
  return vim.fn.fnamemodify(name, ':~:.')
end

local function clip(s, n)
  if #s > n then return s:sub(1, n) .. '…' end
  return s
end

-- win: the window the request is about (not the `q:` window).
function M.gather(win)
  local opts = config.options
  win = (win and vim.api.nvim_win_is_valid(win)) and win or vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local ctx = {
    buf = buf, -- not sent; used to tell whether a run changed the buffer
    cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ':~'),
    file = relname(buf),
    filetype = vim.bo[buf].filetype,
    buftype = vim.bo[buf].buftype,
    modified = vim.bo[buf].modified,
    line = cursor[1],
    col = cursor[2] + 1,
    lines = vim.api.nvim_buf_line_count(buf),
    current = clip(vim.api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], false)[1] or '', 200),
    windows = #vim.api.nvim_tabpage_list_wins(0),
    tabs = #vim.api.nvim_list_tabpages(),
    nvim = tostring(vim.version()),
  }

  local total = ctx.lines
  local n = opts.buffer_lines
  if n > 0 then
    local first = 1
    if total > n then first = math.max(1, math.min(cursor[1] - math.floor(n / 2), total - n + 1)) end
    local last = math.min(total, first + n - 1)
    ctx.text = { from = first, to = last, lines = vim.api.nvim_buf_get_lines(buf, first - 1, last, false) }
  end

  local s = vim.api.nvim_buf_get_mark(buf, '<')
  local e = vim.api.nvim_buf_get_mark(buf, '>')
  if s[1] > 0 and e[1] >= s[1] then
    local last = math.min(e[1], s[1] + opts.selection_lines - 1)
    ctx.selection = {
      from = s[1],
      to = e[1],
      text = vim.api.nvim_buf_get_lines(buf, s[1] - 1, last, false),
    }
  end

  ctx.buffers = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted and #ctx.buffers < 30 then
      table.insert(ctx.buffers, relname(b))
    end
  end

  ctx.recent = {}
  local n = vim.fn.histnr(':')
  for i = n, math.max(1, n - opts.recent_commands + 1), -1 do
    local h = vim.fn.histget(':', i)
    if h ~= '' then table.insert(ctx.recent, 1, h) end
  end
  return ctx
end

function M.render(ctx)
  local out = {
    'Neovim ' .. ctx.nvim .. '. Working directory: ' .. ctx.cwd,
    string.format('Current file: %s (filetype %s%s%s), %d lines; cursor on line %d, column %d.',
      ctx.file, ctx.filetype ~= '' and ctx.filetype or 'none',
      ctx.buftype ~= '' and (', buftype ' .. ctx.buftype) or '',
      ctx.modified and ', unsaved changes' or '',
      ctx.lines, ctx.line, ctx.col),
    'Cursor line: ' .. ctx.current,
    string.format('%d window(s) in this tab, %d tab(s).', ctx.windows, ctx.tabs),
  }
  if ctx.text then
    table.insert(out, string.format('Buffer lines %d-%d of %d, each prefixed with its line number and a tab:',
      ctx.text.from, ctx.text.to, ctx.lines))
    for i, l in ipairs(ctx.text.lines) do
      table.insert(out, (ctx.text.from + i - 1) .. '\t' .. clip(l, 300))
    end
  end
  if ctx.selection then
    table.insert(out, string.format('Last visual selection: lines %d-%d (use the range \'<,\'> for it):',
      ctx.selection.from, ctx.selection.to))
    for _, l in ipairs(ctx.selection.text) do table.insert(out, '  | ' .. l) end
  end
  if #ctx.buffers > 0 then
    table.insert(out, 'Listed buffers: ' .. table.concat(ctx.buffers, ', '))
  end
  if #ctx.recent > 0 then
    table.insert(out, 'Recent Ex commands, oldest first:')
    for _, h in ipairs(ctx.recent) do table.insert(out, '  ' .. h) end
  end
  return table.concat(out, '\n')
end

return M
