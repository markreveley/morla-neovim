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
- Built and on `main`: translation in `q:` and from the `:` line, `:Morla`, `:MorlaHistory`, explanations beside each command, complaints that mark the last run wrong and retry, the buffer's numbered lines in each request, `changed` per run, Sonnet by default. Plan [`feedback-and-explain`](md/plans/2026-11-05-feedback-and-explain/feedback-and-explain.md) is done; its decisions are ARCHITECTURE D8–D12.
- Tests pass: 32 unit, 28 end to end (P4). Live run against `claude -p`, headless: [`md/tested/2026-11-05-1915-live.md`](md/tested/2026-11-05-1915-live.md), which also lists what it did not test.
- Loaded in the operator's Neovim from the main checkout (`~/.dotfiles/nvim/.config/nvim/init.lua`, `dir = "~/dev/repos/morla-neovim"`); a Neovim restart picks up `main`. The operator has not used it live yet.

## Environment facts
- Control+G was taken system-wide by a Gemini shortcut; the operator removed it on 5 Nov 2026. If `<C-g>` does nothing in `q:`, check `:checkhealth morla`, then for an outside shortcut.
- How to drive a live run, and the range idioms that trip the model: `AGENTS.md`, "This repo's own rules".

## Next, in order
1. Blocked on the operator's first use (`next-operator.md`): read `~/.local/share/nvim/morla/history.jsonl` (marks, `changed: false`, `generated` ≠ `command`) and tune `lua/morla/prompt.lua`; each change gets a live run (P5).
2. Live-test what the report lists as not tested: `:Morla`, `:MorlaHistory`, a file longer than `buffer_lines`, the fix path.
3. Optional: a terminal-pane backend for the operator's terminal app (`rex` CLI), so "open htop in a new pane" can mean a terminal pane. Check `rex` usage first.
