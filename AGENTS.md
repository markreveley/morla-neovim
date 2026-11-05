# morla-neovim: working rules

Rules for any agent (Claude Code, Codex, Gemini) and for people. The global
rules in `~/.dotfiles/agents/AGENTS.md` apply first; this file adds the
repo's own. `CLAUDE.md` imports this file and adds nothing.

## Read first

1. `README.md`: what the repo is and the table of what is where.
2. `next-agents.md` and `next-operator.md`: where the last thread stopped.
   `/start` reads them; `/end` rewrites them. What to work on comes from
   `next-agents.md`, not from reading other documents.
3. `md/governance/POLICY.md` before any change (rules `P1`…, cited below);
   `md/governance/ARCHITECTURE.md` before changing how the parts fit;
   `md/governance/SCHEMA.md` before changing an option, a command or the
   history file.

## Where things are

- `plugin/morla.lua`, `lua/morla/`: the plugin, plain Lua.
- `tests/`: `run.lua` (unit), `e2e.sh` with `fake-claude.sh`, `fixtures/`.
- `md/`: every document about the repo. `md/README.md` lists the folders
  and the naming conventions; each folder's README says what belongs in it.
- `LOCAL.md` (git-ignored): names of private projects, local paths, and
  anything else that stays on this machine, including where the
  private-terms list for P7 is.

## Working

- Changes reach `main` through a PR, unless `next-agents.md` says the work
  is on `main`. `/end` commits where the work is and opens the PR.
- Contracts (`SCHEMA.md`): the options, `:Morla`, `:MorlaHistory`, the
  history file. Reader: the operator's Neovim config, in
  `~/.dotfiles/nvim/`.
- Tests before a PR (P4). Neither suite calls the model: a prompt, reply
  or model change also needs a live run reported in `md/tested/` (P5).
- Threads are archived at `/end` into the private `thread-archive` repo,
  under `threads/morla-neovim/`, not into this repo.
- Worktrees go under `.claude/worktrees/` (git-ignored). Never touch
  another session's worktree.

## This repo's own rules

The rules are in `md/governance/POLICY.md`. Gotchas:

- `e2e.sh` drives a headless Neovim with `--remote-send`. In `q:`, a key
  sent before the previous one is handled can land in the wrong mode; the
  script sleeps between steps. It runs under `set -e`: a check that expects
  `grep` to find nothing goes through `has`, never a bare `grep`.
- `nvim_buf_get_extmarks` reads an integer start or end as an extmark id,
  not a row: pass `{row, col}`.
- A live run is easiest the same way: `nvim --headless --listen <sock>`,
  then `nvim --server <sock> --remote-send 'q:i<instruction><C-g>'` and
  `--remote-expr "getline('.')"`.
- Vim ranges trip the model: `0/pat/` searches from the cursor, not the top,
  and `0;/pat/` is a range from the top to the match. Check any range idiom
  in Neovim before putting it in the prompt.
