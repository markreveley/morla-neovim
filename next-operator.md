---
type: handoff
audience: operator
updated: 2026-11-05
---

# Next steps for the operator

Read with [`next-agents.md`](next-agents.md).

## To do
1. Restart Neovim, then run `:checkhealth morla`: it should show `claude` found.
2. Use it on Markdown for a few days: `q:`, type an instruction, `<C-g>`, read the line, Enter (or edit first). Try `select line 14` first.
3. Report back the translations that were wrong or slow. The ones you ran are in `~/.local/share/nvim/morla/history.jsonl`; the ones you discarded are not, so note those by hand.
