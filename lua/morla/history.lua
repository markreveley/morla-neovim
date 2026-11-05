-- The history file: one JSON object per line, appended, never rewritten.
-- A line is a run, or a mark that calls an earlier run wrong. Format in
-- md/governance/SCHEMA.md.
local config = require('morla.config')

local M = {}

local seq = 0
function M.new_id()
  seq = seq + 1
  return string.format('%s-%x-%d', os.date('!%Y%m%dT%H%M%S'), vim.uv.hrtime() % 0x1000000, seq)
end

function M.append(record)
  local path = config.options.history_file
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local f = io.open(path, 'a')
  if not f then return false end
  f:write(vim.json.encode(record), '\n')
  f:close()
  return true
end

-- Mark run `id` wrong, with the operator's words.
function M.mark_wrong(id, note)
  return M.append({ ts = os.date('!%Y-%m-%dT%H:%M:%SZ'), marks = id, ok = false, note = note })
end

-- The runs, oldest first, with marks applied: a marked run has ok = false
-- and the mark's note.
function M.load()
  local f = io.open(config.options.history_file, 'r')
  if not f then return {} end
  local runs, marks = {}, {}
  for line in f:lines() do
    local ok, rec = pcall(vim.json.decode, line)
    if ok and type(rec) == 'table' then
      if type(rec.marks) == 'string' then
        marks[rec.marks] = rec
      elseif rec.command and rec.instruction then
        table.insert(runs, rec)
      end
    end
  end
  f:close()
  for _, r in ipairs(runs) do
    local m = r.id and marks[r.id]
    if m then
      r.ok = false
      r.note = m.note
    end
  end
  return runs
end

-- Newest first, the same project and filetype ahead of the rest, one entry
-- per command. ctx: { cwd, filetype }.
function M.rank(records, ctx)
  local scored = {}
  for i, r in ipairs(records) do
    local s = i / math.max(#records, 1) -- recency, 0..1
    if ctx and r.cwd == ctx.cwd then s = s + 2 end
    if ctx and ctx.filetype ~= '' and r.filetype == ctx.filetype then s = s + 1 end
    table.insert(scored, { s = s, r = r })
  end
  table.sort(scored, function(a, b) return a.s > b.s end)
  local seen, out = {}, {}
  for _, x in ipairs(scored) do
    if not seen[x.r.command] then
      seen[x.r.command] = true
      table.insert(out, x.r)
    end
  end
  return out
end

-- The best n runs the operator kept (no error, not marked wrong), as
-- prompt examples.
function M.examples(ctx, n)
  local ok = vim.tbl_filter(function(r) return r.ok end, M.load())
  local out = {}
  for _, r in ipairs(M.rank(ok, ctx)) do
    if #out >= n then break end
    table.insert(out, { instruction = r.instruction, command = r.command })
  end
  return out
end

return M
