---
type: handoff
audience: agent
updated: 2026-11-05
---

# Next steps for the agent

Read with [`next-operator.md`](next-operator.md). Rewrite both at the end of each thread; delete finished steps.

## Goal
Plain English in `q:` turned into an Ex command in place, reviewed before Enter, learning from what ran. Design: [`md/governance/ARCHITECTURE.md`](md/governance/ARCHITECTURE.md); options and history format: [`md/governance/SCHEMA.md`](md/governance/SCHEMA.md).

## State
- First version built 5 Nov 2026 and pushed: public repo `markreveley/morla-neovim`, `main` at the handoff commit after `6d4bdcd`.
- Tests pass: 25 unit, 15 end to end (`AGENTS.md`, "Working"). Four real translations checked by hand against `claude -p` (Haiku), 2 to 4 s each; not yet used by the operator in a live session.
- Loaded in the operator's Neovim from the local checkout: `~/.dotfiles/nvim/.config/nvim/init.lua`, entry `dir = "~/dev/repos/morla-neovim"`, `lazy = false` (dotfiles `d1dfd96`, pushed). Edits here take effect on the next Neovim start.
- Laid out from repo-template `0232674`; `check-layout.sh` ok, pins in sync.

## Environment facts
- Control+G was taken system-wide by a Gemini shortcut; the operator removed it on 5 Nov 2026. If `<C-g>` does nothing in `q:`, check first that morla is loaded (`:checkhealth morla`), then for an outside shortcut.
- One known weak translation: "set the Date line to today" came back with the date hardcoded, not `strftime()`.

## Next, in order
1. Blocked on the operator's first use (`next-operator.md`): read `~/.local/share/nvim/morla/history.jsonl` and tune the system prompt in `lua/morla/prompt.lua` from the failures and edits (`generated` ≠ `command`).
2. A `:MorlaHistory` picker that searches instruction and command together, if `vim.ui.select` proves too thin.
3. Optional: a terminal-pane backend for the operator's terminal app (`rex` CLI), so "open htop in a new pane" can mean a terminal pane and not a Neovim split. Check `rex` usage first.
