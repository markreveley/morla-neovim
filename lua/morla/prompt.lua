-- The text sent to the model and the reading of its reply.
local M = {}

M.system = table.concat({
  'You translate a plain-English instruction into one Neovim Ex command line.',
  'Reply with the command only: no leading colon, no code fence, no explanation, one line.',
  'Join several commands with |. Prefer built-in Ex commands; use :lua or Vimscript functions only when Ex cannot do it.',
  'Use the editor context you are given. When the instruction refers to a selection, use the range \'<,\'>.',
  'Run shell commands (:!, system(), :terminal) only when the instruction asks for a program or the shell.',
  'If the instruction is already a valid Ex command, return it unchanged.',
  'If you are shown a command that failed and its error, return a corrected command.',
}, ' ')

-- req: { instruction, context = <rendered text>, examples = { {instruction, command} },
--        failure = { command, error } | nil }
function M.build(req)
  local out = { 'Editor context:', req.context, '' }
  if req.examples and #req.examples > 0 then
    table.insert(out, 'Earlier translations the user ran without error:')
    for _, ex in ipairs(req.examples) do
      table.insert(out, 'Instruction: ' .. ex.instruction)
      table.insert(out, 'Command: ' .. ex.command)
    end
    table.insert(out, '')
  end
  if req.failure then
    table.insert(out, 'This command failed: ' .. req.failure.command)
    table.insert(out, 'Error: ' .. req.failure.error)
    table.insert(out, '')
  end
  table.insert(out, 'Instruction: ' .. req.instruction)
  table.insert(out, 'Command:')
  return table.concat(out, '\n')
end

-- The model's reply to one command line, or nil when there is none.
function M.parse(text)
  if not text then return nil end
  local lines = {}
  for line in (text .. '\n'):gmatch('(.-)\r?\n') do
    line = vim.trim(line)
    if line ~= '' and not line:match('^```') then
      line = line:gsub('^Command:%s*', ''):gsub('^:+%s*', '')
      if line ~= '' then table.insert(lines, line) end
    end
  end
  if #lines == 0 then return nil end
  return table.concat(lines, ' | ')
end

return M
