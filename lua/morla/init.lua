-- morla: plain English in, an Ex command out, in place, for review.
-- How the parts fit: md/governance/ARCHITECTURE.md.
local config = require('morla.config')
local context = require('morla.context')
local history = require('morla.history')
local risk = require('morla.risk')
local client = require('morla.client')

local M = {}

local ns = vim.api.nvim_create_namespace('morla')

local state = {
  setup = false,
  origin_win = nil, -- the window `q:` was opened from
  translate_on_enter = false, -- set by the `:` line key, read by CmdwinEnter
  pending = nil, -- the last translation, until it runs or is dropped
  last = nil, -- the last translation that ran this session: { id, instruction, command, ok, error, changed }
  hist = 0, -- `:` history number before the pending command could run
  tick = nil, -- changedtick of the origin buffer at the same moment
}
M._state = state

M.fix_text = 'That failed. Fix it.'

local function notify(msg, level)
  vim.notify('morla: ' .. msg, level or vim.log.levels.INFO)
end

local function where(ctx)
  return { cwd = ctx.cwd, filetype = ctx.filetype }
end

-- The request for one line. The line of the command that just failed asks
-- for a fix; every request carries the last run, so the model can tell a
-- complaint about it from a new instruction (feedback-and-explain D2).
local function request(text, win)
  local ctx = context.gather(win)
  local last = state.last
  if last and not last.ok and text == last.command then text = M.fix_text end
  return {
    instruction = text,
    context = context.render(ctx),
    examples = history.examples(where(ctx), config.options.examples),
    last = last and {
      instruction = last.instruction, command = last.command, ok = last.ok, error = last.error, changed = last.changed,
    },
  }, ctx
end

-- What the reply means for the history: a complaint marks the last run
-- wrong and the retry answers the original instruction (feedback-and-explain D3).
local function accept(req, reply, ctx)
  local p = {
    instruction = req.instruction, generated = reply.command, explain = reply.explain, where = where(ctx),
    origin_buf = ctx.buf,
  }
  local last = state.last
  if reply.feedback and last then
    if last.ok then history.mark_wrong(last.id, req.instruction) end
    p.instruction = last.instruction
    p.retry_of = last.id
  end
  return p
end

-- The text beside a translated line: flags, then the explanation.
function M.label(cmd, explain)
  local flags = risk.check(cmd)
  local parts = {}
  if #flags > 0 then table.insert(parts, '⚠ ' .. table.concat(flags, ', ')) end
  if explain then table.insert(parts, explain) end
  if #parts == 0 then parts = { 'morla' } end
  return table.concat(parts, ' · '), #flags > 0 and 'WarningMsg' or 'Comment'
end

local function mark(buf, row, text, hl)
  return vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
    virt_text = { { '  ' .. text, hl } },
    virt_text_pos = 'eol',
  })
end

