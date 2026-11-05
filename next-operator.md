---
type: handoff
audience: operator
updated: 2026-11-05
---

# Next steps for the operator

Read with [`next-agents.md`](next-agents.md).

## To do
1. Decide whether the GitHub repo `markreveley/morla-neovim` is public or private; the agent creates it and pushes.
2. Add the plugin to the Neovim config in `~/.dotfiles/nvim/` (lazy.nvim: `{ dir = '~/dev/repos/morla-neovim', opts = {} }` until it is on GitHub).
3. Use it for a few days on Markdown; the failures land in `~/.local/share/nvim/morla/history.jsonl` and drive the prompt tuning.
