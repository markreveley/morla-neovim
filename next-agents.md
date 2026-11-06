---
type: handoff
audience: agent
updated: 2026-11-05
---

# Next steps for the agent

Read with [`next-operator.md`](next-operator.md). Rewrite both at the end of each thread; delete finished steps.

## Goal
Plain English in `q:` turned into an Ex command in place, explained in plain English, corrected by plain-English complaints, learning from what the operator kept. The operator does not read Vimscript. Design: [`md/governance/ARCHITECTURE.md`](md/governance/ARCHITECTURE.md); rules: [`md/governance/POLICY.md`](md/governance/POLICY.md); options and history format: [`md/governance/SCHEMA.md`](md/governance/SCHEMA.md).

## State
- Built and on `main`: translation in `q:` and from the `:` line, `:Morla`, `:MorlaHistory`, explanations beside each command, complaints that mark the last run wrong and retry, the buffer's numbered lines in each request, `changed` per run, Sonnet by default, `q:` reopening after a run with each past command's instruction beside it (ARCHITECTURE D13–D14), side panels standing aside for the last file window and `open()` for a mapping (D15; the operator's `<leader>m` uses it). Plan [`feedback-and-explain`](md/plans/2026-11-05-feedback-and-explain/feedback-and-explain.md) is done; its decisions are ARCHITECTURE D8–D12.
- Tests pass: 35 unit, 39 end to end (P4). Live runs against `claude -p`, headless: [`md/tested/2026-11-05-1915-live.md`](md/tested/2026-11-05-1915-live.md), [`md/tested/2026-11-05-2010-live.md`](md/tested/2026-11-05-2010-live.md), [`md/tested/2026-11-05-2050-live.md`](md/tested/2026-11-05-2050-live.md); each lists what it did not test.
- Loaded in the operator's Neovim from the main checkout (`~/.dotfiles/nvim/.config/nvim/init.lua`, `dir = "~/dev/repos/morla-neovim"`); a Neovim restart picks up `main`. The operator's first use (5 Nov 2026) drove D13–D15; they need a restart to get them. `main` is at `4cc6eb6` plus this handoff, pushed.

## Environment facts
- Control+G was taken system-wide by a Gemini shortcut; the operator removed it on 5 Nov 2026. If `<C-g>` does nothing in `q:`, check `:checkhealth morla`, then for an outside shortcut.
- How to drive a live run, and the range idioms that trip the model: `AGENTS.md`, "This repo's own rules".
- The operator's keys are Dvorak-remapped in their config (`k` is next search match, `u` is up): check before naming a key to them. In nvim-tree, `q` closes the tree, so `q:` can't be typed there; `<leader>m` (`open()`) is the way in.
- The operator's host is Ghostty, tmux and workmux; Rex is not used (since 5 Nov 2026). Each worktree is a tmux window with Neovim in one pane and `claude --ide` in the next, linked by claudecode.nvim. morla works inside Neovim, writing Ex commands and Vimscript; nothing in it depends on the host.
- The operator keeps Neovim key notes that describe morla's keys; when a key or command changes, update them too (`LOCAL.md` says where).

## Next, in order
1. Blocked on a few days of the operator's use (`next-operator.md`): read `~/.local/share/nvim/morla/history.jsonl` (marks, `changed: false`, `generated` ≠ `command`) and tune `lua/morla/prompt.lua`; each change gets a live run (P5).
2. Live-test what the report lists as not tested: `:Morla`, `:MorlaHistory`, a file longer than `buffer_lines`, the fix path.
