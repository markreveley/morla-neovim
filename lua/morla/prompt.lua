-- The text sent to the model and the reading of its reply.
local M = {}

M.system = table.concat({
  'You translate a plain-English instruction into one Neovim Ex command line, for a user who cannot read Vimscript.',
  'Reply with one JSON object and nothing else:',
  '{"command": "<one Ex command line, no leading colon>",',
  '"explain": "<what the command does, in plain English, at most 12 words>",',
  '"feedback": <true if the instruction is a complaint or correction about the last command run, else false>}.',
  'Join several commands with |. Prefer built-in Ex commands; use :lua or Vimscript functions only when Ex cannot do it.',
  'Use the editor context you are given. When the instruction refers to a selection, use the range \'<,\'>.',
  'Run shell commands (:!, system(), :terminal) only when the instruction asks for a program or the shell.',
  'For today\'s date or time use strftime(), never a written-out date.',
  'In :s, an expression replacement must begin with \\= and covers the whole replacement: s/\\(Date: \\).*/\\=submatch(1) . strftime("%Y-%m-%d")/.',
  'If the instruction is already a valid Ex command, return it unchanged.',
  'When feedback is true, write the command the earlier instruction should have had;',
  'if the last command changed text the wrong way, begin with "undo | ". Say so in explain.',
}, ' ')

-- req: { instruction, context = <rendered text>, examples = { {instruction, command} },
--        last = { instruction, command, ok, error, changed } | nil }
function M.build(req)
  local out = { 'Editor context:', req.context, '' }
  if req.examples and #req.examples > 0 then
    table.insert(out, 'Earlier translations the user ran and kept:')
    for _, ex in ipairs(req.examples) do
      table.insert(out, 'Instruction: ' .. ex.instruction)
      table.insert(out, 'Command: ' .. ex.command)
    end
    table.insert(out, '')
  end
  if req.last then
    table.insert(out, 'Last command run in this session:')
    table.insert(out, 'Instruction: ' .. req.last.instruction)
    table.insert(out, 'Command: ' .. req.last.command)
    local result
    if not req.last.ok then
      result = 'failed: ' .. (req.last.error or '?')
    elseif req.last.changed == false then
      result = 'ran without error but changed nothing in the buffer'
    else
      result = 'ran without error' .. (req.last.changed and ' and changed the buffer' or '')
    end
    table.insert(out, 'Result: ' .. result)
    table.insert(out, '')
  end
  table.insert(out, 'Instruction: ' .. req.instruction)
  return table.concat(out, '\n')
end

local function clean(cmd)
  cmd = vim.trim(cmd or ''):gsub('^:+%s*', '')
  return cmd ~= '' and cmd or nil
end

-- The old reading: the reply is the command itself, possibly fenced.
local function parse_plain(text)
  local lines = {}
  for line in (text .. '\n'):gmatch('(.-)\r?\n') do
    line = vim.trim(line)
    if line ~= '' and not line:match('^```') then
      line = clean(line:gsub('^Command:%s*', ''))
      if line then table.insert(lines, line) end
    end
  end
  if #lines == 0 then return nil end
  return table.concat(lines, ' | ')
end

-- The reply as { command, explain, feedback }, or nil when there is no command.
function M.parse(text)
  if not text then return nil end
  local json = text:match('{.*}') -- first { to last }: a command may hold an unpaired brace
  if json then
    local ok, obj = pcall(vim.json.decode, json)
    if ok and type(obj) == 'table' and type(obj.command) == 'string' and clean(obj.command) then
      local explain = type(obj.explain) == 'string' and vim.trim(obj.explain) or nil
      return {
        command = clean(obj.command),
        explain = explain ~= '' and explain or nil,
        feedback = obj.feedback == true,
      }
    end
  end
  local cmd = parse_plain(text)
  return cmd and { command = cmd, feedback = false } or nil
end

return M
