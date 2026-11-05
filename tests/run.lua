-- Unit tests. Run: nvim --headless --clean -l tests/run.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, 'p')

local config = require('morla.config')
config.set({ history_file = tmp .. '/history.jsonl' })
local prompt = require('morla.prompt')
local risk = require('morla.risk')
local history = require('morla.history')
local context = require('morla.context')

local tests, failed = {}, 0
local function test(name, fn) table.insert(tests, { name, fn }) end
local function eq(got, want)
  if not vim.deep_equal(got, want) then
    error(('want %s, got %s'):format(vim.inspect(want), vim.inspect(got)), 2)
  end
end

test('parse: plain reply', function() eq(prompt.parse('g/TODO/d\n'), 'g/TODO/d') end)
test('parse: colon and fence stripped', function()
  eq(prompt.parse('```vim\n:%s/a/b/g\n```'), '%s/a/b/g')
end)
test('parse: Command: prefix stripped', function() eq(prompt.parse('Command: :only'), 'only') end)
test('parse: several lines joined with |', function()
  eq(prompt.parse('vsplit\nterminal'), 'vsplit | terminal')
end)
test('parse: empty is nil', function() eq(prompt.parse('  \n```\n```'), nil) end)

test('build: examples, failure and instruction in order', function()
  local s = prompt.build({
    instruction = 'delete todos', context = 'CTX',
    examples = { { instruction = 'only pane', command = 'only' } },
    failure = { command = 'g/TODO/dd', error = 'E492: Not an editor command' },
  })
  local a = s:find('CTX', 1, true)
  local b = s:find('Command: only', 1, true)
  local c = s:find('E492', 1, true)
  local d = s:find('Instruction: delete todos\nCommand:$')
  assert(a and b and c and d and a < b and b < c and c < d, s)
end)

local flags = {
  ['g/TODO/d'] = {},
  ['%s/a/b/g'] = {},
  ['%!sort -u'] = { 'shell' },
  ["'<,'>!sort"] = { 'shell' },
  ['r !date'] = { 'shell' },
  ['w !sudo tee %'] = { 'shell', 'writes files' },
  ['vsplit | lcd ~/x | terminal htop'] = { 'shell' },
  ['vsplit | ter'] = { 'shell' },
  ['bufdo %s/x/y/ge | update'] = { 'many files', 'writes files' },
  ['w'] = { 'writes files' },
  ['wincmd l'] = {},
  ['q!'] = {},
  ['call delete(expand("%"))'] = { 'deletes files' },
  ['echo system("ls")'] = { 'shell' },
  ['lua print(1)'] = { 'runs Lua' },
  ['vertical resize 80'] = {},
}
for cmd, want in pairs(flags) do
  test('risk: ' .. cmd, function() eq(risk.check(cmd), want) end)
end

test('history: append, load, rank, examples', function()
  history.append({ cwd = '~/a', filetype = 'lua', instruction = 'one', command = 'c1', ok = true })
  history.append({ cwd = '~/b', filetype = 'markdown', instruction = 'two', command = 'c2', ok = true })
  history.append({ cwd = '~/b', filetype = 'markdown', instruction = 'bad', command = 'c3', ok = false })
  history.append({ cwd = '~/a', filetype = 'lua', instruction = 'one again', command = 'c1', ok = true })
  local f = io.open(config.options.history_file, 'a'); f:write('not json\n'); f:close()
  eq(#history.load(), 4)
  local ranked = history.rank(history.load(), { cwd = '~/b', filetype = 'markdown' })
  eq(vim.tbl_map(function(r) return r.command end, ranked), { 'c3', 'c2', 'c1' })
  eq(history.examples({ cwd = '~/a', filetype = 'lua' }, 5),
    { { instruction = 'one again', command = 'c1' }, { instruction = 'two', command = 'c2' } })
end)

test('history: the SCHEMA.md example loads', function()
  local saved = config.options.history_file
  config.options.history_file = vim.fn.getcwd() .. '/tests/fixtures/history.jsonl'
  local recs = history.load()
  config.options.history_file = saved
  eq(#recs, 2)
  eq({ recs[2].generated, recs[2].command, recs[2].ok, recs[2].error },
    { "'<,'>sort u", "'<,'>sort", false, 'E20: Mark not set' })
end)

test('context: file, cursor, selection, history', function()
  vim.cmd('enew')
  vim.bo.filetype = 'markdown'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { '# T', 'a', 'b', 'c' })
  vim.api.nvim_buf_set_mark(0, '<', 2, 0, {})
  vim.api.nvim_buf_set_mark(0, '>', 3, 0, {})
  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  vim.fn.histadd(':', 'only')
  local ctx = context.gather()
  eq({ ctx.filetype, ctx.line, ctx.lines, ctx.current }, { 'markdown', 4, 4, 'c' })
  eq(ctx.selection, { from = 2, to = 3, text = { 'a', 'b' } })
  local text = context.render(ctx)
  assert(text:find("lines 2-3", 1, true) and text:find('  only', 1, true), text)
end)

for _, t in ipairs(tests) do
  local ok, err = pcall(t[2])
  if ok then
    io.stdout:write('ok   ', t[1], '\n')
  else
    failed = failed + 1
    io.stdout:write('FAIL ', t[1], '\n     ', tostring(err), '\n')
  end
end
io.stdout:write(('%d tests, %d failed\n'):format(#tests, failed))
vim.fn.delete(tmp, 'rf')
os.exit(failed == 0 and 0 or 1)