-- Translate the line under the cursor in the `q:` window, in place.
function M.translate_cmdwin()
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local text = vim.trim(vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or '')
  if text == '' then return notify('type an instruction first', vim.log.levels.WARN) end

  local req, ctx = request(text, state.origin_win)
  vim.api.nvim_buf_clear_namespace(buf, ns, row, row + 1)
  local id = mark(buf, row, req.instruction == M.fix_text and 'morla: fixing…' or 'morla: translating…', 'Comment')

  client.translate(req, function(reply, err)
    if not vim.api.nvim_buf_is_valid(buf) then return end -- `q:` was closed
    local pos = vim.api.nvim_buf_get_extmark_by_id(buf, ns, id, {})
    if not pos[1] then return end
    vim.api.nvim_buf_del_extmark(buf, ns, id)
    if err then
      mark(buf, pos[1], 'morla: ' .. err:gsub('\n.*', ''), 'ErrorMsg')
      return
    end
    local cmd = reply.command
    vim.api.nvim_buf_set_lines(buf, pos[1], pos[1] + 1, false, { cmd })
    local new = mark(buf, pos[1], M.label(cmd, reply.explain))
    state.pending = accept(req, reply, ctx)
    state.pending.buf, state.pending.mark = buf, new
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_buf(win) == buf and vim.api.nvim_win_get_cursor(win)[1] == pos[1] + 1 then
      vim.api.nvim_win_set_cursor(win, { pos[1] + 1, #cmd })
    end
  end)
end

-- `:Morla <instruction>`: translate, then put the command on the `:` line.
function M.translate_to_cmdline(text)
  local req, ctx = request(vim.trim(text), vim.api.nvim_get_current_win())
  notify(req.instruction == M.fix_text and 'fixing…' or 'translating…')
  client.translate(req, function(reply, err)
    if err then return notify(err, vim.log.levels.ERROR) end
    local label, hl = M.label(reply.command, reply.explain)
    notify(label, hl == 'WarningMsg' and vim.log.levels.WARN or vim.log.levels.INFO)
    state.pending = accept(req, reply, ctx)
    vim.api.nvim_feedkeys(':' .. reply.command, 'n', false)
  end)
end

-- Record the pending translation once it has run. Called after `q:` closes
-- and after the `:` line is left; the `:` history says whether, and what, ran.
local function check()
  local p = state.pending
  if not p then return end
  local n = vim.fn.histnr(':')
  if n <= state.hist then
    -- Nothing ran. Back on the `:` line (<C-c> in `q:`), keep waiting.
    if vim.fn.mode() ~= 'c' then state.pending = nil end
    return
  end
  state.pending = nil
  local ran = vim.fn.histget(':', -1)
  if ran ~= p.generated and ran ~= p.final then return end
  local err = vim.v.errmsg
  local b = p.origin_buf
  local changed = nil
  if b and state.tick and vim.api.nvim_buf_is_valid(b) then
    changed = vim.api.nvim_buf_get_changedtick(b) ~= state.tick
  end
  local rec = {
    id = history.new_id(),
    ts = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    cwd = p.where.cwd,
    filetype = p.where.filetype,
    instruction = p.instruction,
    generated = p.generated,
    command = ran,
    explain = p.explain,
    retry_of = p.retry_of,
    ok = err == '',
    error = err ~= '' and err or nil,
    changed = changed,
  }
  history.append(rec)
  state.last = {
    id = rec.id, instruction = rec.instruction, command = ran, ok = rec.ok, error = rec.error, changed = changed,
  }
  if not rec.ok then
    local key = config.options.key
    notify('that command failed.'
      .. (key and (' In q:, press ' .. key .. ' on it, or type what went wrong.') or ''),
      vim.log.levels.WARN)
  end
end

local function arm()
  if not state.pending then return end
  state.hist = vim.fn.histnr(':')
  local b = state.pending.origin_buf
  state.tick = (b and vim.api.nvim_buf_is_valid(b)) and vim.api.nvim_buf_get_changedtick(b) or nil
  vim.v.errmsg = ''
  vim.schedule(check)
end

function M.pick_history()
  local ctx = context.gather()
  local recs = history.rank(history.load(), where(ctx))
  if #recs == 0 then return notify('no history yet') end
  vim.ui.select(recs, {
    prompt = 'morla history',
    format_item = function(r)
      return (r.ok and '' or '✗ ') .. r.instruction .. '  →  ' .. r.command
        .. (r.explain and ('  (' .. r.explain .. ')') or '')
    end,
  }, function(r)
    if r then vim.api.nvim_feedkeys(':' .. r.command, 'n', false) end
  end)
end

function M.setup(opts)
  config.set(opts)
  state.setup = true
  local key = config.options.key
  local group = vim.api.nvim_create_augroup('morla', { clear = true })

  vim.api.nvim_create_autocmd('CmdwinEnter', {
    group = group,
    pattern = ':',
    callback = function(ev)
      local prev = vim.fn.win_getid(vim.fn.winnr('#'))
      state.origin_win = prev ~= 0 and prev or nil
      if key then
        vim.keymap.set({ 'n', 'i' }, key, M.translate_cmdwin,
          { buffer = ev.buf, desc = 'morla: translate this line' })
      end
      if state.translate_on_enter then
        state.translate_on_enter = false
        vim.schedule(M.translate_cmdwin)
      end
    end,
  })

  vim.api.nvim_create_autocmd('CmdwinLeave', {
    group = group,
    pattern = ':',
    callback = function(ev)
      local p = state.pending
      if p and p.buf == ev.buf then
        local pos = vim.api.nvim_buf_get_extmark_by_id(ev.buf, ns, p.mark, {})
        if pos[1] then
          p.final = vim.trim(vim.api.nvim_buf_get_lines(ev.buf, pos[1], pos[1] + 1, false)[1] or '')
        end
      end
      arm()
    end,
  })

  vim.api.nvim_create_autocmd('CmdlineLeave', {
    group = group,
    pattern = ':',
    callback = function()
      if vim.v.event.abort then return end
      arm()
    end,
  })

  pcall(vim.keymap.del, 'c', state.cmap)
  state.cmap = nil
  if key then
    -- On the `:` line, hand the line to `q:` (the 'cedit' key) and translate there.
    vim.keymap.set('c', key, function()
      if vim.fn.getcmdtype() ~= ':' then
        return vim.api.nvim_replace_termcodes(key, true, false, true)
      end
      state.translate_on_enter = true
      return vim.o.cedit
    end, { expr = true, replace_keycodes = false, desc = 'morla: translate in q:' })
    state.cmap = key
  end
end

-- Called from plugin/morla.lua: defaults, unless setup() already ran.
function M.ensure()
  if not state.setup then M.setup({}) end
end

return M
