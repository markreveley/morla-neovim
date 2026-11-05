-- Flags on a translated command that deserve a second look before Enter.
-- A flag is a warning shown beside the line; nothing is blocked. The
-- reading is approximate: the line is split on `|` and each piece's Ex
-- command name is matched with its abbreviations.
local M = {}

-- { full name, shortest abbreviation, flag }
local commands = {
  { 'terminal', 'ter', 'shell' },
  { 'write', 'w', 'writes files' }, { 'wall', 'wa', 'writes files' },
  { 'wq', 'wq', 'writes files' }, { 'wqall', 'wqa', 'writes files' },
  { 'xit', 'x', 'writes files' }, { 'xall', 'xa', 'writes files' },
  { 'update', 'up', 'writes files' }, { 'saveas', 'sav', 'writes files' },
  { 'bufdo', 'bufdo', 'many files' }, { 'argdo', 'argdo', 'many files' },
  { 'windo', 'windo', 'many files' }, { 'tabdo', 'tabdo', 'many files' },
  { 'cdo', 'cdo', 'many files' }, { 'cfdo', 'cfdo', 'many files' },
  { 'ldo', 'ldo', 'many files' }, { 'lfdo', 'lfdo', 'many files' },
  { 'lua', 'lua', 'runs Lua' }, { 'luafile', 'luaf', 'runs Lua' }, { 'luado', 'luad', 'runs Lua' },
}

-- Anywhere in the line.
local calls = {
  { 'system%(', 'shell' }, { 'systemlist%(', 'shell' }, { 'jobstart%(', 'shell' },
  { 'termopen%(', 'shell' }, { 'vim%.system', 'shell' },
  { 'delete%(', 'deletes files' }, { 'os%.remove', 'deletes files' }, { 'vim%.fs%.rm', 'deletes files' },
  { 'writefile%(', 'writes files' }, { 'luaeval%(', 'runs Lua' },
}

local function strip_range(s)
  local pats = { '^%s+', '^:', '^%d+', '^[%%.$,;+%-]', "^'.", '^/[^/]*/', '^%?[^?]*%?' }
  local prev
  repeat
    prev = s
    for _, p in ipairs(pats) do s = s:gsub(p, '') end
  until s == prev
  return s
end

local function name_matches(name, full, min)
  return #name >= #min and full:sub(1, #name) == name
end

function M.check(cmd)
  local set, flags = {}, {}
  local function add(f)
    if not set[f] then set[f] = true; table.insert(flags, f) end
  end
  for piece in (cmd .. '|'):gmatch('([^|]*)|') do
    local rest = strip_range(piece)
    if rest:match('^!') then add('shell') end -- :!cmd, :%!filter, :'<,'>!sort
    local name, after = rest:match('^(%a+)!?(.*)$')
    if name then
      if (name == 'r' or name == 'read' or name == 'w' or name == 'write') and after:match('^%s*!') then
        add('shell') -- :r !cmd, :w !cmd
      end
      for _, c in ipairs(commands) do
        if name_matches(name, c[1], c[2]) then add(c[3]) end
      end
    end
  end
  for _, c in ipairs(calls) do
    if cmd:match(c[1]) then add(c[2]) end
  end
  return flags
end

return M
