---
type: handoff
audience: agent
updated: 2026-11-05
---

# Next steps for the agent

Read with [`next-operator.md`](next-operator.md). Rewrite both at the end of each thread; delete finished steps.

## State
- First version built on 5 Nov 2026: translate in place in `q:` and from the `:` line, `:Morla`, `:MorlaHistory`, history with examples, fix on error, risk flags, `:checkhealth morla`. Design: `md/governance/ARCHITECTURE.md`.
- Tests pass: 25 unit, 15 end to end. Four real translations checked by hand against `claude -p` (Haiku), 2 to 4 s each.
- Laid out from repo-template (`0232674`) locally; pins in place. First commit on `main`, no remote yet.

## Next, in order
1. Once the operator has used it: tune the system prompt (`lua/morla/prompt.lua`) from the failures in the history file.
2. A `:MorlaHistory` picker that searches instruction and command together, if `vim.ui.select` proves too thin.
3. Optional: a terminal-pane backend for the operator's terminal app (`rex` CLI), so "open htop in a new pane" can mean a terminal pane and not a Neovim split. Check `rex` usage first.

## Pending operator decisions
- In `next-operator.md`.
