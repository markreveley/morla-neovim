-- Commands and defaults. require('morla').setup(opts) changes the defaults.
if vim.g.loaded_morla then return end
vim.g.loaded_morla = true

vim.api.nvim_create_user_command('Morla', function(a)
  if a.args == '' then
    return vim.notify('morla: :Morla <instruction>', vim.log.levels.WARN)
  end
  require('morla').translate_to_cmdline(a.args)
end, { nargs = '*', desc = 'Translate an instruction to an Ex command on the : line' })

vim.api.nvim_create_user_command('MorlaHistory', function()
  require('morla').pick_history()
end, { desc = 'Pick a past translation and put it on the : line' })

require('morla').ensure()
